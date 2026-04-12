import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/domain/entities/manga.dart';
import 'package:web_admin/domain/usecases/get_manga.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_event.dart';
import 'package:web_admin/presentation/bloc/manga/remote/remote_manga_state.dart';

class RemoteMangaBloc extends Bloc<RemoteMangaEvent, RemoteMangaState> {
  final GetMangaUseCase _getMangaUseCase;

  RemoteMangaBloc(this._getMangaUseCase) : super(const RemoteMangaLoading()) {
    on<GetManga>(onGetManga);
  }

  Future<void> onGetManga(
    GetManga event,
    Emitter<RemoteMangaState> emit,
  ) async {
    final dataState = await _getMangaUseCase();

    if (dataState is DataSuccess && dataState.data != null) {
      final manga = dataState.data as List<MangaEntity>;
      emit(RemoteMangaDone(manga));
      return;
    }

    if (dataState is DataFailed && dataState.error != null) {
      emit(RemoteMangaError(dataState.error!));
    }
  }
}
