class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.8.159:5001/api',
    // defaultValue: 'http://10.76.200.178:5001/api',
  );

  static String get apiOrigin {
    final uri = Uri.parse(apiBaseUrl);
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portPart';
  }
}
