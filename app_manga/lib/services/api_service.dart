import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/genre.dart';
import '../models/manga.dart';

class ApiService {
  // Override with: flutter run --dart-define=API_BASE_URL=http://host:port/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5219/api',
  );

  static List<dynamic> _extractList(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        return data['data'];
      }

      if (data['data'] is Map<String, dynamic> &&
          data['data'][r'$values'] is List) {
        return data['data'][r'$values'];
      }

      if (data[r'$values'] is List) {
        return data[r'$values'];
      }
    }

    if (data is List) {
      return data;
    }

    return const [];
  }

  static List<Manga> _parseMangaList(String rawBody) {
    final data = json.decode(rawBody);
    final listData = _extractList(data);

    return listData
        .whereType<Map<String, dynamic>>()
        .where((e) =>
            !e.containsKey(r'$ref') &&
            (e.containsKey('id') || e.containsKey('Id')))
        .map(Manga.fromJson)
        .toList();
  }

  static Future<List<Manga>> getAllManga() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Manga/get-all-manga'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'API get-all-manga failed: ${response.statusCode} ${response.body}',
      );
    }

    return _parseMangaList(response.body);
  }

  static Future<List<Manga>> searchManga(String query) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Manga/search').replace(
        queryParameters: {'query': query},
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'API search manga failed: ${response.statusCode} ${response.body}',
      );
    }

    return _parseMangaList(response.body);
  }

  static Future<List<Manga>> getOngoingManga() async {
    final response = await http.post(
      Uri.parse('$baseUrl/Manga/manga-ongoing'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'API manga-ongoing failed: ${response.statusCode} ${response.body}',
      );
    }

    return _parseMangaList(response.body);
  }

  static Future<List<Manga>> getCompletedManga() async {
    final response = await http.post(
      Uri.parse('$baseUrl/Manga/manga-completed'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'API manga-completed failed: ${response.statusCode} ${response.body}',
      );
    }

    return _parseMangaList(response.body);
  }

  static Future<List<Manga>> getMangaByGenre(int genreId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Manga/sort-by-genre').replace(
        queryParameters: {'genreId': '$genreId'},
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'API sort-by-genre failed: ${response.statusCode} ${response.body}',
      );
    }

    return _parseMangaList(response.body);
  }

  static Future<List<Genre>> getAllGenres() async {
    final response = await http.get(
      Uri.parse('$baseUrl/Genre/get-all-genre'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'API get-all-genre failed: ${response.statusCode} ${response.body}',
      );
    }

    final data = json.decode(response.body);
    final listData = _extractList(data);

    return listData
        .whereType<Map<String, dynamic>>()
        .where((e) => !e.containsKey(r'$ref'))
        .map(Genre.fromJson)
        .where((e) => e.id > 0 && e.name.isNotEmpty)
        .toList();
  }
}
