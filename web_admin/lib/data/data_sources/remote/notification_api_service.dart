import 'package:dio/dio.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/core/utils/auth_token_storage.dart';
import 'package:web_admin/data/models/notification_model.dart';

class NotificationApiService {
  final Dio _dio;
  final AuthTokenStorage _authTokenStorage;

  NotificationApiService(this._dio, this._authTokenStorage);

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

  Future<Map<String, dynamic>> _buildAuthHeaders() async {
    final String? token = await _authTokenStorage.getAccessToken();
    if (token == null || token.trim().isEmpty) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{
      'Authorization': _authTokenStorage.formatBearerValue(token),
    };
  }

  Future<List<NotificationModel>> getAllNotification() async {
    final Map<String, dynamic> headers = await _buildAuthHeaders();

    final response = await _dio.get<dynamic>(
      '${newAPIBaseURL}FcmNotification/get-all-notification',
      options: Options(headers: headers),
    );

    final rawList = _extractList(response.data);

    return rawList
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(NotificationModel.fromJson)
        .toList();
  }

  Future<Response<dynamic>> createNotification(
    NotificationModel notification,
  ) async {
    final Map<String, dynamic> headers = await _buildAuthHeaders();

    return _dio.post<dynamic>(
      '${newAPIBaseURL}FcmNotification/create-notification',
      data: <String, dynamic>{
        'title': notification.title,
        'content': notification.content,
        'targetRole': notification.targetRole,
        'mangaId': notification.mangaId ?? 0,
      },
      options: Options(headers: headers),
    );
  }
}
