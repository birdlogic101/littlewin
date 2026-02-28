import 'package:equatable/equatable.dart';

abstract class PeopleEvent extends Equatable {
  const PeopleEvent();

  @override
  List<Object?> get props => [];
}

/// Load both followed and followers lists from repository.
class PeopleFetchRequested extends PeopleEvent {
  const PeopleFetchRequested();
}

/// Switch between the Followed and Followers tabs.
class PeopleTabChanged extends PeopleEvent {
  final PeopleTab tab;
  const PeopleTabChanged(this.tab);

  @override
  List<Object?> get props => [tab];
}

/// Re-filter the active tab list client-side by [query].
class PeopleSearchChanged extends PeopleEvent {
  final String query;
  const PeopleSearchChanged({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Toggle follow/unfollow for a user (from either tab or search sheet).
class PeopleFollowToggled extends PeopleEvent {
  final String userId;
  const PeopleFollowToggled({required this.userId});

  @override
  List<Object?> get props => [userId];
}

enum PeopleTab { followed, followers }
