import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/challenge_creation_result.dart';

/// Remote datasource for challenge creation via Supabase.
///
/// Calls the `create_challenge` RPC which atomically:
///   1. Inserts a `challenges` row with the supplied fields
///   2. Creates an `ongoing` run for the creator
///   3. Sets participant/run counts to 1
class ChallengeRemoteDataSource {
  final SupabaseClient _client;

  ChallengeRemoteDataSource(this._client);

  /// Creates a challenge and auto-joins the current user.
  ///
  /// [title]       3–50 characters (validated by the server).
  /// [description] Optional free-text up to 500 characters.
  /// [visibility]  'public' or 'private'.
  ///
  /// Returns a [ChallengeCreationResult] on success.
  /// Throws [PostgrestException] on server errors.
  Future<ChallengeCreationResult> createChallenge({
    required String title,
    required String description,
    required String visibility,
  }) async {
    final slug = _generateSlug(title);

    final result = await _client.rpc('create_challenge', params: {
      'p_title': title,
      'p_description': description.trim().isEmpty ? null : description.trim(),
      'p_visibility': visibility,
      'p_slug': slug,
    }) as Map<String, dynamic>;

    return ChallengeCreationResult(
      challengeId: result['challenge_id'] as String,
      runId: result['run_id'] as String,
      challengeTitle: title,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Generates a URL-safe slug from a title.
  /// Example: "16-Hour Fasting!" → "16-hour-fasting-a3f2"
  static String _generateSlug(String title) {
    final base = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    final suffix = DateTime.now().millisecondsSinceEpoch
        .toRadixString(36)
        .substring(0, 4);
    return '$base-$suffix';
  }
}
