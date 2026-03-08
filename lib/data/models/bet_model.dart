import '../../domain/entities/bet_entity.dart';
import '../../domain/entities/stake_entity.dart';

/// Converts raw Supabase JSON rows into domain entities.
class BetModel {
  /// Maps a `bets` table row (with optional joined bettor username and stake title)
  /// to a [BetEntity].
  static BetEntity fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'pending';
    final status = switch (statusStr) {
      'won' => BetStatus.won,
      'lost' => BetStatus.lost,
      _ => BetStatus.pending,
    };

    // Joined bettor username — may come from a nested users object.
    String? bettorUsername;
    final bettorRow = json['users'];
    if (bettorRow is Map<String, dynamic>) {
      bettorUsername = bettorRow['username'] as String?;
    }

    String? stakeTitle;
    String? imageAsset;
    final stakeRow = json['stakes'];
    if (stakeRow is Map<String, dynamic>) {
      stakeTitle = stakeRow['title'] as String?;
      if (stakeTitle != null) {
        final slug = stakeTitle.toLowerCase().replaceAll(' ', '_');
        imageAsset = 'assets/icons/stake-$slug.png';
      }
    }

    // Custom stake: default to gift_box icon
    if (json['custom_stake_title'] != null) {
      imageAsset = 'assets/icons/stake-gift_box.png';
    }

    return BetEntity(
      id: json['id'] as String,
      runId: json['run_id'] as String,
      bettorId: json['bettor_id'] as String,
      bettorUsername: bettorUsername,
      targetStreak: json['target_streak'] as int,
      stakeId: json['stake_id'] as String?,
      stakeTitle: stakeTitle,
      customStakeTitle: json['custom_stake_title'] as String?,
      imageAsset: imageAsset,
      status: status,
      isSelfBet: json['is_self_bet'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Maps a `stakes` table row to a [StakeEntity].
  static StakeEntity stakeFromJson(Map<String, dynamic> json) {
    final catStr = json['category'] as String? ?? 'plan';
    final category = switch (catStr) {
      'gift' => StakeCategory.gift,
      'custom' => StakeCategory.custom,
      _ => StakeCategory.plan,
    };

    final title = json['title'] as String;

    // Hardcoded mapping for official stakes
    String? imageAsset;
    final slug = title.toLowerCase().replaceAll(' ', '_');
    if (category != StakeCategory.custom) {
      imageAsset = 'assets/icons/stake-$slug.png';
    }

    return StakeEntity(
      id: json['id'] as String,
      title: title,
      category: category,
      emoji: json['emoji'] as String?,
      imageAsset: imageAsset,
    );
  }
}
