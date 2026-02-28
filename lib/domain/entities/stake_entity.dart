import 'package:equatable/equatable.dart';

/// Category of a stake (symbolic reward).
enum StakeCategory { plan, gift, custom }

/// A symbolic stake that can be attached to a bet.
class StakeEntity extends Equatable {
  final String id;
  final String title;
  final StakeCategory category;

  /// Optional emoji shown next to the title in the UI.
  final String? emoji;

  /// Optional local PNG asset path, e.g. 'assets/icons/stake-coffee_cup.png'.
  /// Takes precedence over [emoji] when both are present.
  final String? imageAsset;

  const StakeEntity({
    required this.id,
    required this.title,
    required this.category,
    this.emoji,
    this.imageAsset,
  });

  @override
  List<Object?> get props => [id, title, category, emoji, imageAsset];
}
