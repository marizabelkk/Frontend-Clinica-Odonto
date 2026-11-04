/// In-memory JWT holder shared by the auth flow and Dio token interceptor.
class AuthTokenStore {
  String? _accessToken;

  String? get accessToken => _accessToken;

  void save(String accessToken) => _accessToken = accessToken;

  void clear() => _accessToken = null;
}
