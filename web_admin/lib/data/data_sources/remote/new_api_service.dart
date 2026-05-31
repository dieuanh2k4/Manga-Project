import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/data/models/manga.dart';

class NewApiService {
  final Dio _dio;
  final String baseUrl;

  NewApiService(this._dio, {this.baseUrl = newAPIBaseURL});

  Future<HttpResponse<List<MangaModel>>> getManga() async {
    final Response<dynamic> response = await _dio.get<dynamic>(
      '${baseUrl}Manga/get-all-manga',
    );

    final List<MangaModel> mangas = _extractMangaMaps(
      response.data,
    ).map(MangaModel.fromJson).toList();

    return HttpResponse<List<MangaModel>>(mangas, response);
  }

  List<Map<String, dynamic>> _extractMangaMaps(dynamic data) {
    final Map<String, Map<String, dynamic>> referenceById =
        <String, Map<String, dynamic>>{};

    void collectReferences(dynamic value) {
      if (value is List) {
        for (final dynamic item in value) {
          collectReferences(item);
        }
        return;
      }

      if (value is Map) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(value);
        final dynamic referenceId = map[r'$id'];
        if (referenceId is String) {
          referenceById[referenceId] = map;
        }

        for (final dynamic child in map.values) {
          collectReferences(child);
        }
      }
    }

    collectReferences(data);

    return _extractList(data)
        .whereType<Map>()
        .map((Map item) {
          final Map<String, dynamic> map = Map<String, dynamic>.from(item);
          final dynamic reference = map[r'$ref'];
          if (reference is String && referenceById.containsKey(reference)) {
            return referenceById[reference]!;
          }
          return map;
        })
        .where(_looksLikeManga)
        .toList();
  }

  bool _looksLikeManga(Map<String, dynamic> map) {
    return (map.containsKey('id') || map.containsKey('Id')) &&
        (map.containsKey('title') ||
            map.containsKey('Title') ||
            map.containsKey('authorId') ||
            map.containsKey('AuthorId') ||
            map.containsKey('totalChapter') ||
            map.containsKey('TotalChapter'));
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map) {
      final dynamic values = data[r'$values'];
      if (values is List) {
        return values;
      }

      final dynamic directData = data['data'];
      if (directData is List) {
        return directData;
      }

      if (directData is Map) {
        final dynamic nestedValues = directData[r'$values'];
        if (nestedValues is List) {
          return nestedValues;
        }
      }

      final dynamic items = data['items'] ?? data['result'];
      if (items is List) {
        return items;
      }

      if (items is Map) {
        final dynamic nestedValues = items[r'$values'];
        if (nestedValues is List) {
          return nestedValues;
        }
      }
    }

    return const <dynamic>[];
  }
}
