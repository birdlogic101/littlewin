import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/people/people_bloc.dart';
import '../../bloc/people/people_event.dart';
import '../../bloc/people/people_state.dart';
import '../../widgets/user_card.dart';
import '../../widgets/add_person_sheet.dart';
import '../../widgets/user_runs_sheet.dart';
import '../../../data/repositories/people_repository.dart';
import '../../../data/repositories/runs_repository.dart';
import '../../../data/repositories/bet_repository.dart';
import '../../widgets/lw_button.dart';
import '../../../core/theme/design_system.dart';

/// The People tab — Followed / Followers lists with search.
class PeopleScreen extends StatefulWidget {
  final PeopleRepository peopleRepository;
  final RunsRepository runsRepository;
  final BetRepository betRepository;

  const PeopleScreen({
    super.key,
    required this.peopleRepository,
    required this.runsRepository,
    required this.betRepository,
  });

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<PeopleBloc>().add(const PeopleFetchRequested());

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _searchController.clear();
      context.read<PeopleBloc>().add(PeopleTabChanged(
            _tabController.index == 0
                ? PeopleTab.followed
                : PeopleTab.followers,
          ));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAddPersonSheet() {
    AddPersonSheet.show(context, repository: widget.peopleRepository);
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return BlocBuilder<PeopleBloc, PeopleState>(
      builder: (context, state) {
        return ColoredBox(
          color: lw.backgroundApp,
          child: Column(
            children: [
              // ── Tab bar ────────────────────────────────────────────────
              Container(
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
                  tabs: const [
                    Tab(text: 'Followed'),
                    Tab(text: 'Followers'),
                  ],
                ),
              ),

              // ── Search bar ─────────────────────────────────────────────
              if (state is PeopleLoaded) ...[
                if (state.followedUsers.length > 20 ||
                    state.followersUsers.length > 20 ||
                    _searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      LWSpacing.lg,
                      LWSpacing.lg,
                      LWSpacing.lg,
                      LWSpacing.sm,
                    ),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onChanged: (q) => context
                          .read<PeopleBloc>()
                          .add(PeopleSearchChanged(query: q)),
                      style: LWTypography.smallTightRegular
                          .copyWith(color: lw.contentPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        hintStyle: LWTypography.smallTightRegular
                            .copyWith(color: lw.contentSecondary),
                        filled: true,
                        fillColor: lw.backgroundSurface,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: lw.contentSecondary, size: 22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(LWRadius.sm),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(LWRadius.sm),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  context.read<PeopleBloc>().add(
                                      const PeopleSearchChanged(query: ''));
                                },
                                child: Icon(Icons.clear_rounded,
                                    color: lw.contentSecondary, size: 18),
                              )
                            : null,
                      ),
                    ),
                  ),
              ],

              // ── Tab content ────────────────────────────────────────────
              Expanded(
                child: switch (state) {
                  PeopleInitial() || PeopleLoading() => const _LoadingView(),
                  PeopleFailure(:final message) => _ErrorView(message: message),
                  PeopleLoaded() => _buildList(context, state),
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, PeopleLoaded state) {
    final users = state.visibleUsers;
    if (users.isEmpty) {
      return _EmptyView(
        hasQuery: _searchController.text.trim().isNotEmpty,
        onInvite: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite logic coming soon!')),
          );
        },
        onFind: _openAddPersonSheet,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: LWSpacing.sm, bottom: LWSpacing.xxl),
      itemCount: users.length,
      itemBuilder: (_, i) {
        final user = users[i];
        return UserCard(
          key: ValueKey(user.userId),
          user: user,
          mode: UserCardMode.listRow,
          onFollowToggle: () => context
              .read<PeopleBloc>()
              .add(PeopleFollowToggled(userId: user.userId, user: user)),
          onTap: () => UserRunsSheet.show(
            context,
            userId: user.userId,
            username: user.username,
            avatarId: user.avatarId,
            runsRepository: widget.runsRepository,
            betRepository: widget.betRepository,
          ),
        );
      },
    );
  }
}

// ── Supporting views ──────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Center(
      child: CircularProgressIndicator(color: lw.brandPrimary, strokeWidth: 2.5),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool hasQuery;
  final VoidCallback? onInvite;
  final VoidCallback? onFind;

  const _EmptyView({
    required this.hasQuery,
    this.onInvite,
    this.onFind,
  });

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LWSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off_outlined,
                size: 80, color: lw.contentSecondary.withOpacity(0.6)),
            const SizedBox(height: LWSpacing.lg),
            Text(
              hasQuery ? 'No users found' : 'No one here yet',
              style: LWTypography.title4.copyWith(color: lw.contentPrimary),
            ),
            const SizedBox(height: LWSpacing.sm),
            Text(
              hasQuery
                  ? 'Try a different username.'
                  : 'Follow people to see them here.',
              style: LWTypography.regularNoneRegular
                  .copyWith(color: lw.contentSecondary),
              textAlign: TextAlign.center,
            ),
            if (!hasQuery) ...[
              const SizedBox(height: LWSpacing.xxl),
              LwButton.primary(
                label: 'Invite Someone',
                onPressed: onInvite,
                width: double.infinity,
              ),
              const SizedBox(height: LWSpacing.md),
              LwButton.secondary(
                label: 'Find User',
                onPressed: onFind,
                width: double.infinity,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LWSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 48, color: lw.contentSecondary),
            const SizedBox(height: LWSpacing.lg),
            Text('Could not load users.',
                style: LWTypography.regularNoneBold
                    .copyWith(color: lw.contentPrimary)),
            const SizedBox(height: LWSpacing.sm),
            Text(message,
                style: LWTypography.smallTightRegular
                    .copyWith(color: lw.contentSecondary),
                textAlign: TextAlign.center,
                maxLines: 3),
            const SizedBox(height: LWSpacing.xl),
            ElevatedButton(
              onPressed: () =>
                  context.read<PeopleBloc>().add(const PeopleFetchRequested()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
