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
///
/// Allows other users to:
/// - View ongoing runs and place bets.
/// - View completed runs and see streak records.
/// - Join any challenge the profile user is/was in.
class UserRunsSheet extends StatefulWidget {
  final String userId;
  final String username;
  final int? avatarId;
  final RunsRepository runsRepository;
  final BetRepository betRepository;

  const UserRunsSheet({
    super.key,
    required this.userId,
    required this.username,
    this.avatarId,
    required this.runsRepository,
    required this.betRepository,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    required String username,
    int? avatarId,
    required RunsRepository runsRepository,
    required BetRepository betRepository,
  }) {
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
      ),
    );
  }

  @override
  State<UserRunsSheet> createState() => _UserRunsSheetState();
}

class _UserRunsSheetState extends State<UserRunsSheet> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<ActiveRunEntity>> _ongoingFuture;
  late Future<List<CompletedRunEntity>> _completedFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ongoingFuture = widget.runsRepository.fetchUserRuns(widget.userId);
    _completedFuture = widget.runsRepository.fetchUserCompletedRuns(widget.userId);
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

    return Container(
      height: size.height * 0.9,
      decoration: BoxDecoration(
        color: lw.backgroundApp,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(LWRadius.lg)),
      ),
      child: Column(
        children: [
          // ── Header Section ──────────────────────────────────────────────
          const SizedBox(height: LWSpacing.md),
          Center(
            child: Container(
              width: LWComponents.modal.dragHandleWidth,
              height: LWComponents.modal.dragHandleHeight,
              decoration: BoxDecoration(
                color: lw.borderSubtle,
                borderRadius: BorderRadius.circular(LWComponents.modal.dragHandleRadius),
              ),
            ),
          ),
          const SizedBox(height: LWSpacing.md),
          
          _ProfileHeader(
            username: widget.username,
            avatarId: widget.avatarId,
            onClose: () => Navigator.pop(context),
          ),
          
          const SizedBox(height: LWSpacing.sm),
          
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
                ),
                _CompletedTab(
                  future: _completedFuture,
                  username: widget.username,
                  runsRepository: widget.runsRepository,
                ),
              ],
            ),
          ),
        ],
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
    final lw = LWThemeExtension.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LWSpacing.lg, vertical: LWSpacing.sm),
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
                  style: LWTypography.regularNormalBold.copyWith(color: lw.contentPrimary),
                ),
                Text(
                  'Member since 2026', // Static for now
                  style: LWTypography.smallNormalRegular.copyWith(color: lw.contentSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            color: lw.contentSecondary,
          ),
        ],
      ),
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
              errorBuilder: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white70),
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

  const _OngoingTab({
    required this.future,
    required this.username,
    required this.runsRepository,
    required this.betRepository,
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
        if (runs.isEmpty) return _EmptyView(message: '@$username has no ongoing runs.');

        return ListView.separated(
          padding: const EdgeInsets.all(LWSpacing.lg),
          itemCount: runs.length,
          separatorBuilder: (_, __) => const SizedBox(height: LWSpacing.lg),
          itemBuilder: (context, index) {
            final run = runs[index];
            return _ProfileRunCard(
              title: run.challengeTitle,
              subtitle: 'Current streak: ${run.currentStreak} days',
              streak: run.currentStreak,
              challengeId: run.challengeId,
              runsRepository: runsRepository,
              trailing: _BetButton(
                betCount: run.betCount,
                onTap: () {
                  RunBetsSheet.show(
                    context,
                    runId: run.runId,
                    currentStreak: run.currentStreak,
                    username: username,
                    isSelfBet: false,
                    startInPlaceMode: run.betCount == 0,
                    betRepository: betRepository,
                  );
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

  const _CompletedTab({
    required this.future,
    required this.username,
    required this.runsRepository,
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
        if (runs.isEmpty) return _EmptyView(message: '@$username has not completed any challenges yet.');

        return ListView.separated(
          padding: const EdgeInsets.all(LWSpacing.lg),
          itemCount: runs.length,
          separatorBuilder: (_, __) => const SizedBox(height: LWSpacing.lg),
          itemBuilder: (context, index) {
            final run = runs[index];
            return _ProfileRunCard(
              title: run.challengeTitle,
              subtitle: 'Final streak: ${run.finalScore} days',
              streak: run.finalScore,
              challengeId: run.challengeId,
              runsRepository: runsRepository,
              trailing: _BetButton(
                betCount: 0, // No bets on completed runs shown here usually, or fixed UI
                onTap: () {}, // Handled differently if needed
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
  final int streak;
  final String challengeId;
  final RunsRepository runsRepository;
  final Widget trailing;

  const _ProfileRunCard({
    required this.title,
    required this.subtitle,
    required this.streak,
    required this.challengeId,
    required this.runsRepository,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Container(
      padding: const EdgeInsets.all(LWSpacing.md),
      decoration: BoxDecoration(
        color: lw.backgroundCard,
        borderRadius: BorderRadius.circular(LWRadius.md),
        border: Border.all(color: lw.borderSubtle),
      ),
      child: Column(
        children: [
          Row(
            children: [
              PngStreakRing(
                streak: streak,
                size: 56,
                numberColor: lw.contentPrimary,
              ),
              const SizedBox(width: LWSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: LWTypography.regularNormalBold.copyWith(color: lw.contentPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: LWTypography.smallNormalRegular.copyWith(color: lw.contentSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LWSpacing.sm),
              trailing,
            ],
          ),
          const SizedBox(height: LWSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: LWSpacing.sm),
          _JoinSection(challengeId: challengeId, runsRepository: runsRepository),
        ],
      ),
    );
  }
}

class _JoinSection extends StatelessWidget {
  final String challengeId;
  final RunsRepository runsRepository;

  const _JoinSection({required this.challengeId, required this.runsRepository});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return BlocBuilder<CheckinBloc, CheckinState>(
      builder: (context, state) {
        final isAlreadyJoined = state is CheckinLoaded &&
            state.runs.any((r) => r.challengeId == challengeId);

        if (isAlreadyJoined) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: lw.feedbackPositive),
              const SizedBox(width: 6),
              Text(
                'You are in this challenge',
                style: LWTypography.smallNormalMedium.copyWith(color: lw.feedbackPositive),
              ),
            ],
          );
        }

        return GestureDetector(
          onTap: () {
            // Optimistic join
            runsRepository.addRun(ActiveRunEntity(
              runId: 'temp-${DateTime.now().millisecondsSinceEpoch}',
              challengeId: challengeId,
              challengeTitle: '', // will be enriched by repo
              challengeSlug: '',
              currentStreak: 0,
              startDate: '',
              hasCheckedInToday: false,
              lastCheckinDay: null,
            ));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LwIcon('misc_plus', size: 14, color: lw.brandPrimary),
                const SizedBox(width: 8),
                Text(
                  'Start this challenge too',
                  style: LWTypography.smallNormalBold.copyWith(color: lw.brandPrimary),
                ),
              ],
            ),
          ),
        );
      },
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
              style: LWTypography.regularNormalRegular.copyWith(color: lw.contentSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
