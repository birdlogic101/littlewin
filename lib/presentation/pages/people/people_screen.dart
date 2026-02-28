import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/people/people_bloc.dart';
import '../../bloc/people/people_event.dart';
import '../../bloc/people/people_state.dart';
import '../../widgets/lw_page_header.dart';
import '../../widgets/user_card.dart';
import '../../widgets/add_person_sheet.dart';
import '../../../data/repositories/people_repository.dart';
import '../../../core/theme/design_system.dart';

/// The People tab — Followed / Followers lists with search.
///
/// Header: "People" title + person+ icon (→ AddPersonSheet)
/// Tabs: Followed | Followers
/// Below the tab bar: search field (filters current tab client-side)
class PeopleScreen extends StatefulWidget {
  final PeopleRepository peopleRepository;
  const PeopleScreen({super.key, required this.peopleRepository});

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
              // ── Shared page header (centered title + person+ icon) ──────────
              LwPageHeader(
                title: 'People',
                trailingIcon: 'misc_add_contact',
                trailingSemanticLabel: 'Add person',
                onTrailingTap: _openAddPersonSheet,
              ),

              // ── Tab bar ────────────────────────────────────────────────
              TabBar(
                controller: _tabController,
                labelStyle: LWTypography.regularNormalBold,
                unselectedLabelStyle: LWTypography.regularNormalRegular,
                labelColor: lw.contentPrimary,
                unselectedLabelColor: lw.contentSecondary,
                indicatorColor: lw.contentPrimary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Followed'),
                  Tab(text: 'Followers'),
                ],
              ),

              // ── Search bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LWSpacing.lg, LWSpacing.lg, LWSpacing.lg, LWSpacing.sm,
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (q) => context
                      .read<PeopleBloc>()
                      .add(PeopleSearchChanged(query: q)),
                  decoration: InputDecoration(
                    hintText: 'Search…',
                    prefixIcon: Icon(Icons.search_rounded,
                        color: lw.contentSecondary, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              context
                                  .read<PeopleBloc>()
                                  .add(const PeopleSearchChanged(query: ''));
                            },
                            child: Icon(Icons.clear_rounded,
                                color: lw.contentSecondary, size: 18),
                          )
                        : null,
                  ),
                ),
              ),

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
      return _EmptyView(hasQuery: _searchController.text.trim().isNotEmpty);
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
              .add(PeopleFollowToggled(userId: user.userId)),
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
  const _EmptyView({required this.hasQuery});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LWSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_off_outlined, size: 60, color: lw.contentSecondary),
            const SizedBox(height: LWSpacing.lg),
            Text(
              hasQuery ? 'No users found' : 'No one here yet',
              style: LWTypography.title4.copyWith(color: lw.contentPrimary),
            ),
            const SizedBox(height: LWSpacing.sm),
            Text(
              hasQuery
                  ? 'Try a different username.'
                  : 'Tap the person+ icon to find people to follow.',
              style: LWTypography.regularNormalRegular
                  .copyWith(color: lw.contentSecondary),
              textAlign: TextAlign.center,
            ),
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
                style: LWTypography.regularNormalBold
                    .copyWith(color: lw.contentPrimary)),
            const SizedBox(height: LWSpacing.sm),
            Text(message,
                style: LWTypography.smallNormalRegular
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
