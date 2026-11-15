class SessionManager {
  static String? _accessToken;
  static String? _refreshToken;

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;

  static void setSession({
    required String accessToken,
    String? refreshToken,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  static void clear() {
    _accessToken = null;
    _refreshToken = null;
  }

  static bool get isAuthenticated =>
      _accessToken != null && _accessToken!.isNotEmpty;
}