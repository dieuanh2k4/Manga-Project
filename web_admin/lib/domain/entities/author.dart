import 'package:equatable/equatable.dart';

class AuthorEntity extends Equatable {
  final int? id;
  final String? fullName;
  final String? description;

  const AuthorEntity({this.id, this.fullName, this.description});

  @override
  List<Object?> get props => [id, fullName, description];
}
