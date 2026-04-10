import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'people_event.dart';
import 'people_state.dart';
import '../../../data/repositories/people_repository.dart';
import '../../../domain/entities/people_user_entity.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/di/injection.dart';

@injectable
class PeopleBloc extends Bloc<PeopleEvent, PeopleState> {
  final PeopleRepository _repository;
  /// Tracks user IDs that have a follow/unfollow request in flight.
  final Set<String> _pendingToggles = {};

  PeopleBloc({required PeopleRepository repository})
      : _repository = repository,
        super(const PeopleState.initial()) {
    on<PeopleFetchRequested>(_onFetch);
    on<PeopleTabChanged>(_onTabChanged);
    on<PeopleSearchChanged>(_onSearch);
    on<PeopleFollowToggled>(_onFollowToggled);
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onFetch(
    PeopleFetchRequested event,
    Emitter<PeopleState> emit,
  ) async {
    final current = state is PeopleLoaded ? (state as PeopleLoaded) : null;
    
    // Skip full-screen loading if we already have data (prevents flickering on refresh)
    if (current == null) {
      emit(const PeopleState.loading());
    }

    try {
      final activeTab = current?.activeTab ?? PeopleTab.followed;

      final results = await Future.wait([
        _repository.getFollowed(),
        _repository.getFollowers(),
      ]);

      emit(PeopleState.loaded(
        followedUsers: results[0],
        followersUsers: results[1],
        activeTab: activeTab,
        query: current?.query ?? '',
      ));
    } catch (e) {
      if (current == null) {
        emit(PeopleState.failure(message: e.toString()));
      } else {
        // If we already have data, just log and keep current state
        // ignore: avoid_print
        print('[PeopleBloc] Refresh error: $e');
      }
    }
  }

  void _onTabChanged(PeopleTabChanged event, Emitter<PeopleState> emit) {
    final current = state;
    if (current is! PeopleLoaded) return;
    emit(current.copyWith(activeTab: event.tab, query: ''));
  }

  void _onSearch(PeopleSearchChanged event, Emitter<PeopleState> emit) {
    final current = state;
    if (current is! PeopleLoaded) return;
    emit(current.copyWith(query: event.query));
  }

  Future<void> _onFollowToggled(
    PeopleFollowToggled event,
    Emitter<PeopleState> emit,
  ) async {
    final currentState = state;
    if (currentState is! PeopleLoaded) return;
    
    // Guard: ignore if a request for this user is already in flight
    if (_pendingToggles.contains(event.userId)) return;
    _pendingToggles.add(event.userId);

    try {
      bool isCurrentlyFollowing = false;
      final target = currentState.followedUsers
          .where((u) => u.userId == event.userId)
          .firstOrNull;
      
      isCurrentlyFollowing = target?.isFollowing ??
          currentState.followersUsers
              .where((u) => u.userId == event.userId)
              .firstOrNull
              ?.isFollowing ??
          false;
  
      // Optimistic toggle on both lists
      PeopleUserEntity toggle(PeopleUserEntity u) =>
          u.userId == event.userId
              ? u.copyWith(isFollowing: !u.isFollowing)
              : u;
  
      List<PeopleUserEntity> newFollowed = currentState.followedUsers.map(toggle).toList();
      List<PeopleUserEntity> newFollowers = currentState.followersUsers.map(toggle).toList();
  
      // If we are following a NEW person (not in our lists yet), and the object was provided
      if (!isCurrentlyFollowing && event.user != null) {
        final alreadyInFollowed = newFollowed.any((u) => u.userId == event.userId);
        if (!alreadyInFollowed) {
          newFollowed.insert(0, event.user!.copyWith(isFollowing: true));
        }
      }
  
      emit(currentState.copyWith(
        followedUsers: newFollowed,
        followersUsers: newFollowers,
      ));
  
      if (isCurrentlyFollowing) {
        await _repository.unfollow(event.userId);
      } else {
        await _repository.follow(event.userId);
        
        // requestPermissions can throw synchronously on unsupported platforms
        try {
          getIt<NotificationService>().requestPermissions();
        } catch (e) {
          print('[PeopleBloc] Notification permission soft-fail: $e');
        }
      }
      
      // Post-action refresh to get accurate run counts etc.
      add(const PeopleFetchRequested());
    } catch (e) {
      print('[PeopleBloc] _onFollowToggled error: $e');
      // Revert optimistic update on error.
      // Easiest is to just fetch fresh state.
      add(const PeopleFetchRequested());
    } finally {
      _pendingToggles.remove(event.userId);
    }
  }
}
