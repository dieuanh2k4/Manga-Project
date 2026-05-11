import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotificationByReaderId(String token) async {
    final response = await http.get(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/FcmNotification/get-notification-by-readerid',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    final decoded = response.body.isEmpty ? null : json.decode(response.body);

    if (response.statusCode != 200) {
      String message = 'API get-notification-by-readerid failed: ${response.statusCode}';
      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        message = decoded['message'].toString();
      }
      throw Exception(message);
    }

    final data = _extractJsonList(decoded);

    return data
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();
  }

  List<dynamic> _extractJsonList(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final rawData = decoded['data'] ?? decoded['Data'];

      if (rawData is List) {
        return rawData;
      }

      if (rawData is Map<String, dynamic>) {
        final values = rawData[r'$values'];
        if (values is List) {
          return values;
        }
      }

      final values = decoded[r'$values'];
      if (values is List) {
        return values;
      }
    }

    return <dynamic>[];
  }

  Future<int> countUnreadNotification(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/FcmNotification/count-unread-notification'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final decoded = response.body.isEmpty ? null : json.decode(response.body);

    if (response.statusCode != 200) {
      throw Exception('API count-unread-notification failed: ${response.statusCode}');
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is int) {
        return data;
      }
      return int.tryParse(data?.toString() ?? '') ?? 0;
    }

    return 0;
  }

  Future<void> markNotificationAsRead(int notificationId, String token) async {
    final response = await http.post(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/FcmNotification/mark-notification-as-read/$notificationId',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('API mark-notification-as-read failed: ${response.statusCode}');
    }
  }

  Future<void> markAllUnreadNotifications(String token) async {
    final response = await http.post(
      Uri.parse(
        '${AppConfig.apiBaseUrl}/FcmNotification/mark-all-unread-notification',
      ),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('API mark-all-unread-notification failed: ${response.statusCode}');
    }
  }
}
