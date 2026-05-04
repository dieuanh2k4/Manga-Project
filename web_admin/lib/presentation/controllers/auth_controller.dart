import 'package:flutter/foundation.dart';
import 'package:web_admin/core/resources/data_state.dart';
import 'package:web_admin/core/utils/auth_token_storage.dart';
import 'package:web_admin/domain/entities/auth.dart';
import 'package:web_admin/domain/usecases/login.dart';

// mô tả trạng thái hoạt động của auth
enum AuthStatus {
  initial, // trạng thái ban đầu
  loading, // đang đăng nhập
  authenticated, // đăng nhập thành công
  unauthenticated, // chưa đăng nhập hoặc logout
  failure, // đăng nhập thất bại
}

class AuthController extends ChangeNotifier {
  final Login _login;
  final AuthTokenStorage
  _tokenStorage; // lưu hoặc xóa token sau khi đăng nhập/logout

  AuthController(this._login, this._tokenStorage);

  AuthStatus _status = AuthStatus.unauthenticated; // trạng thái hiện tại
  AuthEntity? _auth; // thông tin user
  String? _errorMessage; // lỗi UI hiển thị

  // các getter giúp UI đọc state
  AuthStatus get status => _status;
  AuthEntity? get auth => _auth;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Future<void> initialize() async {
  //   final String? token = await _tokenStorage.getAccessToken();

  //   if (token != null && token.trim().isNotEmpty) {
  //     _auth = AuthEntity(userName: 'Admin', role: 'Admin', token: token);
  //     _status = AuthStatus.authenticated;
  //   } else {
  //     _auth = null;
  //     _status = AuthStatus.unauthenticated;
  //   }

  //   notifyListeners();
  // }

  Future<bool> login({
    required String userName,
    required String password,
  }) async {
    final String normalizedUserName = userName.trim();
    final String normalizedPassword = password.trim();

    if (normalizedUserName.isEmpty || normalizedPassword.isEmpty) {
      _setFailure('Vui long nhap ten dang nhap va mat khau.');
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final DataState<AuthEntity> result = await _login(
        normalizedUserName,
        normalizedPassword,
      );

      if (result is DataSuccess<AuthEntity> && result.data != null) {
        final AuthEntity auth = result.data!;
        await _tokenStorage.saveAccessToken(auth.token);
        _auth = auth;
        _status = AuthStatus.authenticated;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      _setFailure(_messageFromDataState(result));
      return false;
    } catch (error) {
      _setFailure(error.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<void> logout() async {
    await _tokenStorage.clearTokens();
    _auth = null;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    if (_status == AuthStatus.failure) {
      _status = _auth == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
    }
    notifyListeners();
  }

  void _setFailure(String message) {
    _auth = null;
    _status = AuthStatus.failure;
    _errorMessage = message;
    notifyListeners();
  }

  String _messageFromDataState(DataState<AuthEntity> state) {
    final dynamic responseData = state.error?.response?.data;
    if (responseData is Map<String, dynamic>) {
      final dynamic message = responseData['message'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }

    final String? dioMessage = state.error?.message;
    if (dioMessage != null && dioMessage.trim().isNotEmpty) {
      return dioMessage;
    }

    return 'Dang nhap that bai.';
  }
}
