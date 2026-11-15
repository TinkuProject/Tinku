import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tinkuapp/services/auth_storage.dart';

import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import '../config/config.dart';
import '../core/session_manager.dart';
import 'api_http_client.dart';
import '../helpers/api_error_translations.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  String get userMessage {
    String raw = message;

    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        final details = decoded['details'];
        if (details is List && details.isNotEmpty) {
          final first = details.first;
          if (first is Map<String, dynamic>) {
            raw = '${first['field'] ?? ''}: ${first['message'] ?? ''}';
          } else {
            raw = first.toString();
          }
        } else {
          raw = (decoded['message'] ?? decoded['error'] ?? message).toString();
        }
      }
    } catch (_) {
      // Si no es JSON, usamos el mensaje original.
    }

    final normalized = raw.toLowerCase();
    final translated = translateDomainError(raw);
    if (translated != null) return translated;

    if (normalized.contains('password too short')) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (normalized.contains('must include uppercase')) {
      return 'La contraseña debe incluir al menos una letra mayúscula';
    }
    if (normalized.contains('must include number')) {
      return 'La contraseña debe incluir al menos un número';
    }
    if (normalized.contains('invalid email')) {
      return 'Ingresa un email válido';
    }
    if (normalized.contains('invalid username')) {
      return 'El usuario sólo puede incluir letras, números y guion bajo';
    }
    if (normalized.contains('email or username already in use')) {
      return 'Ese email o nombre de usuario ya está registrado';
    }
    if (normalized.contains('invalid credentials')) {
      return 'Credenciales inválidas';
    }
    if (normalized.contains('verification code expired')) {
      return 'El código venció. Solicitá uno nuevo';
    }
    if (normalized.contains('invalid verification code')) {
      return 'El código ingresado no es válido';
    }
    if (normalized.contains('email not verified')) {
      return 'Verifica tu correo para ingresar';
    }
    if (normalized.contains('email already verified')) {
      return 'Este correo ya está verificado';
    }
    if (normalized.contains('please wait before requesting another code')) {
      return 'Espera un momento antes de solicitar otro código';
    }
    if (normalized.contains('too many code requests')) {
      return 'Solicitaste demasiados códigos. Intenta nuevamente más tarde';
    }
    if (normalized.contains('too many verification attempts')) {
      return 'Superaste el límite de intentos. Solicita un código nuevo';
    }
    if (normalized.contains('email service is not configured')) {
      return 'El envío de correo no está disponible temporalmente';
    }
    if (normalized.contains('unauthorized')) return 'No autorizado';
    if (normalized.contains('forbidden')) return 'No tienes permisos';
    if (normalized.contains('not found')) return 'No se encontró el recurso';
    if (normalized.contains('already')) return 'La solicitud ya fue procesada';
    if (normalized.contains('duplicate')) return 'El registro ya existe';
    if (normalized.contains('balance')) return 'No tienes suficientes tinkus';
    if (normalized.contains('capacity')) return 'No hay cupos disponibles';
    if (normalized.contains('past')) {
      return 'La fecha y hora no puede estar en el pasado';
    }
    if (normalized.contains('30 minutos') ||
        normalized.contains('30 minutes')) {
      return 'El evento debe durar al menos 30 minutos';
    }
    if (normalized.contains('fecha de fin') ||
        normalized.contains('end_date')) {
      return 'La fecha de fin debe ser posterior al inicio';
    }

    if (statusCode >= 500) {
      return 'Ocurrió un problema en el servidor';
    }

    return raw.trim().isEmpty ? 'No se pudo completar la operación' : raw;
  }

  @override
  String toString() => userMessage;
}

class AuthService {
  final String baseUrl;
  final http.Client client;
  Future<String?>? _refreshInFlight;
  int _sessionRevision = 0;

  AuthService({
    this.baseUrl = Config.baseUrl,
    http.Client? client,
  }) : client = client ?? ApiHttpClient();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: Config.serverGoogleClientId,
  );

  // =========================
  // HEADERS
  // =========================
  Map<String, String> _jsonHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _handleError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw ApiException(response.statusCode, response.body);
  }

  Future<Map<String, String>> authHeaders() async {
    final token = await getValidAccessToken();
    return _jsonHeaders(token: token);
  }

  // =========================
  // LOGIN
  // =========================
  Future<AuthResponse> login({
    String? email,
    String? username,
    required String password,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        if (email != null) 'email': email,
        if (username != null) 'username': username,
        'password': password,
      }),
    );

    _handleError(response);

    final data = jsonDecode(response.body);
    final auth = AuthResponse.fromJson(data);

    await persistSession(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );

    return auth;
  }

  // =========================
  // LOGIN GOOGLE
  // =========================
  Future<AuthResponse> loginWithGoogle({
    bool forceAccountSelection = false,
  }) async {
    if (forceAccountSelection) {
      await _googleSignIn.signOut();
    }

    final googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw ApiException(400, 'Login con Google cancelado');
    }

    final googleAuth = await googleUser.authentication;

    if (googleAuth.idToken == null) {
      throw ApiException(400, 'No se pudo obtener idToken de Google');
    }

    final response = await client.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'id_token': googleAuth.idToken,
        'email': googleUser.email,
      }),
    );

    _handleError(response);

    final data = jsonDecode(response.body);
    final auth = AuthResponse.fromJson(data);

    await persistSession(
      accessToken: auth.accessToken,
      refreshToken: auth.refreshToken,
    );
    return auth;
  }

  // =========================
  // REGISTER
  // =========================
  Future<RegistrationResult> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final body = {
      'username': username,
      'email': email,
      'password': password,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
    };

    final response = await client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );

    _handleError(response);

    final data = jsonDecode(response.body);
    return RegistrationResult.fromJson(Map<String, dynamic>.from(data));
  }

  // =========================
  // LOGOUT
  // =========================
  Future<void> logout() async {
    final token = SessionManager.accessToken;
    final refreshToken = SessionManager.refreshToken;
    await clearLocalSession();

    if (token != null) {
      try {
        await client.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: _jsonHeaders(token: token),
          body: jsonEncode({
            if (refreshToken != null) 'refresh_token': refreshToken,
          }),
        );
      } catch (_) {
        // El logout local no depende de que el servidor esté disponible.
      }
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  // =========================
  // REFRESH TOKEN
  // =========================
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/refresh'),
      headers: _jsonHeaders(),
      body: jsonEncode({'refresh_token': refreshToken}),
    );

    _handleError(response);

    return jsonDecode(response.body);
  }

  // =========================
  // TOKEN MANAGER
  // =========================
  Future<String?> getValidAccessToken({bool forceRefresh = false}) async {
    final access = SessionManager.accessToken;

    if (access == null) return null;

    if (!forceRefresh && !_isTokenExpired(access)) return access;

    return _refreshAccessToken();
  }

  Future<String?> _refreshAccessToken() {
    final activeRefresh = _refreshInFlight;
    if (activeRefresh != null) return activeRefresh;

    late final Future<String?> operation;
    operation = _performTokenRefresh().whenComplete(() {
      if (identical(_refreshInFlight, operation)) {
        _refreshInFlight = null;
      }
    });
    _refreshInFlight = operation;
    return operation;
  }

  Future<String?> _performTokenRefresh() async {
    final refresh = SessionManager.refreshToken;
    final revision = _sessionRevision;

    if (refresh == null) {
      await clearLocalSession();
      return null;
    }

    try {
      final data = await refreshToken(refresh);
      final session = data['session'];

      if (session is! Map) {
        throw ApiException(500, 'Invalid refresh response');
      }

      final newAccess = session['access_token'];
      final newRefresh = session['refresh_token'] ?? refresh;

      if (newAccess is! String ||
          newAccess.isEmpty ||
          newRefresh is! String ||
          newRefresh.isEmpty) {
        throw ApiException(500, 'Invalid refresh response');
      }

      if (revision != _sessionRevision ||
          SessionManager.refreshToken != refresh) {
        return SessionManager.accessToken;
      }

      SessionManager.setSession(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      await AuthStorage.saveTokens(newAccess, newRefresh);

      return newAccess;
    } catch (e) {
      if (_isInvalidRefreshError(e) &&
          revision == _sessionRevision &&
          SessionManager.refreshToken == refresh) {
        await clearLocalSession();
        return null;
      }

      rethrow;
    }
  }

  Future<String?> _recoverFromUnauthorized(String rejectedToken) async {
    final currentToken = SessionManager.accessToken;

    if (currentToken != null &&
        currentToken != rejectedToken &&
        !_isTokenExpired(currentToken)) {
      return currentToken;
    }

    return getValidAccessToken(forceRefresh: true);
  }

  // =========================
  // CURRENT USER
  // =========================
  Future<UserModel?> getCurrentUser() async {
    final token = await getValidAccessToken();

    if (token == null) return null;

    final response = await client.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _jsonHeaders(token: token),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['profile']);
    }

    if (response.statusCode == 401) {
      final newToken = await _recoverFromUnauthorized(token);

      if (newToken == null) {
        return null;
      }

      // retry request
      final retry = await client.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _jsonHeaders(token: newToken),
      );

      if (retry.statusCode == 200) {
        final data = jsonDecode(retry.body);
        return UserModel.fromJson(data['profile']);
      }

      if (retry.statusCode == 401) {
        await clearLocalSession();
        return null;
      }

      throw ApiException(retry.statusCode, retry.body);
    }

    throw ApiException(response.statusCode, response.body);
  }

  // =========================
  // CHANGE PASSWORD
  // =========================
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getValidAccessToken();

    if (token == null) {
      throw ApiException(401, "Session expired");
    }

    final response = await client.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _jsonHeaders(token: token),
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    _handleError(response);
  }

  Future<Map<String, dynamic>> requestEmailVerificationCode({
    required String email,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/email/verification-code'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email}),
    );

    _handleError(response);
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/email/verify-code'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': email,
        'code': code,
      }),
    );

    _handleError(response);
  }

  Future<void> requestEmailChange(String email) async {
    final response = await client.post(
        Uri.parse('$baseUrl/auth/email/change-code'),
        headers: await authHeaders(),
        body: jsonEncode({'email': email}));
    _handleError(response);
  }

  Future<void> confirmEmailChange(String email, String code) async {
    final response = await client.post(Uri.parse('$baseUrl/auth/email/change'),
        headers: await authHeaders(),
        body: jsonEncode({'email': email, 'code': code}));
    _handleError(response);
  }

  Future<Map<String, dynamic>> requestPasswordRecoveryCode({
    required String email,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/password/recovery-code'),
      headers: _jsonHeaders(),
      body: jsonEncode({'email': email}),
    );

    _handleError(response);
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  Future<void> resetPasswordWithCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/password/reset-with-code'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': email,
        'code': code,
        'new_password': newPassword,
      }),
    );

    _handleError(response);
  }

  // =========================
  // TOKEN EXPIRATION
  // =========================
  Future<void> persistSession({
    required String accessToken,
    String? refreshToken,
  }) async {
    _sessionRevision++;
    SessionManager.setSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await AuthStorage.saveTokens(accessToken, refreshToken);
  }

  void restoreSession({
    required String accessToken,
    String? refreshToken,
  }) {
    _sessionRevision++;
    SessionManager.setSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Future<void> clearLocalSession() async {
    _sessionRevision++;
    SessionManager.clear();
    try {
      await AuthStorage.clear();
    } catch (_) {
      // La memoria se limpia aunque el almacenamiento seguro no responda.
    }
  }

  bool _isInvalidRefreshError(Object error) {
    return error is ApiException && error.statusCode == 401;
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = (payload['exp'] as num?)?.toInt();
      if (exp == null) return true;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now >= exp;
    } catch (_) {
      return true;
    }
  }
}
