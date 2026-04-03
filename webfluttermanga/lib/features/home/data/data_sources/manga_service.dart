import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/manga_mock.dart'; // Tạm mượn cấu trúc Manga của bạn
import '../../../../core/network/api_config.dart';

class MangaService {
  // Lấy toàn bộ truyện tranh từ Backend
  Future<List<Manga>> fetchAllManga() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.getAllManga));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // ASP.NET JSON Options "ReferenceHandler.Preserve" thường ném về list ở bên trong key "$values"
        // Kiểm tra xem format json trả về có bọc object không
        List<dynamic> jsonList;
        if (data.containsKey('\$values')) {
          jsonList = data['\$values'];
        } else {
          jsonList = jsonDecode(response.body);
        }

        return jsonList.map((json) => Manga(
          id: json['id'] ?? 0,
          title: json['title'] ?? 'Unknown',
          // Backend có thể không trả thẳng 'authorName', chờ bạn map logic
          authorName: 'Update...', 
          thumbnail: json['thumbnail'] ?? 'https://via.placeholder.com/150',
          latestChapter: json['totalChapter'] != null ? '#${json['totalChapter']}' : '#?',
          views: json['rate'] ?? 0, 
        )).toList();
      } else {
        throw Exception('Failed to load manga');
      }
    } catch (e) {
      throw Exception('Error fetching manga: $e');
    }
  }
}
