import 'package:equatable/equatable.dart';

abstract class PeopleEvent extends Equatable {
  const PeopleEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch the initial user list (followed users + suggestions).
class PeopleFetchRequested extends PeopleEvent {
  const PeopleFetchRequested();
}

/// Re-filter the list based on the search query.
class PeopleSearchChanged extends PeopleEvent {
  final String query;
  const PeopleSearchChanged({required this.query});

  @override
  List<Object?> get props => [query];
}

/// Toggle follow/unfollow for a specific user.
class PeopleFollowToggled extends PeopleEvent {
  final String userId;
  const PeopleFollowToggled({required this.userId});

  @override
  List<Object?> get props => [userId];
}
