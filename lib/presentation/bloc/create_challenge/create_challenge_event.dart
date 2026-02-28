import 'package:equatable/equatable.dart';

abstract class CreateChallengeEvent extends Equatable {
  const CreateChallengeEvent();
  @override
  List<Object?> get props => [];
}

class CreateChallengeSubmitted extends CreateChallengeEvent {
  final String title;
  final String description;
  final String visibility; // 'public' | 'private'

  const CreateChallengeSubmitted({
    required this.title,
    required this.description,
    required this.visibility,
  });

  @override
  List<Object?> get props => [title, description, visibility];
}
