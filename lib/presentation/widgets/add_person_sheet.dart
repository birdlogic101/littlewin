import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/people_repository.dart';
import '../../domain/entities/people_user_entity.dart';
import '../../core/theme/design_system.dart';
import '../bloc/people/people_bloc.dart';
import '../bloc/people/people_event.dart';
import 'user_card.dart';

/// Bottom sheet for finding and following new people.
///
/// Has its own lightweight search state (no BLoC needed — local StatefulWidget).
/// On follow/unfollow, fires [PeopleFollowToggled] to keep the parent
/// People tab lists in sync.
class AddPersonSheet extends StatefulWidget {
  final PeopleRepository repository;

  const AddPersonSheet({super.key, required this.repository});

  static Future<void> show(
    BuildContext context, {
    required PeopleRepository repository,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<PeopleBloc>(),
        child: AddPersonSheet(repository: repository),
      ),
    );
  }

  @override
  State<AddPersonSheet> createState() => _AddPersonSheetState();
}

class _AddPersonSheetState extends State<AddPersonSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<PeopleUserEntity> _results = [];
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    final results = await widget.repository.searchUsers(q);
    if (mounted) setState(() { _results = results; _loading = false; });
  }

  void _onFollowToggle(PeopleUserEntity user) {
    // Optimistic local update
    setState(() {
      _results = _results
          .map((u) => u.userId == user.userId
              ? u.copyWith(isFollowing: !u.isFollowing)
              : u)
          .toList();
    });
    // Notify parent BLoC so the Followed tab refreshes
    context
        .read<PeopleBloc>()
        .add(PeopleFollowToggled(userId: user.userId));
  }

  @override
  Widget build(BuildContext context) {
    final lw = LWThemeExtension.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: lw.backgroundApp,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(LWRadius.lg),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        LWSpacing.lg, LWSpacing.md, LWSpacing.lg,
        bottomInset + LWSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: LWComponents.modal.dragHandleWidth,
              height: LWComponents.modal.dragHandleHeight,
              decoration: BoxDecoration(
                color: lw.borderSubtle,
                borderRadius:
                    BorderRadius.circular(LWComponents.modal.dragHandleRadius),
              ),
            ),
          ),
          const SizedBox(height: LWSpacing.lg),

          // Title
          Text(
            'Add people',
            style: LWTypography.title4
                .copyWith(color: lw.contentPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: LWSpacing.lg),

          // Search field
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Search by username…',
              prefixIcon: Icon(Icons.search_rounded,
                  color: lw.contentSecondary, size: 20),
              suffixIcon: _controller.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _controller.clear();
                        setState(() => _results = []);
                      },
                      child: Icon(Icons.clear_rounded,
                          color: lw.contentSecondary, size: 18),
                    )
                  : null,
            ),
          ),

          const SizedBox(height: LWSpacing.md),

          // Results
          if (_loading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: LWSpacing.xl),
              child: Center(
                child: CircularProgressIndicator(
                    color: lw.brandPrimary, strokeWidth: 2),
              ),
            )
          else if (_controller.text.isNotEmpty && _results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: LWSpacing.xl),
              child: Center(
                child: Text(
                  'No users found for "${_controller.text}"',
                  style: LWTypography.regularNormalRegular
                      .copyWith(color: lw.contentSecondary),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (_, i) => UserCard(
                  key: ValueKey(_results[i].userId),
                  user: _results[i],
                  mode: UserCardMode.searchResult,
                  onFollowToggle: () => _onFollowToggle(_results[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
