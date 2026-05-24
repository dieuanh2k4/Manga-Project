import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../models/library_manga_model.dart';

class LibraryRemoteDataSource {
  Future<List<LibraryMangaModel>> getLibraryManga(String token) async {
    http.Response response;
    try {
      response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/Library/get-manga-in-library'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      throw Exception('Network error get-manga-in-library: $e');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'API get-manga-in-library failed: ${response.statusCode} ${response.body}',
      );
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
        final values = rawData[r'$values'];
        if (values is List) {
          data = values;
        } else {
          data = [rawData];
        }
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
    http.Response response;
    try {
      response = await http.post(
        Uri.parse(
          '${AppConfig.apiBaseUrl}/Library/add-manga-to-library?mangaId=$mangaId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      throw Exception('Network error add-manga-to-library: $e');
    }
    if (response.statusCode == 400 && _isAlreadyInLibraryMessage(response.body)) {
      return;
    }
    if (response.statusCode != 200) {
      throw Exception(
        'API add-manga-to-library failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> deleteMangaFromLibrary(int mangaId, String token) async {
    http.Response response;
    try {
      response = await http.delete(
        Uri.parse(
          '${AppConfig.apiBaseUrl}/Library/delete-manga-to-library?mangaId=$mangaId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      throw Exception('Network error delete-manga-to-library: $e');
    }
    if (response.statusCode != 200) {
      throw Exception(
        'API delete-manga-to-library failed: ${response.statusCode} ${response.body}',
      );
    }
  }
}

bool _isAlreadyInLibraryMessage(String responseBody) {
  try {
    final decoded = json.decode(responseBody);
    if (decoded is Map<String, dynamic>) {
      final values = _collectStringValues(decoded);
      values.add(responseBody);
      return values.any(_isAlreadyInLibraryText);
    }
  } catch (_) {
    return _isAlreadyInLibraryText(responseBody);
  }
  return false;
}

bool _isAlreadyInLibraryText(String input) {
  final normalized = _stripDiacritics(input.toLowerCase());
  return (normalized.contains('da them') && normalized.contains('thu vien')) ||
      normalized.contains('already in') ||
      normalized.contains('already added');
}

Set<String> _collectStringValues(Map<String, dynamic> map) {
  final results = <String>{};
  map.forEach((_, value) {
    if (value is String) {
      results.add(value);
    } else if (value is Map<String, dynamic>) {
      results.addAll(_collectStringValues(value));
    } else if (value is List) {
      for (final item in value) {
        if (item is String) {
          results.add(item);
        } else if (item is Map<String, dynamic>) {
          results.addAll(_collectStringValues(item));
        }
      }
    }
  });
  return results;
}

String _stripDiacritics(String input) {
  const map = {
    'a': 'àáảãạâầấẩẫậăằắẳẵặ',
    'e': 'èéẻẽẹêềếểễệ',
    'i': 'ìíỉĩị',
    'o': 'òóỏõọôồốổỗộơờớởỡợ',
    'u': 'ùúủũụưừứửữự',
    'y': 'ỳýỷỹỵ',
    'd': 'đ',
  };

  var result = input;
  map.forEach((ascii, chars) {
    result = result.replaceAll(RegExp('[$chars]'), ascii);
  });
  return result;
}
