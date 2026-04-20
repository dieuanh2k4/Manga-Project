import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_session_model.dart';

class AuthLocalDataSource {
  static const _sessionKey = 'auth_session';

  Future<void> saveSession(AuthSessionModel model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(model.toStorage()));
  }

  Future<AuthSessionModel?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
    final model = AuthSessionModel.fromStorage(jsonMap);
    if (model.token.isEmpty) {
      return null;
    }

    return model;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
