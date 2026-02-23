import 'package:equatable/equatable.dart';

/// Represents a user's completed run shown on the Records screen.
///
/// A run completes when the first UTC day is missed.
/// [finalScore] equals the last consecutive streak count.
class CompletedRunEntity extends Equatable {
  final String runId;
  final String challengeId;
  final String challengeTitle;
  final String challengeSlug;

  /// The final streak reached when the run ended.
  final int finalScore;

  /// UTC start date of the run (yyyy-MM-dd).
  final String startDate;

  /// UTC date when the run was completed / missed (yyyy-MM-dd).
  final String endDate;

  /// Optional local asset path for background image.
  final String? imageAsset;

  /// Optional remote URL for background image.
  final String? imageUrl;

  const CompletedRunEntity({
    required this.runId,
    required this.challengeId,
    required this.challengeTitle,
    required this.challengeSlug,
    required this.finalScore,
    required this.startDate,
    required this.endDate,
    this.imageAsset,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
        runId,
        challengeId,
        challengeTitle,
        challengeSlug,
        finalScore,
        startDate,
        endDate,
        imageAsset,
        imageUrl,
      ];
}
