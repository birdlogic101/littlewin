import 'package:flutter_bloc/flutter_bloc.dart';
import 'people_event.dart';
import 'people_state.dart';
import '../../../data/repositories/people_repository.dart';
import '../../../domain/entities/people_user_entity.dart';

class PeopleBloc extends Bloc<PeopleEvent, PeopleState> {
  final PeopleRepository _repository;

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
    emit(const PeopleState.loading());
    try {
      final current =
          state is PeopleLoaded ? (state as PeopleLoaded) : null;
      final activeTab = current?.activeTab ?? PeopleTab.followed;

      final results = await Future.wait([
        _repository.getFollowed(),
        _repository.getFollowers(),
      ]);

      emit(PeopleState.loaded(
        followedUsers: results[0],
        followersUsers: results[1],
        activeTab: activeTab,
        query: '',
      ));
    } catch (e) {
      emit(PeopleState.failure(message: e.toString()));
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
    final current = state;
    if (current is! PeopleLoaded) return;

    final target = current.followedUsers
        .where((u) => u.userId == event.userId)
        .firstOrNull;
    final isCurrentlyFollowing = target?.isFollowing ??
        current.followersUsers
            .where((u) => u.userId == event.userId)
            .firstOrNull
            ?.isFollowing ??
        false;

    // Optimistic toggle on both lists
    PeopleUserEntity toggle(PeopleUserEntity u) =>
        u.userId == event.userId
            ? u.copyWith(isFollowing: !u.isFollowing)
            : u;

    emit(current.copyWith(
      followedUsers: current.followedUsers.map(toggle).toList(),
      followersUsers: current.followersUsers.map(toggle).toList(),
    ));

    // Persist (fire-and-forget; revert on failure not implemented for MLP)
    if (isCurrentlyFollowing) {
      await _repository.unfollow(event.userId);
    } else {
      await _repository.follow(event.userId);
    }

    // Refresh to get accurate run counts
    add(const PeopleFetchRequested());
  }
}
