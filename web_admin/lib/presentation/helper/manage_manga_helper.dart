import 'package:dio/dio.dart';
import 'package:web_admin/domain/entities/author.dart';
import 'package:web_admin/domain/entities/genre.dart';
import 'package:web_admin/domain/entities/manga.dart';

class ManageMangaHelper {
  static Map<int, String> authorLookupFromEntities(List<AuthorEntity> authors) {
    final Map<int, String> lookup = <int, String>{};

    for (final AuthorEntity author in authors) {
      final int? id = author.id;
      final String name = (author.fullName ?? '').trim();

      if (id == null || name.isEmpty) {
        continue;
      }

      lookup[id] = name;
    }

    return lookup;
  }

  static Map<int, String> genreLookupFromEntities(List<GenreEntity> genres) {
    final Map<int, String> lookup = <int, String>{};

    for (final GenreEntity genre in genres) {
      final int? id = genre.id;
      final String name = (genre.name ?? '').trim();

      if (id == null || name.isEmpty) {
        continue;
      }

      lookup[id] = name;
    }

    return lookup;
  }

  static List<MangaEntity> applyFilters({
    required List<MangaEntity> items,
    required String globalSearchText,
    required String mangaSearchText,
    required String selectedStatus,
    required String allStatus,
    required Map<int, String> authorNameById,
    required Map<int, String> genreNameById,
  }) {
    final String keyword = '$globalSearchText $mangaSearchText'
        .trim()
        .toLowerCase();

    return items.where((MangaEntity manga) {
      final String normalizedStatus = normalizeStatus(manga.status);
      final String title = (manga.title ?? '').toLowerCase();
      final String description = (manga.description ?? '').toLowerCase();
      final String status = normalizedStatus.toLowerCase();
      final String author = buildAuthor(manga, authorNameById).toLowerCase();
      final String genres = buildGenres(manga, genreNameById).toLowerCase();

      final bool matchesKeyword =
          keyword.isEmpty ||
          title.contains(keyword) ||
          description.contains(keyword) ||
          author.contains(keyword) ||
          genres.contains(keyword) ||
          status.contains(keyword);

      final bool matchesStatus =
          selectedStatus == allStatus || normalizedStatus == selectedStatus;

      return matchesKeyword && matchesStatus;
    }).toList();
  }

  static String normalizeStatus(String? value) {
    final String status = (value ?? '').trim().toLowerCase();

    if (status.contains('ongoing') || status.contains('đang')) {
      return 'Đang tiến hành';
    }

    if (status.contains('completed') || status.contains('hoàn')) {
      return 'Hoàn thành';
    }

    if (status.contains('pause') ||
        status.contains('hiatus') ||
        status.contains('tạm')) {
      return 'Tạm dừng';
    }

    if (status.isEmpty) {
      return 'Chưa cập nhật';
    }

    return value!.trim();
  }

  static String buildAuthor(
    MangaEntity manga,
    Map<int, String> authorNameById,
  ) {
    if (manga.authorId == null || manga.authorId == 0) {
      return 'Chưa cập nhật';
    }
    return authorNameById[manga.authorId] ?? 'Tác giả #${manga.authorId}';
  }

  static String buildGenres(MangaEntity manga, Map<int, String> genreNameById) {
    if (manga.genreIds == null || manga.genreIds!.isEmpty) {
      return 'Chưa phân loại';
    }

    return manga.genreIds!
        .map((int id) => genreNameById[id] ?? 'Thể loại #$id')
        .join(', ');
  }

  static String buildViewsText(MangaEntity manga) {
    final int chapters = manga.totalChapter ?? 0;
    final int seed = manga.id ?? 1;
    final int views = chapters * 2300 + seed * 1700;
    return formatCompactNumber(views);
  }

  static String formatCompactNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toString();
  }

  static String resolveErrorMessage(DioError? error) {
    if (error == null) {
      return 'Không thể cập nhật manga';
    }

    final dynamic responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final dynamic message = responseData['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    final String errorText = (error.error ?? '').toString().trim();
    if (errorText.isNotEmpty && errorText != 'null') {
      return errorText;
    }

    final String statusMessage = (error.response?.statusMessage ?? '').trim();
    if (statusMessage.isNotEmpty) {
      return statusMessage;
    }

    return 'Không thể cập nhật manga';
  }
}
