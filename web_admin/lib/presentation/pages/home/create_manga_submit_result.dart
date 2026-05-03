import 'package:web_admin/core/models/upload_file_data.dart';
import 'package:web_admin/domain/entities/manga.dart';

class CreateMangaSubmitResult {
  final MangaEntity manga;
  final UploadFileData? thumbnailFile;

  const CreateMangaSubmitResult({required this.manga, this.thumbnailFile});
}
