// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_api_service.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers

class _NewApiService implements NewApiService {
  _NewApiService(this._dio, {this.baseUrl}) {
    baseUrl ??= 'http://localhost:5001/api/';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<HttpResponse<List<MangaModel>>> getManga() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<dynamic>(
      _setStreamType<HttpResponse<List<MangaModel>>>(
        Options(method: 'GET', headers: _headers, extra: _extra)
            .compose(
              _dio.options,
              'Manga/get-all-manga',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl),
      ),
    );
    final rawList = _extractMangaList(_result.data);
    List<MangaModel> value = rawList
        .whereType<Map<String, dynamic>>()
        .where((json) => json.containsKey('id') || json.containsKey('title'))
        .map<MangaModel>(
          (dynamic i) => MangaModel.fromJson(i as Map<String, dynamic>),
        )
        .toList();
    final httpResponse = HttpResponse(value, _result);
    return httpResponse;
  }

  List<dynamic> _extractMangaList(dynamic data) {
    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final directValues = data[r'$values'];
      if (directValues is List) {
        return directValues;
      }

      final manga = data['manga'];
      if (manga is List) {
        return manga;
      }

      if (manga is Map<String, dynamic>) {
        final mangaValues = manga[r'$values'];
        if (mangaValues is List) {
          return mangaValues;
        }
      }
    }

    return const <dynamic>[];
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }
}
