import 'package:equatable/equatable.dart';

class AuthorEntity extends Equatable {
  final int? id;
  final String? fullName;

  const AuthorEntity({this.id, this.fullName});

  @override
  List<Object?> get props => [id, fullName];
}
