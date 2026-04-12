import 'package:web_admin/data/models/genre.dart';
import 'package:web_admin/domain/entities/genre.dart';

extension GenreModelMapper on GenreModel {
  GenreEntity toEntity() {
    return GenreEntity(id: id, name: name);
  }
}

extension GenreModelListMapper on List<GenreModel> {
  List<GenreEntity> toEntityList() {
    return map((genreModel) => genreModel.toEntity()).toList();
  }
}
