import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/challenge_entity.dart';

/// Loads the bundled challenge list from `assets/data/challenges.json`.
///
/// This is the single source of truth for challenge metadata on the client.
/// When a challenge gains a Supabase record, its `id` will match the
/// `ch-XX` id in the JSON so the two can be joined.
class ChallengeLocalDatasource {
  static const _assetPath = 'assets/data/challenges.json';

  /// Returns all challenges from the seed JSON.
  Future<List<ChallengeEntity>> loadAll() async {
    final raw = await rootBundle.loadString(_assetPath);
    final map = json.decode(raw) as Map<String, dynamic>;
    final list = map['challenges'] as List<dynamic>;
    return list
        .map((e) => _fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Returns a single challenge by its `id`, or null if not found.
  Future<ChallengeEntity?> findById(String id) async {
    final all = await loadAll();
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static ChallengeEntity _fromJson(Map<String, dynamic> json) {
    return ChallengeEntity(
      id: json['id'] as String,
      slug: json['slug'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageAsset: json['image'] as String?,
    );
  }
}
