import 'package:equatable/equatable.dart';
import '../../../domain/entities/people_user_entity.dart';
import 'people_event.dart';

sealed class PeopleState extends Equatable {
  const PeopleState();

  const factory PeopleState.initial() = PeopleInitial;
  const factory PeopleState.loading() = PeopleLoading;
  const factory PeopleState.loaded({
    required List<PeopleUserEntity> followedUsers,
    required List<PeopleUserEntity> followersUsers,
    required PeopleTab activeTab,
    required String query,
  }) = PeopleLoaded;
  const factory PeopleState.failure({required String message}) = PeopleFailure;

  @override
  List<Object?> get props => [];
}

class PeopleInitial extends PeopleState {
  const PeopleInitial();
}

class PeopleLoading extends PeopleState {
  const PeopleLoading();
}

class PeopleLoaded extends PeopleState {
  final List<PeopleUserEntity> followedUsers;
  final List<PeopleUserEntity> followersUsers;
  final PeopleTab activeTab;
  final String query;

  const PeopleLoaded({
    required this.followedUsers,
    required this.followersUsers,
    required this.activeTab,
    required this.query,
  });

  /// The filtered list shown in the active tab.
  List<PeopleUserEntity> get visibleUsers {
    final base =
        activeTab == PeopleTab.followed ? followedUsers : followersUsers;
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base.where((u) => u.username.toLowerCase().contains(q)).toList();
  }

  PeopleLoaded copyWith({
    List<PeopleUserEntity>? followedUsers,
    List<PeopleUserEntity>? followersUsers,
    PeopleTab? activeTab,
    String? query,
  }) {
    return PeopleLoaded(
      followedUsers: followedUsers ?? this.followedUsers,
      followersUsers: followersUsers ?? this.followersUsers,
      activeTab: activeTab ?? this.activeTab,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props => [followedUsers, followersUsers, activeTab, query];
}

class PeopleFailure extends PeopleState {
  final String message;
  const PeopleFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
