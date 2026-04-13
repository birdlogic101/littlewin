import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/design_system.dart';
import '../../../domain/entities/people_user_entity.dart';
import '../../../domain/entities/active_run_entity.dart';
import '../../../domain/entities/completed_run_entity.dart';
import '../../../data/repositories/runs_repository.dart';
import '../../widgets/png_streak_ring.dart';
import '../../widgets/lw_icon.dart';
import '../../widgets/lw_empty_state.dart';
import '../../bloc/people/people_bloc.dart';
import '../../bloc/people/people_event.dart';
import '../../bloc/people/people_state.dart';
import '../../../domain/entities/challenge_record.dart';
import '../../widgets/lw_card_action.dart';
import '../../widgets/run_record_card.dart';
import '../../widgets/challenge_history_sheet.dart';
import '../../widgets/run_bets_sheet.dart';
import '../../../data/repositories/bet_repository.dart';
import '../../../core/di/injection.dart';
import '../../widgets/lw_pill_action.dart';

class ViewUserScreen extends StatefulWidget {
  final PeopleUserEntity user;
  final RunsRepository runsRepository;

  const ViewUserScreen({
    super.key,
    required this.user,
    required this.runsRepository,
  });

  @override
  State<ViewUserScreen> createState() => _ViewUserScreenState();
}

class _ViewUserScreenState extends State<ViewUserScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<ActiveRunEntity>> _ongoingFuture;
  late Future<List<CompletedRunEntity>> _completedFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _ongoingFuture = widget.runsRepository.fetchUserRuns(widget.user.userId);
    _completedFuture = widget.runsRepository.fetchUserCompletedRuns(widget.user.userId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    // Using BlocBuilder so the follow button updates instantly when toggled
    return BlocBuilder<PeopleBloc, PeopleState>(
      buildWhen: (prev, curr) => curr is PeopleLoaded,
      builder: (context, state) {
        // Resolve the most up-to-date user state from PeopleBloc
        PeopleUserEntity currentUserState = widget.user;
        if (state is PeopleLoaded) {
          final matchedUser = [...state.followedUsers, ...state.followersUsers]
              .where((u) => u.userId == widget.user.userId)
              .firstOrNull;

          if (matchedUser != null) {
            currentUserState = matchedUser;
          } else {
            // If they are not in the loaded lists (e.g. removed after unfollow),
            // then we are definitively not following them.
            currentUserState = currentUserState.copyWith(isFollowing: false);
          }
        }

        return Scaffold(
          backgroundColor: lw.backgroundApp,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: AppBar(
              backgroundColor: lw.backgroundApp,
              elevation: LWElevation.none,
              toolbarHeight: 64,
              centerTitle: false,
              titleSpacing: 0,
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: LwIcon('arrows_back', size: 24, color: LWColors.skyDark),
                ),
              ),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(avatarId: currentUserState.avatarId, size: 32),
                  const SizedBox(width: LWSpacing.sm),
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      // Subtle offset to counteract visual downward bias of smallNoneBold
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              currentUserState.username,
                              style: LWTypography.smallNoneBold.copyWith(color: LWColors.inkBase),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (currentUserState.isPremium) ...[
                            const SizedBox(width: 4),
                            const LwIcon(
                              'misc_crown',
                              size: 14,
                              color: Color(0xFFFFD700),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: LWSpacing.md),
                  child: Center(
                    child: _FollowButton(
                      isFollowing: currentUserState.isFollowing,
                      onTap: () {
                        context.read<PeopleBloc>().add(
                          PeopleFollowToggled(userId: currentUserState.userId, user: currentUserState)
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Container(
                height: 48,
                color: lw.backgroundApp,
                child: TabBar(
                  controller: _tabController,
                  labelStyle: LWTypography.regularNoneBold,
                  unselectedLabelStyle: LWTypography.regularNoneRegular,
                  labelColor: lw.contentPrimary,
                  unselectedLabelColor: lw.contentSecondary,
                  indicatorColor: lw.contentPrimary,
                  indicatorWeight: 1,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: lw.borderSubtle,
                  dividerHeight: 1,
                  tabs: const [Tab(text: 'Ongoing'), Tab(text: 'Completed')],
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: LWColors.skyLighter,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _OngoingTab(
                        future: _ongoingFuture,
                        runsRepository: widget.runsRepository,
                        username: widget.user.username,
                      ),
                      _CompletedTab(
                        future: _completedFuture,
                        runsRepository: widget.runsRepository,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OngoingTab extends StatelessWidget {
  final Future<List<ActiveRunEntity>> future;
  final RunsRepository runsRepository;
  final String username;

  const _OngoingTab({
    required this.future,
    required this.runsRepository,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ActiveRunEntity>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load runs: ${snapshot.error}'));
        }
        final runs = snapshot.data ?? [];
        if (runs.isEmpty) {
          return const LWEmptyState(title: 'No ongoing runs', subtitle: 'This user is taking a break.');
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: LWSpacing.sm),
          itemCount: runs.length,
          itemBuilder: (context, i) => _OngoingCard(
            run: runs[i],
            runsRepository: runsRepository,
            username: username,
          ),
        );
      },
    );
  }
}

class _CompletedTab extends StatelessWidget {
  final Future<List<CompletedRunEntity>> future;
  final RunsRepository runsRepository;

  const _CompletedTab({
    required this.future,
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
        if (snapshot.hasError) {
          return Center(child: Text('Failed to load records: ${snapshot.error}'));
        }
        final runs = snapshot.data ?? [];
        if (runs.isEmpty) {
          return const LWEmptyState(title: 'No completed runs', subtitle: 'Nothing completed yet.');
        }

        final groups = ChallengeRecord.fromRuns(runs);

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: LWSpacing.sm),
          itemCount: groups.length,
          itemBuilder: (context, i) {
            final g = groups[i];
            return RunRecordCard(
              record: g,
              actionLabel: 'Join',
              actionIcon: 'misc_join',
              iconSize: 21,
              onRetry: () {
                final first = g.runs.first;
                runsRepository.joinChallenge(
                  g.challengeId,
                  title: g.challengeTitle,
                  slug: g.challengeSlug,
                  imageAsset: first.imageAsset,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Joined challenge!')),
                );
              },
              onViewHistory: () => ChallengeHistorySheet.show(
                context,
                record: g,
              ),
            );
          },
        );
      },
    );
  }
}

class _OngoingCard extends StatelessWidget {
  final ActiveRunEntity run;
  final RunsRepository runsRepository;
  final String username;

  const _OngoingCard({
    required this.run,
    required this.runsRepository,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: LWSpacing.xs),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: lw.backgroundCard,
        borderRadius: BorderRadius.circular(LWRadius.lg),
        border: Border.all(color: lw.borderSubtle, width: 1),
      ),
      child: Row(
        children: [
          PngStreakRing(streak: run.currentStreak, size: 64, numberColor: LWColors.inkBase),
          const SizedBox(width: LWSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start, // Higher positioning
              children: [
                const SizedBox(height: 4), // Optical nudge
                Row(
                  children: [
                    if (!run.isPublic)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: LwIcon(
                          'misc_incognito',
                          size: 16,
                          color: lw.contentSecondary.withOpacity(0.7),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        run.challengeTitle,
                        style: LWTypography.regularNoneBold.copyWith(color: LWColors.inkBase),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Increased gap from 6 to 12
                LWPillAction(
                  icon: 'misc_bet',
                  label: run.betCount == 0 ? 'Bet' : '${run.betCount}',
                  contentColor: run.betCount == 0 ? LWColors.primaryBase : LWColors.inkLighter,
                  onTap: () => RunBetsSheet.show(
                    context,
                    runId: run.runId,
                    currentStreak: run.currentStreak,
                    username: username,
                    isSelfBet: false,
                    betRepository: getIt<BetRepository>(),
                  ),
                ),
              ],
            ),
          ),
        LWCardAction(
          icon: 'misc_join',
          iconSize: 21,
          onTap: () {
            runsRepository.joinChallenge(
              run.challengeId,
              title: run.challengeTitle,
              slug: run.challengeSlug,
              imageAsset: run.imageAsset,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Joined challenge!')),
            );
          },
          semanticLabel: 'Join challenge',
        ),
      ],
    ),
  );
}
}



// _CompletedCard removed in favor of RunRecordCard for smart grouping.

// ── Shared local subcomponents ───────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final int? avatarId;
  final double size;
  const _Avatar({this.avatarId, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: LWColors.skyLight,
        border: Border.all(color: LWThemeExtension.of(context).borderSubtle, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarId != null
          ? Image.asset(
              'assets/avatars/avatar_$avatarId.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.person_rounded, color: Colors.white70, size: size * 0.7),
            )
          : Icon(Icons.person_rounded, color: Colors.white70, size: size * 0.7),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;

  const _FollowButton({required this.isFollowing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textColor = isFollowing ? LWColors.skyDark : LWColors.primaryBase;

    return Semantics(
      label: isFollowing ? 'Unfollow user' : 'Follow user',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: LWColors.skyLightest,
            borderRadius: BorderRadius.circular(LWRadius.pill),
          ),
          child: Text(
            isFollowing ? 'Unfollow' : 'Follow',
            style: LWTypography.regularNormalBold.copyWith(
              color: textColor,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
