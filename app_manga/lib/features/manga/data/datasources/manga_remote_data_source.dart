import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/network/json_list_parser.dart';
import '../models/genre_model.dart';
import '../models/manga_model.dart';

class MangaRemoteDataSource {
  Future<List<MangaModel>> getAllManga() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/Manga/get-all-manga'),
    );

    if (response.statusCode != 200) {
      throw Exception('API get-all-manga failed: ${response.statusCode} ${response.body}');
    }

    return _parseMangaList(response.body);
  }

  Future<List<MangaModel>> searchManga(String query) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/Manga/search').replace(
        queryParameters: {'query': query},
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('API search manga failed: ${response.statusCode} ${response.body}');
    }

    return _parseMangaList(response.body);
  }

  Future<List<MangaModel>> getOngoingManga() async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/Manga/manga-ongoing'),
    );

    if (response.statusCode != 200) {
      throw Exception('API manga-ongoing failed: ${response.statusCode} ${response.body}');
    }

    return _parseMangaList(response.body);
  }

  Future<List<MangaModel>> getCompletedManga() async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/Manga/manga-completed'),
    );

    if (response.statusCode != 200) {
      throw Exception('API manga-completed failed: ${response.statusCode} ${response.body}');
    }

    return _parseMangaList(response.body);
  }

  Future<List<MangaModel>> getMangaByGenre(int genreId) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/Manga/sort-by-genre').replace(
        queryParameters: {'genreId': '$genreId'},
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('API sort-by-genre failed: ${response.statusCode} ${response.body}');
    }

    return _parseMangaList(response.body);
  }

  Future<List<GenreModel>> getAllGenres() async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/Genre/get-all-genre'),
    );

    if (response.statusCode != 200) {
      throw Exception('API get-all-genre failed: ${response.statusCode} ${response.body}');
    }

    final data = json.decode(response.body);
    final listData = JsonListParser.extractList(data);

    return listData
        .whereType<Map<String, dynamic>>()
        .where((e) => !e.containsKey(r'$ref'))
        .map(GenreModel.fromJson)
        .where((e) => e.id > 0 && e.name.isNotEmpty)
        .toList();
  }

  List<MangaModel> _parseMangaList(String rawBody) {
    final data = json.decode(rawBody);
    final listData = JsonListParser.extractList(data);

    return listData
        .whereType<Map<String, dynamic>>()
        .where((e) => !e.containsKey(r'$ref') && (e.containsKey('id') || e.containsKey('Id')))
        .map(MangaModel.fromJson)
        .toList();
  }
}
