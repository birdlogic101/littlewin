import 'package:flutter_bloc/flutter_bloc.dart';
import 'people_event.dart';
import 'people_state.dart';
import '../../../domain/entities/people_user_entity.dart';

class PeopleBloc extends Bloc<PeopleEvent, PeopleState> {
  /// Full unfiltered user list (source of truth for client-side search).
  List<PeopleUserEntity> _allUsers = [];

  PeopleBloc() : super(const PeopleState.initial()) {
    on<PeopleFetchRequested>(_onFetch);
    on<PeopleSearchChanged>(_onSearch);
    on<PeopleFollowToggled>(_onFollowToggled);
  }

  Future<void> _onFetch(
    PeopleFetchRequested event,
    Emitter<PeopleState> emit,
  ) async {
    emit(const PeopleState.loading());
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _allUsers = _mockUsers();
      emit(PeopleState.loaded(users: _allUsers, query: ''));
    } catch (e) {
      emit(PeopleState.failure(message: e.toString()));
    }
  }

  void _onSearch(PeopleSearchChanged event, Emitter<PeopleState> emit) {
    final q = event.query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _allUsers
        : _allUsers
            .where((u) => u.username.toLowerCase().contains(q))
            .toList();
    emit(PeopleState.loaded(users: filtered, query: event.query));
  }

  void _onFollowToggled(
    PeopleFollowToggled event,
    Emitter<PeopleState> emit,
  ) {
    // Optimistic toggle in both the filtered view and the master list.
    _allUsers = _allUsers.map((u) {
      if (u.userId != event.userId) return u;
      return u.copyWith(isFollowing: !u.isFollowing);
    }).toList();

    final current = state;
    if (current is! PeopleLoaded) return;

    final updatedFiltered = current.users.map((u) {
      if (u.userId != event.userId) return u;
      return u.copyWith(isFollowing: !u.isFollowing);
    }).toList();

    emit(PeopleState.loaded(users: updatedFiltered, query: current.query));

    // TODO: call follow/unfollow use-case (fire-and-forget, revert on failure)
  }

  // ── Stub data ──────────────────────────────────────────────────────────────

  List<PeopleUserEntity> _mockUsers() => [
        const PeopleUserEntity(
          userId: 'user-1',
          username: 'elwilliam',
          avatarId: 1,
          isFollowing: true,
        ),
        const PeopleUserEntity(
          userId: 'user-2',
          username: 'marta.runs',
          avatarId: 3,
          isFollowing: false,
        ),
        const PeopleUserEntity(
          userId: 'user-3',
          username: 'jakobf',
          avatarId: 5,
          isFollowing: true,
        ),
        const PeopleUserEntity(
          userId: 'user-4',
          username: 'sophiecal',
          avatarId: 7,
          isFollowing: false,
        ),
        const PeopleUserEntity(
          userId: 'user-5',
          username: 'tomas_k',
          avatarId: 2,
          isFollowing: false,
        ),
        const PeopleUserEntity(
          userId: 'user-6',
          username: 'nadia.fit',
          avatarId: 9,
          isFollowing: false,
        ),
      ];
}
