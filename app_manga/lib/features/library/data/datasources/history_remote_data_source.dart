import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../models/history_item_model.dart';

class HistoryRemoteDataSource {
  Future<List<HistoryItemModel>> getHistory(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/History/get-history'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'API get-history failed: ${response.statusCode} ${response.body}',
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
        data = [rawData];
      } else {
        data = [];
      }
    } else {
      data = [];
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(HistoryItemModel.fromJson)
        .where((item) => item.mangaId > 0 && item.title.isNotEmpty)
        .toList();
  }
}
