class AppConfig {
  const AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.200:5001/api',
    // defaultValue: 'https://c0f0-118-71-135-136.ngrok-free.app/api',
    // defaultValue: 'http://10.76.200.178:5001/api',
    // defaultValue: 'http://192.168.0.114:5001/api',
  );

  static String get apiOrigin {
    final uri = Uri.parse(apiBaseUrl);
    final portPart = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$portPart';
  }
}
