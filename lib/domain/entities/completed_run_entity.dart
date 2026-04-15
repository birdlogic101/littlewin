import 'package:equatable/equatable.dart';

/// Represents a user's completed run shown on the Records screen.
///
/// A run completes when the first UTC day is missed.
/// [finalScore] equals the last consecutive streak count.
class CompletedRunEntity extends Equatable {
  final String runId;
  final String challengeId;
  final String challengeTitle;
  final String? challengeDescription;
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

  /// Whether the challenge associated with this run is public or private.
  final bool isPublic;

  const CompletedRunEntity({
    required this.runId,
    required this.challengeId,
    required this.challengeTitle,
    this.challengeDescription,
    required this.challengeSlug,
    required this.finalScore,
    required this.startDate,
    required this.endDate,
    this.imageAsset,
    this.imageUrl,
    this.isPublic = true,
  });

  @override
  List<Object?> get props => [
        runId,
        challengeId,
        challengeTitle,
        challengeDescription,
        challengeSlug,
        finalScore,
        startDate,
        endDate,
        imageAsset,
        imageUrl,
        isPublic,
      ];

  CompletedRunEntity copyWith({
    String? runId,
    String? challengeId,
    String? challengeTitle,
    String? challengeDescription,
    String? challengeSlug,
    int? finalScore,
    String? startDate,
    String? endDate,
    String? imageAsset,
    String? imageUrl,
    bool? isPublic,
  }) {
    return CompletedRunEntity(
      runId: runId ?? this.runId,
      challengeId: challengeId ?? this.challengeId,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      challengeDescription: challengeDescription ?? this.challengeDescription,
      challengeSlug: challengeSlug ?? this.challengeSlug,
      finalScore: finalScore ?? this.finalScore,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imageAsset: imageAsset ?? this.imageAsset,
      imageUrl: imageUrl ?? this.imageUrl,
      isPublic: isPublic ?? this.isPublic,
    );
  }
}
