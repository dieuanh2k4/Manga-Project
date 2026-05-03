import 'package:web_admin/core/models/upload_file_data.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/domain/entities/manga.dart';

abstract class MangaRepository {
  Future<DataState<List<MangaEntity>>> getManga();

  Future<DataState<bool>> createManga(
    MangaEntity manga, {
    UploadFileData? thumbnailFile,
  });

  Future<DataState<bool>> updateManga(
    MangaEntity manga, {
    UploadFileData? thumbnailFile,
  });

  Future<DataState<bool>> deleteManga(int mangaId);
}
