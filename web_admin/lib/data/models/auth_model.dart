import 'package:web_admin/domain/entities/auth.dart';

class AuthModel {
  final String userName;
  final String role;
  final String token;

  const AuthModel({
    required this.userName,
    required this.role,
    required this.token,
  });

  factory AuthModel.fromLoginResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Đăng nhập thất bại: thiếu data');
    }

    final isSuccess = json['isSuccess'] == true;
    if (!isSuccess) {
      final message = (json['message'] ?? 'Đăng nhập thất bại').toString();
      throw Exception(message);
    }

    return AuthModel(
      userName: (data['userName'] ?? '').toString(),
      role: (data['role'] ?? '').toString(),
      token: (data['token'] ?? '').toString(),
    );
  }

  factory AuthModel.fromStorage(Map<String, dynamic> json) {
    return AuthModel(
      userName: (json['userName'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toStorage() {
    return {'userName': userName, 'role': role, 'token': token};
  }

  AuthEntity toEntity() {
    return AuthEntity(userName: userName, role: role, token: token);
  }
}
