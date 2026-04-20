import '../entities/auth_session_entity.dart';
import '../entities/reader_profile_entity.dart';

class RegisterPayload {
  final String userName;
  final String password;
  final String fullName;
  final String email;
  final String phone;
  final String birth;
  final String gender;
  final String address;

  const RegisterPayload({
    required this.userName,
    required this.password,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.birth,
    required this.gender,
    required this.address,
  });
}

abstract class AuthRepository {
  Future<AuthSessionEntity> login(String userName, String password);
  Future<void> register(RegisterPayload payload);
  Future<ReaderProfileEntity> getMyProfile(String token);
  Future<AuthSessionEntity?> restoreSession();
  Future<void> clearSession();
}
