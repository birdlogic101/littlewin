import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/people_user_entity.dart';

import 'package:injectable/injectable.dart';

/// Remote data source for follow-system Supabase operations.
@lazySingleton
class PeopleRemoteDataSource {
  final SupabaseClient _client;
  PeopleRemoteDataSource(this._client);

  // ── Reads ──────────────────────────────────────────────────────────────────

  /// Fetches users the current user follows, with their ongoing run count.
  ///
  /// Calls the `get_followed_users` RPC (see impl plan SQL).
  /// Falls back to an empty list on error.
  Future<List<PeopleUserEntity>> fetchFollowed() async {
    final rows = await _client.rpc('get_followed_users') as List<dynamic>;
    return rows.map<PeopleUserEntity>((r) {
      return PeopleUserEntity(
        userId: r['user_id'] as String,
        username: r['username'] as String,
        avatarId: r['avatar_id'] as int?,
        isFollowing: true,
        ongoingRunCount: (r['ongoing_count'] as num?)?.toInt() ?? 0,
        isPremium: (r['roles'] as List<dynamic>?)?.contains('premium') ??
            (r['is_premium'] as bool? ?? false),
      );
    }).toList();
  }

  /// Fetches users who follow the current user.
  Future<List<PeopleUserEntity>> fetchFollowers() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];

    final rows = await _client
        .from('follows')
        .select('follower_id, users!follows_follower_id_fkey(id, username, avatar_id, roles)')
        .eq('followed_id', uid);

    return (rows as List<dynamic>).map<PeopleUserEntity>((r) {
      final u = r['users'] as Map<String, dynamic>;
      final roles = u['roles'] as List<dynamic>?;
      return PeopleUserEntity(
        userId: u['id'] as String,
        username: u['username'] as String,
        avatarId: u['avatar_id'] as int?,
        isFollowing: false, // will be enriched by PeopleRepository
        isPremium: roles?.contains('premium') ?? false,
      );
    }).toList();
  }

  /// Searches for users by username prefix (global, excluding self).
  Future<List<PeopleUserEntity>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    final uid = _client.auth.currentUser?.id;

    final rows = await _client
        .from('users')
        .select('id, username, avatar_id, roles')
        .ilike('username', '%${query.trim()}%')
        .neq('id', uid ?? '')
        .limit(20);

    return (rows as List<dynamic>).map<PeopleUserEntity>((r) {
      final roles = r['roles'] as List<dynamic>?;
      return PeopleUserEntity(
        userId: r['id'] as String,
        username: r['username'] as String,
        avatarId: r['avatar_id'] as int?,
        isFollowing: false, // caller enriches with follow state
        isPremium: roles?.contains('premium') ?? false,
      );
    }).toList();
  }

  // ── Writes ─────────────────────────────────────────────────────────────────

  Future<void> follow(String userId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      // Pre-flight check: ensure the current user has a public profile record.
      // This handles "zombie" accounts that exist in Auth but not in public.users.
      await _client.rpc('ensure_user_profile');

      await _client.from('follows').insert({
        'follower_id': uid,
        'followed_id': userId,
      });
    } catch (e) {
      // ignore: avoid_print
      print('[PeopleRemoteDataSource] Follow failed for user $userId (follower $uid): $e');
      rethrow;
    }
  }

  Future<void> unfollow(String userId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client
          .from('follows')
          .delete()
          .eq('follower_id', uid)
          .eq('followed_id', userId);
    } catch (e) {
      // ignore: avoid_print
      print('[PeopleRemoteDataSource] Unfollow failed for user $userId (follower $uid): $e');
      rethrow;
    }
  }

  /// Returns the set of userIds the current user follows (for enriching search results).
  Future<Set<String>> fetchFollowedIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return {};
    final rows = await _client
        .from('follows')
        .select('followed_id')
        .eq('follower_id', uid);
    return (rows as List<dynamic>)
        .map((r) => r['followed_id'] as String)
        .toSet();
  }

  /// Fetches a single user by ID.
  Future<PeopleUserEntity?> fetchUser(String userId) async {
    final uid = _client.auth.currentUser?.id;
    final row = await _client
        .from('users')
        .select('id, username, avatar_id, roles')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;

    final roles = row['roles'] as List<dynamic>?;
    final isFollowing = uid != null &&
        (await _client
                .from('follows')
                .select('followed_id')
                .eq('follower_id', uid)
                .eq('followed_id', userId)
                .maybeSingle()) !=
            null;

    return PeopleUserEntity(
      userId: row['id'] as String,
      username: row['username'] as String,
      avatarId: row['avatar_id'] as int?,
      isFollowing: isFollowing,
      isPremium: roles?.contains('premium') ?? false,
    );
  }
}
