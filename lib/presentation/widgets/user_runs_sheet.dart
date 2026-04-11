import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/design_system.dart';
import '../../data/repositories/bet_repository.dart';
import '../../data/repositories/runs_repository.dart';
import '../../domain/entities/active_run_entity.dart';
import '../../domain/entities/completed_run_entity.dart';
import '../bloc/checkin/checkin_bloc.dart';
import '../bloc/checkin/checkin_state.dart';
import 'run_bets_sheet.dart';
import 'png_streak_ring.dart';
import 'lw_icon.dart';

/// A bottom sheet that displays a user's profile info (ongoing and completed runs).
class UserRunsSheet extends StatefulWidget {
  final String userId;
  final String username;
  final int? avatarId;
  final RunsRepository runsRepository;
  final BetRepository betRepository;
  final Set<String> joinedChallengeIds;

  const UserRunsSheet({
    super.key,
    required this.userId,
    required this.username,
    this.avatarId,
    required this.runsRepository,
    required this.betRepository,
    this.joinedChallengeIds = const {},
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String username,
    int? avatarId,
    required RunsRepository runsRepository,
    required BetRepository betRepository,
  }) {
    final checkinState = context.read<CheckinBloc>().state;
    final joinedChallengeIds = checkinState is CheckinLoaded
        ? checkinState.runs.map((r) => r.challengeId).toSet()
        : const <String>{};

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserRunsSheet(
        userId: userId,
        username: username,
        avatarId: avatarId,
        runsRepository: runsRepository,
        betRepository: betRepository,
        joinedChallengeIds: joinedChallengeIds,
      ),
    );
  }

  @override
  State<UserRunsSheet> createState() => _UserRunsSheetState();
}

class _UserRunsSheetState extends State<UserRunsSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<ActiveRunEntity>> _ongoingFuture;
  late Future<List<CompletedRunEntity>> _completedFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshOngoing();
    _refreshCompleted();
  }

  void _refreshOngoing() {
    setState(() {
      _ongoingFuture = widget.runsRepository.fetchUserRuns(widget.userId);
    });
  }

  void _refreshCompleted() {
    setState(() {
      _completedFuture =
          widget.runsRepository.fetchUserCompletedRuns(widget.userId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final size = MediaQuery.of(context).size;

    return Material(
      color: lw.backgroundApp,
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(LWRadius.lg)),
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        height: size.height * 0.9,
        child: Column(
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

            _ProfileHeader(
              username: widget.username,
              avatarId: widget.avatarId,
              onClose: () => Navigator.pop(context),
            ),

            TabBar(
              controller: _tabController,
              labelStyle: LWTypography.regularNormalBold,
              unselectedLabelStyle: LWTypography.regularNormalRegular,
              labelColor: lw.contentPrimary,
              unselectedLabelColor: lw.contentSecondary,
              indicatorColor: lw.brandPrimary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Ongoing'),
                Tab(text: 'Completed'),
              ],
            ),
            const Divider(height: 1),

            // ── Tab Content ──────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OngoingTab(
                    future: _ongoingFuture,
                    username: widget.username,
                    runsRepository: widget.runsRepository,
                    betRepository: widget.betRepository,
                    joinedChallengeIds: widget.joinedChallengeIds,
                    onRefresh: _refreshOngoing,
                  ),
                  _CompletedTab(
                    future: _completedFuture,
                    username: widget.username,
                    runsRepository: widget.runsRepository,
                    joinedChallengeIds: widget.joinedChallengeIds,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String username;
  final int? avatarId;
  final VoidCallback onClose;

  const _ProfileHeader({
    required this.username,
    this.avatarId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              LWSpacing.xl, LWSpacing.lg, LWSpacing.sm, LWSpacing.md),
          child: Row(
            children: [
              _Avatar(avatarId: avatarId, size: 48),
              const SizedBox(width: LWSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@$username',
                      style: LWTypography.largeNoneBold.copyWith(
                        color: LWColors.inkBase,
                      ),
                    ),
                    Text(
                      'Member since 2026',
                      style: LWTypography.smallNoneRegular.copyWith(
                        color: LWColors.inkLighter,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              // Close icon: 24×24, skyDark, weight ≈ stroke 1.5
              GestureDetector(
                onTap: onClose,
                child: Padding(
                  padding: const EdgeInsets.all(LWSpacing.sm),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 24,
                    color: LWColors.skyDark,
                    weight: 300,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final int? avatarId;
  final double size;
  const _Avatar({this.avatarId, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LWColors.skyLight,
        border: Border.all(
          color: LWThemeExtension.of(context).borderSubtle,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarId != null
          ? Image.asset(
              'assets/avatars/avatar_$avatarId.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.person_rounded, color: Colors.white70),
            )
          : const Icon(Icons.person_rounded, color: Colors.white70),
    );
  }
}

// ── Ongoing Tab ──────────────────────────────────────────────────────────────

class _OngoingTab extends StatelessWidget {
  final Future<List<ActiveRunEntity>> future;
  final String username;
  final RunsRepository runsRepository;
  final BetRepository betRepository;
  final Set<String> joinedChallengeIds;
  final VoidCallback onRefresh;

  const _OngoingTab({
    required this.future,
    required this.username,
    required this.runsRepository,
    required this.betRepository,
    required this.joinedChallengeIds,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ActiveRunEntity>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final runs = snapshot.data ?? [];
        if (runs.isEmpty) {
          return _EmptyView(message: '@$username has no ongoing runs.');
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: LWSpacing.lg),
          itemCount: runs.length,
          separatorBuilder: (_, __) => const SizedBox(height: LWSpacing.lg),
          itemBuilder: (context, index) {
            final run = runs[index];
            final isJoined = joinedChallengeIds.contains(run.challengeId);
            return _ProfileRunCard(
              title: run.challengeTitle,
              subtitle: 'Current streak: ${run.currentStreak} days',
              slug: run.challengeSlug,
              streak: run.currentStreak,
              challengeId: run.challengeId,
              isAlreadyJoined: isJoined,
              runsRepository: runsRepository,
              onRefresh: onRefresh,
              trailing: _BetButton(
                betCount: run.betCount,
                onTap: () async {
                  await RunBetsSheet.show(
                    context,
                    runId: run.runId,
                    currentStreak: run.currentStreak,
                    username: username,
                    isSelfBet: false,
                    startInPlaceMode: run.betCount == 0,
                    betRepository: betRepository,
                  );
                  onRefresh();
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ── Completed Tab ─────────────────────────────────────────────────────────────

class _CompletedTab extends StatelessWidget {
  final Future<List<CompletedRunEntity>> future;
  final String username;
  final RunsRepository runsRepository;
  final Set<String> joinedChallengeIds;

  const _CompletedTab({
    required this.future,
    required this.username,
    required this.runsRepository,
    required this.joinedChallengeIds,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CompletedRunEntity>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final runs = snapshot.data ?? [];
        if (runs.isEmpty) {
          return _EmptyView(
              message: '@$username has not completed any challenges yet.');
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: LWSpacing.lg),
          itemCount: runs.length,
          separatorBuilder: (_, __) => const SizedBox(height: LWSpacing.lg),
          itemBuilder: (context, index) {
            final run = runs[index];
            return _ProfileRunCard(
              title: run.challengeTitle,
              subtitle: 'Final streak: ${run.finalScore} days',
              slug: run.challengeSlug,
              streak: run.finalScore,
              challengeId: run.challengeId,
              isAlreadyJoined: joinedChallengeIds.contains(run.challengeId),
              runsRepository: runsRepository,
              onRefresh: () {}, // Not needed for completed tab but required by constructor
              trailing: _BetButton(
                betCount: 0,
                onTap: () {},
                isCompleted: true,
                finalScore: run.finalScore,
              ),
            );
          },
        );
      },
    );
  }
}

// ── Common Components ─────────────────────────────────────────────────────────

class _ProfileRunCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? slug;
  final int streak;
  final String challengeId;
  final bool isAlreadyJoined;
  final RunsRepository runsRepository;
  final Widget trailing;
  final VoidCallback onRefresh;

  const _ProfileRunCard({
    required this.title,
    required this.subtitle,
    this.slug,
    required this.streak,
    required this.challengeId,
    required this.isAlreadyJoined,
    required this.runsRepository,
    required this.trailing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lw.backgroundCard,
        borderRadius: BorderRadius.circular(LWRadius.lg),
        border: Border.all(color: lw.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          PngStreakRing(
            streak: streak,
            size: 64, // Harmonized size
            numberColor: lw.contentPrimary,
          ),
          const SizedBox(width: LWSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: LWTypography.regularNoneBold
                      .copyWith(color: lw.contentPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8), // Increased gap
                Text(
                  subtitle,
                  style: LWTypography.smallNoneRegular
                      .copyWith(color: lw.contentSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: LWSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              trailing,
              if (!isAlreadyJoined) ...[
                const SizedBox(width: LWSpacing.sm),
                _JoinCircleButton(
                  challengeId: challengeId,
                  challengeTitle: title,
                  challengeSlug: slug,
                  runsRepository: runsRepository,
                  onJoined: onRefresh,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _JoinCircleButton extends StatefulWidget {
  final String challengeId;
  final String challengeTitle;
  final String? challengeSlug;
  final RunsRepository runsRepository;
  final VoidCallback onJoined;

  const _JoinCircleButton({
    required this.challengeId,
    required this.challengeTitle,
    this.challengeSlug,
    required this.runsRepository,
    required this.onJoined,
  });

  @override
  State<_JoinCircleButton> createState() => _JoinCircleButtonState();
}

class _JoinCircleButtonState extends State<_JoinCircleButton> {
  bool _loading = false;

  Future<void> _join() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.runsRepository.joinChallenge(
        widget.challengeId,
        title: widget.challengeTitle,
        slug: widget.challengeSlug ?? '',
      );
      widget.onJoined();
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('ALREADY_JOINED')
                ? "You're already running this challenge!"
                : "Couldn't join — please try again."),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        width: 32,
        height: 32,
        child: Center(
            child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    return GestureDetector(
      onTap: _join,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: LWColors.skyLighter,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const LwIcon(
          'misc_join',
          size: 24,
          color: LWColors.inkLight,
        ),
      ),
    );
  }
}

class _BetButton extends StatelessWidget {
  final int betCount;
  final VoidCallback onTap;
  final bool isCompleted;
  final int? finalScore;

  const _BetButton({
    required this.betCount,
    required this.onTap,
    this.isCompleted = false,
    this.finalScore,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: lw.interactiveDefault,
          borderRadius: BorderRadius.circular(LWRadius.sm),
        ),
        child: const Text('🏆', style: TextStyle(fontSize: 14)),
      );
    }

    if (betCount > 0) {
      return GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 16,
              color: Color(0xFFB0BEC5), // Subtle gray
            ),
            const SizedBox(width: 4),
            Text(
              '$betCount bet${betCount == 1 ? '' : 's'}',
              style: LWTypography.smallNormalRegular.copyWith(
                color: lw.contentSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Default "Bet" button for 0 bets
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: LWSpacing.md, vertical: LWSpacing.sm),
        decoration: BoxDecoration(
          color: lw.brandPrimary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(LWRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LwIcon('misc_bet', size: 16, color: lw.brandPrimary),
            const SizedBox(width: 6),
            Text(
              'Bet',
              style:
                  LWTypography.smallNormalBold.copyWith(color: lw.brandPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LWSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 48, color: lw.contentSecondary),
            const SizedBox(height: LWSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: LWTypography.regularNormalRegular
                  .copyWith(color: lw.contentSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
