import 'package:equatable/equatable.dart';

/// A single challenge that users can start a run on.
class ChallengeEntity extends Equatable {
  final String id;
  final String slug;
  final String title;
  final String description;

  /// Local asset path — e.g. `assets/pictures/challenge_16-hour-fasting.jpg`.
  /// Null if no picture has been added yet.
  final String? imageAsset;

  const ChallengeEntity({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    this.imageAsset,
  });

  @override
  List<Object?> get props => [id, slug, title, description, imageAsset];
}
