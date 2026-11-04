/// API host can be overridden per build with `--dart-define=API_BASE_URL=...`.
abstract final class ApiConstants {
  static const String serverUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String apiPrefix = '/api/v1';

  static String get baseUrl => '${_trimTrailingSlash(serverUrl)}$apiPrefix';

  static String _trimTrailingSlash(String value) {
    var result = value;
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
