import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_session_entity.dart';
import '../../domain/entities/reader_profile_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_my_profile_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/restore_session_usecase.dart';

class AuthController extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GetMyProfileUseCase getMyProfileUseCase;
  final RestoreSessionUseCase restoreSessionUseCase;
  final LogoutUseCase logoutUseCase;

  AuthController({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.getMyProfileUseCase,
    required this.restoreSessionUseCase,
    required this.logoutUseCase,
  });

  bool isBootstrapping = true;
  bool isBusy = false;
  String? errorMessage;

  AuthSessionEntity? session;
  ReaderProfileEntity? profile;

  bool get isAuthenticated => session != null;

  Future<void> bootstrap() async {
    if (!isBootstrapping) {
      return;
    }

    try {
      session = await restoreSessionUseCase();
      if (session != null) {
        await _loadProfile();
      }
    } catch (_) {
      await logoutUseCase();
      session = null;
      profile = null;
    } finally {
      isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<bool> login(String userName, String password) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      session = await loginUseCase(userName, password);
      await _loadProfile();
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<bool> register(RegisterPayload payload) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      await registerUseCase(payload);
      return true;
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    if (session == null) {
      return;
    }

    isBusy = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _loadProfile();
    } catch (e) {
      errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await logoutUseCase();
    session = null;
    profile = null;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    if (session == null) {
      return;
    }

    profile = await getMyProfileUseCase(session!.token);
  }
}
