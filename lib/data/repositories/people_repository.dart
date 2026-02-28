import '../../domain/entities/people_user_entity.dart';
import '../datasources/people_remote_datasource.dart';

/// Repository for the follow system.
///
/// Provides followed / followers lists and search, with mock fallback when
/// Supabase is not configured (tests / offline dev).
class PeopleRepository {
  final PeopleRemoteDataSource? _datasource;

  PeopleRepository({PeopleRemoteDataSource? datasource})
      : _datasource = datasource;

  // ── Reads ──────────────────────────────────────────────────────────────────

  Future<List<PeopleUserEntity>> getFollowed() async {
    if (_datasource == null) return _mockFollowed();
    try {
      return await _datasource.fetchFollowed();
    } catch (e) {
      // ignore: avoid_print
      print('[PeopleRepository] fetchFollowed error: $e');
      return _mockFollowed();
    }
  }

  Future<List<PeopleUserEntity>> getFollowers() async {
    if (_datasource == null) return _mockFollowers();
    try {
      final followers = await _datasource.fetchFollowers();
      // Enrich: mark those we also follow back
      final followedIds = await _datasource.fetchFollowedIds();
      return followers
          .map((u) => u.copyWith(isFollowing: followedIds.contains(u.userId)))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('[PeopleRepository] fetchFollowers error: $e');
      return _mockFollowers();
    }
  }

  /// Searches for users by username and marks which ones the caller follows.
  Future<List<PeopleUserEntity>> searchUsers(String query) async {
    if (_datasource == null) return _mockSearch(query);
    try {
      final results = await _datasource.searchUsers(query);
      final followedIds = await _datasource.fetchFollowedIds();
      return results
          .map((u) => u.copyWith(isFollowing: followedIds.contains(u.userId)))
          .toList();
    } catch (e) {
      // ignore: avoid_print
      print('[PeopleRepository] searchUsers error: $e');
      return [];
    }
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<void> follow(String userId) async {
    if (_datasource == null) return;
    try {
      await _datasource.follow(userId);
    } catch (e) {
      // ignore: avoid_print
      print('[PeopleRepository] follow error: $e');
    }
  }

  Future<void> unfollow(String userId) async {
    if (_datasource == null) return;
    try {
      await _datasource.unfollow(userId);
    } catch (e) {
      // ignore: avoid_print
      print('[PeopleRepository] unfollow error: $e');
    }
  }

  // ── Mock data ──────────────────────────────────────────────────────────────

  List<PeopleUserEntity> _mockFollowed() => [
        const PeopleUserEntity(
          userId: 'u1', username: 'enzogorlomi',
          avatarId: 2, isFollowing: true, ongoingRunCount: 5,
        ),
        const PeopleUserEntity(
          userId: 'u2', username: 'antoniamargheriti',
          avatarId: 4, isFollowing: true, ongoingRunCount: 3,
        ),
        const PeopleUserEntity(
          userId: 'u3', username: 'dominickdecocco',
          avatarId: 7, isFollowing: true, ongoingRunCount: 10,
        ),
      ];

  List<PeopleUserEntity> _mockFollowers() => [
        const PeopleUserEntity(
          userId: 'u1', username: 'enzogorlomi',
          avatarId: 2, isFollowing: true,
        ),
        const PeopleUserEntity(
          userId: 'u4', username: 'marta.runs',
          avatarId: 3, isFollowing: false,
        ),
      ];

  List<PeopleUserEntity> _mockSearch(String query) {
    final all = [
      const PeopleUserEntity(userId: 'u5', username: 'sophiecal', avatarId: 7, isFollowing: false),
      const PeopleUserEntity(userId: 'u6', username: 'tomas_k', avatarId: 2, isFollowing: false),
      const PeopleUserEntity(userId: 'u7', username: 'nadia.fit', avatarId: 9, isFollowing: false),
    ];
    final q = query.trim().toLowerCase();
    return q.isEmpty
        ? all
        : all.where((u) => u.username.toLowerCase().contains(q)).toList();
  }
}
