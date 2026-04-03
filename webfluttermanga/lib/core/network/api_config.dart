class ApiConfig {
  // Thay đổi URL này tùy theo môi trường. URL backend mặc định của bạn là cổng 5219
  static const String baseUrl = 'http://localhost:5219/api';

  // Auth Endpoints
  static const String login = '$baseUrl/Auth/login';
  static const String register = '$baseUrl/Auth/reader-register'; // Sửa thành endpoint đúng của backend

  // Manga Endpoints
  static const String getAllManga = '$baseUrl/Manga/get-all-manga';
  static String getMangaById(int id) => '$baseUrl/Manga/get-manga-by-id/$id';
  static const String searchManga = '$baseUrl/Manga/search';

  // Thêm các endpoint khác sau này...
}
