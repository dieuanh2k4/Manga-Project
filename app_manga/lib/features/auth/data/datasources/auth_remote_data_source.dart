import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../models/auth_session_model.dart';
import '../models/reader_profile_model.dart';

class AuthRemoteDataSource {
  Map<String, dynamic>? _tryDecodeJson(String body) {
    if (body.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<AuthSessionModel> login(String userName, String password) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userName': userName, 'password': password}),
    );

    final jsonMap = _tryDecodeJson(response.body);
    if (jsonMap == null) {
      throw Exception(
        'Server tra ve du lieu khong hop le (${response.statusCode}).',
      );
    }

    if (response.statusCode != 200) {
      final message = (jsonMap['message'] ?? 'Đăng nhập thất bại').toString();
      throw Exception(message);
    }

    return AuthSessionModel.fromLoginResponse(jsonMap);
  }

  Future<void> register({
    required String userName,
    required String password,
    required String fullName,
    required String email,
    required String phone,
    required String birth,
    required String gender,
    required String address,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.apiBaseUrl}/Auth/reader-register'),
    );

    request.fields['UserName'] = userName;
    request.fields['Password'] = password;
    request.fields['FullName'] = fullName;
    request.fields['Email'] = email;
    request.fields['Phone'] = phone;
    request.fields['Birth'] = birth;
    request.fields['Gender'] = gender;
    request.fields['Address'] = address;

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();
    final jsonMap = _tryDecodeJson(responseBody);
    if (jsonMap == null) {
      throw Exception(
        'Server tra ve du lieu khong hop le (${streamed.statusCode}).',
      );
    }

    if (streamed.statusCode != 200) {
      final message = (jsonMap['message'] ?? 'Đăng ký thất bại').toString();
      throw Exception(message);
    }
  }

  Future<ReaderProfileModel> getMyProfile(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/Reader/get-info-account'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final jsonMap = _tryDecodeJson(response.body);
    if (jsonMap == null) {
      throw Exception(
        'Server tra ve du lieu khong hop le (${response.statusCode}).',
      );
    }

    if (response.statusCode != 200) {
      final message = (jsonMap['message'] ?? 'Không tải được thông tin user')
          .toString();
      throw Exception(message);
    }

    return ReaderProfileModel.fromJson(jsonMap);
  }
}
