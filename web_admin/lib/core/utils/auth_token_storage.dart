import 'package:shared_preferences/shared_preferences.dart';

class AuthTokenStorage {
  static const List<String> _tokenKeys = <String>[
    'token',
    'accessToken',
    'access_token',
    'jwt',
    'jwtToken',
  ];

  final SharedPreferences _preferences;

  const AuthTokenStorage(this._preferences);

  Future<String?> getAccessToken() async {
    for (final String key in _tokenKeys) {
      final String? value = _preferences.getString(key)?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  Future<void> saveAccessToken(String token, {String key = 'token'}) async {
    final String normalized = token.trim();
    if (normalized.isEmpty) {
      return;
    }

    await _preferences.setString(key, normalized);
  }

  Future<void> clearTokens() async {
    for (final String key in _tokenKeys) {
      await _preferences.remove(key);
    }
  }

  String formatBearerValue(String token) {
    final String trimmed = token.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed;
    }
    return 'Bearer $trimmed';
  }
}
