import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:web_admin/featured/manage_manga/domain/entities/manga.dart';

abstract class RemoteMangaState extends Equatable {
  final List<MangaEntity>? manga;
  final DioError? error;

  const RemoteMangaState({this.manga, this.error});

  @override
  List<Object?> get props => [manga, error];
}

class RemoteMangaLoading extends RemoteMangaState {
  const RemoteMangaLoading();
}

class RemoteMangaDone extends RemoteMangaState {
  const RemoteMangaDone(List<MangaEntity> manga) : super(manga: manga);
}

class RemoteMangaError extends RemoteMangaState {
  const RemoteMangaError(DioError error) : super(error: error);
}
