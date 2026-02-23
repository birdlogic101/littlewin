import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/people/people_bloc.dart';
import '../../bloc/people/people_event.dart';
import '../../bloc/people/people_state.dart';
import '../../widgets/user_card.dart';
import '../../../core/theme/design_system.dart';

/// The People tab — user search, follow/unfollow.
class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<PeopleBloc>().add(const PeopleFetchRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return BlocBuilder<PeopleBloc, PeopleState>(
      builder: (context, state) {
        return ColoredBox(
          color: lw.backgroundApp,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Search bar ─────────────────────────────────────────────
              _SearchBar(
                controller: _searchController,
                onChanged: (q) => context
                    .read<PeopleBloc>()
                    .add(PeopleSearchChanged(query: q)),
              ),

              // ── Content ────────────────────────────────────────────────
              Expanded(
                child: switch (state) {
                  PeopleInitial() ||
                  PeopleLoading() =>
                    const _LoadingView(),
                  PeopleFailure(:final message) =>
                    _ErrorView(message: message),
                  PeopleLoaded(:final users) when users.isEmpty =>
                    _EmptyView(
                        hasQuery: _searchController.text.trim().isNotEmpty),
                  PeopleLoaded(:final users) => ListView.builder(
                      padding: const EdgeInsets.only(
                        top: LWSpacing.sm,
                        bottom: LWSpacing.xxl,
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return UserCard(
                          key: ValueKey(user.userId),
                          user: user,
                          onFollowToggle: () => context
                              .read<PeopleBloc>()
                              .add(PeopleFollowToggled(userId: user.userId)),
                        );
                      },
                    ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LWSpacing.lg,
        LWSpacing.xl,
        LWSpacing.lg,
        LWSpacing.sm,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search people…',
          prefixIcon: Icon(Icons.search_rounded,
              color: lw.contentSecondary, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Icon(Icons.clear_rounded,
                      color: lw.contentSecondary, size: 18),
                )
              : null,
        ),
      ),
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
            Icon(Icons.group_off_outlined,
                size: 60, color: lw.contentSecondary),
            const SizedBox(height: LWSpacing.lg),
            Text(
              hasQuery ? 'No users found' : 'Find people',
              style: LWTypography.title4.copyWith(color: lw.contentPrimary),
            ),
            const SizedBox(height: LWSpacing.sm),
            Text(
              hasQuery
                  ? 'Try a different username.'
                  : 'Search for someone by username.',
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
            Text(
              'Could not load users.',
              style: LWTypography.regularNormalBold
                  .copyWith(color: lw.contentPrimary),
            ),
            const SizedBox(height: LWSpacing.sm),
            Text(
              message,
              style: LWTypography.smallNormalRegular
                  .copyWith(color: lw.contentSecondary),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: LWSpacing.xl),
            ElevatedButton(
              onPressed: () => context
                  .read<PeopleBloc>()
                  .add(const PeopleFetchRequested()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
