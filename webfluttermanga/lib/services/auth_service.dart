import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class AuthService {
  // Lấy token đang lưu
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<bool> isLoggedIn() async {
    return await getToken() != null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Đăng nhập
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'UserName': username,
          'Password': password,
        }),
      );

      final data = jsonDecode(response.body);

      // Nếu HTTP success
      if (response.statusCode == 200) {
        // Lưu token nếu Backend trả về field data token hoặc JWT
        // (API của bạn có thể trả về 'token' hay 'data')
        String? token;
        String? username;
        if (data.containsKey('token')) {
          token = data['token'];
          username = data['userName'];
        } else if (data['data'] != null && data['data']['token'] != null) {
          token = data['data']['token'];
          username = data['data']['userName']; // get username from data
        }

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          if (username != null) await prefs.setString('username', username);
        }
        
        return {'success': true, 'message': 'Đăng nhập thành công', 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Sai tên đăng nhập hoặc mật khẩu'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi mạng hoặc CORS: $e'};
    }
  }

  // Đăng ký
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String phone,
    String? birth,
    String? address,
    String? gender,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.register));

      // Append form fields (Gửi qua FromForm theo yêu cầu của backend)
      request.fields['FullName'] = fullName;
      request.fields['UserName'] = username;
      request.fields['Email'] = email;
      request.fields['Password'] = password;
      request.fields['Phone'] = phone;
      if (birth != null) request.fields['Birth'] = birth;
      if (address != null) request.fields['Address'] = address;
      if (gender != null) request.fields['Gender'] = gender;

      var response = await request.send();
      var responseString = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Đăng ký thành công'};
      } else {
        try {
          var errData = jsonDecode(responseString);
          return {'success': false, 'message': errData['message'] ?? 'Lỗi tạo tài khoản'};
        } catch (_) {
          return {'success': false, 'message': 'Lỗi tạo tài khoản. Mã lỗi: ${response.statusCode}'};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối Server: $e'};
    }
  }
}
