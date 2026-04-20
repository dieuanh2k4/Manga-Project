import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../models/auth_session_model.dart';
import '../models/reader_profile_model.dart';

class AuthRemoteDataSource {
  Future<AuthSessionModel> login(String userName, String password) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/Auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userName': userName, 'password': password}),
    );

    final body = response.body.isEmpty ? '{}' : response.body;
    final jsonMap = jsonDecode(body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final message = (jsonMap['message'] ?? 'Dang nhap that bai').toString();
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
    final body = responseBody.isEmpty ? '{}' : responseBody;
    final jsonMap = jsonDecode(body) as Map<String, dynamic>;

    if (streamed.statusCode != 200) {
      final message = (jsonMap['message'] ?? 'Dang ky that bai').toString();
      throw Exception(message);
    }
  }

  Future<ReaderProfileModel> getMyProfile(String token) async {
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/Reader/get-info-account'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final body = response.body.isEmpty ? '{}' : response.body;
    final jsonMap = jsonDecode(body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      final message = (jsonMap['message'] ?? 'Khong tai duoc thong tin user').toString();
      throw Exception(message);
    }

    return ReaderProfileModel.fromJson(jsonMap);
  }
}
