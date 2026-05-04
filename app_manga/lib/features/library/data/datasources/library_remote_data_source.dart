import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../models/library_manga_model.dart';

class LibraryRemoteDataSource {
  Future<List<LibraryMangaModel>> getLibraryManga(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/Library/get-manga-in-library'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('API get-manga-in-library failed: ${response.statusCode} ${response.body}');
    }
    final decoded = json.decode(response.body);
    final List<dynamic> data;

    if (decoded is List) {
      data = decoded;
    } else if (decoded is Map<String, dynamic>) {
      final rawData = decoded['data'];
      if (rawData is List) {
        data = rawData;
      } else if (rawData is Map<String, dynamic>) {
        data = [rawData];
      } else {
        data = [];
      }
    } else {
      data = [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(LibraryMangaModel.fromJson)
        .toList();
  }

  Future<void> addMangaToLibrary(int mangaId, String token) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/Library/add-manga-to-library?mangaId=$mangaId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('API add-manga-to-library failed: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> deleteMangaFromLibrary(int mangaId, String token) async {
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/Library/delete-manga-to-library?mangaId=$mangaId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('API delete-manga-to-library failed: ${response.statusCode} ${response.body}');
    }
  }
}
