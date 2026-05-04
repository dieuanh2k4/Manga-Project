import 'package:web_admin/data/models/author.dart';
import 'package:web_admin/domain/entities/author.dart';

extension AuthorModelMapper on AuthorModel {
  AuthorEntity toEntity() {
    return AuthorEntity(id: id, fullName: fullName, description: description);
  }
}

extension AuthorModelListMapper on List<AuthorModel> {
  List<AuthorEntity> toEntityList() {
    return map((authorModel) => authorModel.toEntity()).toList();
  }
}
