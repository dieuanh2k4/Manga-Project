import '../../domain/entities/auth_session_entity.dart';
import '../../domain/entities/reader_profile_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote;
  final AuthLocalDataSource local;

  AuthRepositoryImpl({required this.remote, required this.local});

  @override
  Future<AuthSessionEntity> login(String userName, String password) async {
    final session = await remote.login(userName, password);
    await local.saveSession(session);
    return session.toEntity();
  }

  @override
  Future<void> register(RegisterPayload payload) {
    return remote.register(
      userName: payload.userName,
      password: payload.password,
      fullName: payload.fullName,
      email: payload.email,
      phone: payload.phone,
      birth: payload.birth,
      gender: payload.gender,
      address: payload.address,
    );
  }

  @override
  Future<ReaderProfileEntity> getMyProfile(String token) async {
    final profile = await remote.getMyProfile(token);
    return profile.toEntity();
  }

  @override
  Future<AuthSessionEntity?> restoreSession() async {
    final session = await local.getSession();
    return session?.toEntity();
  }

  @override
  Future<void> clearSession() {
    return local.clearSession();
  }
}
