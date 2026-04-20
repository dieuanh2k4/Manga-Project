import '../../domain/entities/auth_session_entity.dart';

class AuthSessionModel {
  final String userName;
  final String role;
  final String token;

  const AuthSessionModel({
    required this.userName,
    required this.role,
    required this.token,
  });

  factory AuthSessionModel.fromLoginResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Dang nhap that bai: thieu data');
    }

    final isSuccess = json['isSuccess'] == true;
    if (!isSuccess) {
      final message = (json['message'] ?? 'Dang nhap that bai').toString();
      throw Exception(message);
    }

    return AuthSessionModel(
      userName: (data['userName'] ?? '').toString(),
      role: (data['role'] ?? '').toString(),
      token: (data['token'] ?? '').toString(),
    );
  }

  factory AuthSessionModel.fromStorage(Map<String, dynamic> json) {
    return AuthSessionModel(
      userName: (json['userName'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      token: (json['token'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toStorage() {
    return {
      'userName': userName,
      'role': role,
      'token': token,
    };
  }

  AuthSessionEntity toEntity() {
    return AuthSessionEntity(userName: userName, role: role, token: token);
  }
}
