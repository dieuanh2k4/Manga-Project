import 'package:dio/dio.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/data/models/author.dart';
import 'package:web_admin/data/models/genre.dart';

class LookupApiService {
  final Dio _dio;

  LookupApiService(this._dio);

  Future<List<AuthorModel>> getAllAuthors() async {
    final response = await _dio.get<dynamic>(
      '${newAPIBaseURL}Author/get-all-author',
    );

    final rawList = _extractList(response.data);

    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(AuthorModel.fromJson)
        .toList();
  }

  Future<List<GenreModel>> getAllGenres() async {
    final response = await _dio.get<dynamic>(
      '${newAPIBaseURL}Genre/get-all-genre',
    );

    final rawList = _extractList(response.data);

    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(GenreModel.fromJson)
        .toList();
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
