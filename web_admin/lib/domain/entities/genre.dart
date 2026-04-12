import 'package:equatable/equatable.dart';

class GenreEntity extends Equatable {
  final int? id;
  final String? name;

  const GenreEntity({this.id, this.name});

  @override
  List<Object?> get props => [id, name];
}
