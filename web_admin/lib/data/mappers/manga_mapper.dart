import 'package:web_admin/data/models/manga.dart';
import 'package:web_admin/domain/entities/manga.dart';

extension MangaModelMapper on MangaModel {
  MangaEntity toEntity() {
    return MangaEntity(
      id: id,
      title: title,
      description: description,
      thumbnail: thumbnail,
      status: status,
      totalChapter: totalChapter,
      rate: rate,
      authorId: authorId,
      genreIds: genreIds,
      releaseDate: releaseDate,
      endDate: endDate,
    );
  }
}

extension MangaEntityMapper on MangaEntity {
  MangaModel toModel() {
    return MangaModel(
      id: id,
      title: title,
      description: description,
      thumbnail: thumbnail,
      status: status,
      totalChapter: totalChapter,
      rate: rate,
      authorId: authorId,
      genreIds: genreIds,
      releaseDate: releaseDate,
      endDate: endDate,
    );
  }
}

extension MangaModelListMapper on List<MangaModel> {
  List<MangaEntity> toEntityList() {
    return map((mangaModel) => mangaModel.toEntity()).toList();
  }
}

extension MangaEntityListMapper on List<MangaEntity> {
  List<MangaModel> toModelList() {
    return map((mangaEntity) => mangaEntity.toModel()).toList();
  }
}
