import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/theme/design_system.dart';
import '../widgets/lw_icon.dart';

/// A reusable bottom sheet that displays a challenge's title and description.
///
/// If [description] is null, it attempts to fetch it from the 'challenge_descriptions'
/// Hive cache based on the provided [challengeId].
class ChallengeDescriptionSheet extends StatelessWidget {
  final String title;
  final String? description;
  final String? challengeId;

  const ChallengeDescriptionSheet({
    super.key,
    required this.title,
    this.description,
    this.challengeId,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? description,
    String? challengeId,
  }) {
    final lw = LWThemeExtension.of(context);
    
    // Attempt local cache lookup if description is missing but ID is present
    String? effectiveDescription = description;
    if (effectiveDescription == null && challengeId != null) {
      final box = Hive.box('challenge_descriptions');
      effectiveDescription = box.get(challengeId) as String?;
    }

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Material(
        color: lw.backgroundApp,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(LWRadius.lg),
        ),
        clipBehavior: Clip.hardEdge,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: LWSpacing.md),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: LWColors.skyBase,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header: Title
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    LWSpacing.xl, LWSpacing.lg, LWSpacing.xl, LWSpacing.lg),
                child: Text(
                  title,
                  style: LWTypography.largeNoneBold.copyWith(
                    color: LWColors.inkBase,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // ── Description body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    LWSpacing.xl,
                    LWSpacing.lg,
                    LWSpacing.xl,
                    LWSpacing.xxl,
                  ),
                  child: Text(
                    effectiveDescription ?? 'No description available.',
                    style: LWTypography.smallNoneRegular.copyWith(
                      color: LWColors.inkLighter,
                      fontWeight: FontWeight.w300,
                      height: 1.75, // open line-height for natural breathing room
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This widget is primarily used via the static .show method.
    return const SizedBox.shrink();
  }
}
