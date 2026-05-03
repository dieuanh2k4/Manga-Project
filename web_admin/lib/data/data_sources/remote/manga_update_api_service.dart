import 'package:dio/dio.dart';
import 'package:web_admin/core/models/upload_file_data.dart';
import 'package:web_admin/core/utils/auth_token_storage.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/domain/entities/manga.dart';

class MangaUpdateApiService {
  final Dio _dio;
  final AuthTokenStorage _authTokenStorage;

  MangaUpdateApiService(this._dio, this._authTokenStorage);

  Future<Response<dynamic>> updateManga(
    MangaEntity manga, {
    UploadFileData? thumbnailFile,
  }) async {
    final int id = manga.id ?? 0;
    final FormData formData = FormData();
    final String? token = await _authTokenStorage.getAccessToken();

    formData.fields.addAll([
      MapEntry('Title', (manga.title ?? '').trim()),
      MapEntry('Description', (manga.description ?? '').trim()),
      MapEntry('Thumbnail', _normalizeThumbnail(manga.thumbnail)),
      MapEntry('Status', (manga.status ?? '').trim()),
      MapEntry('TotalChapter', '${manga.totalChapter ?? 0}'),
      MapEntry('Rate', '${manga.rate ?? 0}'),
      MapEntry('AuthorId', '${manga.authorId ?? 0}'),
      MapEntry('ReleaseDate', _formatDate(manga.releaseDate)),
      MapEntry('EndDate', _formatDate(manga.endDate)),
    ]);

    for (final int genreId in manga.genreIds ?? const <int>[]) {
      formData.fields.add(MapEntry('GenreIds', '$genreId'));
    }

    if (thumbnailFile != null && thumbnailFile.isValid) {
      final MultipartFile multipartFile = thumbnailFile.hasBytes
          ? MultipartFile.fromBytes(
              thumbnailFile.bytes!,
              filename: thumbnailFile.fileName,
            )
          : await MultipartFile.fromFile(
              thumbnailFile.filePath!,
              filename: thumbnailFile.fileName,
            );

      formData.files.add(MapEntry('file', multipartFile));
    }

    final Map<String, dynamic> headers = <String, dynamic>{};
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = _authTokenStorage.formatBearerValue(token);
    }

    return _dio.put<dynamic>(
      '${newAPIBaseURL}Manga/update-manga/$id',
      data: formData,
      options: Options(headers: headers),
    );
  }

  Future<Response<dynamic>> createManga(
    MangaEntity manga, {
    UploadFileData? thumbnailFile,
  }) async {
    final FormData formData = await _buildMangaFormDataAsync(
      manga,
      thumbnailFile: thumbnailFile,
    );

    final Map<String, dynamic> headers = await _buildAuthHeaders();

    return _dio.post<dynamic>(
      '${newAPIBaseURL}Manga/create-manga',
      data: formData,
      options: Options(headers: headers),
    );
  }

  Future<Response<dynamic>> deleteManga(int mangaId) async {
    final Map<String, dynamic> headers = await _buildAuthHeaders();

    return _dio.delete<dynamic>(
      '${newAPIBaseURL}Manga/delete-manga/$mangaId',
      options: Options(headers: headers),
    );
  }

  String _formatDate(DateTime? value) {
    final DateTime date = value ?? DateTime.now();
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<Map<String, dynamic>> _buildAuthHeaders() async {
    final String? token = await _authTokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{
      'Authorization': _authTokenStorage.formatBearerValue(token),
    };
  }

  Future<FormData> _buildMangaFormDataAsync(
    MangaEntity manga, {
    UploadFileData? thumbnailFile,
  }) async {
    final FormData formData = FormData();

    formData.fields.addAll([
      MapEntry('Title', (manga.title ?? '').trim()),
      MapEntry('Description', (manga.description ?? '').trim()),
      MapEntry('Thumbnail', _normalizeThumbnail(manga.thumbnail)),
      MapEntry('Status', (manga.status ?? '').trim()),
      MapEntry('TotalChapter', '${manga.totalChapter ?? 0}'),
      MapEntry('Rate', '${manga.rate ?? 0}'),
      MapEntry('AuthorId', '${manga.authorId ?? 0}'),
      MapEntry('ReleaseDate', _formatDate(manga.releaseDate)),
      MapEntry('EndDate', _formatDate(manga.endDate)),
    ]);

    for (final int genreId in manga.genreIds ?? const <int>[]) {
      formData.fields.add(MapEntry('GenreIds', '$genreId'));
    }

    if (thumbnailFile != null && thumbnailFile.isValid) {
      final MultipartFile multipartFile = thumbnailFile.hasBytes
          ? MultipartFile.fromBytes(
              thumbnailFile.bytes!,
              filename: thumbnailFile.fileName,
            )
          : await MultipartFile.fromFile(
              thumbnailFile.filePath!,
              filename: thumbnailFile.fileName,
            );

      formData.files.add(MapEntry('file', multipartFile));
    }

    return formData;
  }

  String _normalizeThumbnail(String? value) {
    final String raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return '';
    }

    final Uri? uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      return raw;
    }

    final List<String> segments = uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (segments.length < 2) {
      return raw;
    }

    final String bucket = segments.first;
    final String objectPath = segments.skip(1).join('/');

    if (bucket.isEmpty || objectPath.isEmpty) {
      return raw;
    }

    return '$bucket/$objectPath';
  }
}
