import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:web_admin/core/constants/constants.dart';
import 'package:web_admin/data/models/auth_model.dart';

class AuthLoginApiService {
  final Dio _dio;

  AuthLoginApiService(this._dio);

  Future<AuthModel> login(String userName, String password) async {
    try {
      final response = await _dio.post(
        '${newAPIBaseURL}Auth/login',
        data: {"userName": userName, "password": password},
      );

      final jsonMap = response.data as Map<String, dynamic>? ?? {};

      return AuthModel.fromLoginResponse(jsonMap);
    } on DioError catch (e) {
      if (e.response != null) {
        final errorData = e.response?.data;
        String message = 'Đăng nhập thất bại';

        if (errorData is Map<String, dynamic> && errorData['message'] != null) {
          message = errorData['message'].toString();
        }

        throw Exception(message);
      } else {
        throw Exception('Lỗi kết nối: ${e.message}');
      }
    } catch (e) {
      throw Exception('Lỗi hệ thống: $e');
    }
  }
}
