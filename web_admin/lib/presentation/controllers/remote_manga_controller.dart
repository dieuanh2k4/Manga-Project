import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/domain/usecases/get_manga.dart';

abstract class RemoteMangaState {
  final List<MangaEntity>? manga;
  final DioError? error;

  const RemoteMangaState({this.manga, this.error});
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

class RemoteMangaController extends ChangeNotifier {
  final GetMangaUseCase _getMangaUseCase;

  RemoteMangaController(this._getMangaUseCase);

  RemoteMangaState _state = const RemoteMangaLoading();

  RemoteMangaState get state => _state;

  Future<void> loadManga() async {
    _state = const RemoteMangaLoading();
    notifyListeners();

    final DataState<List<MangaEntity>> dataState = await _getMangaUseCase();

    if (dataState is DataSuccess<List<MangaEntity>> &&
        dataState.data != null) {
      _state = RemoteMangaDone(dataState.data!);
      notifyListeners();
      return;
    }

    if (dataState is DataFailed<List<MangaEntity>> &&
        dataState.error != null) {
      _state = RemoteMangaError(dataState.error!);
      notifyListeners();
    }
  }
}
