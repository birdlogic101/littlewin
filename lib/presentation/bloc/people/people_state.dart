import 'package:equatable/equatable.dart';
import '../../../domain/entities/people_user_entity.dart';

sealed class PeopleState extends Equatable {
  const PeopleState();

  const factory PeopleState.initial() = PeopleInitial;
  const factory PeopleState.loading() = PeopleLoading;
  const factory PeopleState.loaded({
    required List<PeopleUserEntity> users,
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
  final List<PeopleUserEntity> users;
  final String query;
  const PeopleLoaded({required this.users, required this.query});

  @override
  List<Object?> get props => [users, query];
}

class PeopleFailure extends PeopleState {
  final String message;
  const PeopleFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
