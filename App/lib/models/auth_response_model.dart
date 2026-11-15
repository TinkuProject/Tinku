import 'user_model.dart';

class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final UserModel profile;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.profile,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final session = json['session'];

    return AuthResponse(
      accessToken: session['access_token'],
      refreshToken: session['refresh_token'],
      profile: UserModel.fromJson(json['profile']),
    );
  }
}

class RegistrationResult {
  final String email;
  final bool requiresEmailVerification;
  final bool deliverySent;

  const RegistrationResult({
    required this.email,
    required this.requiresEmailVerification,
    required this.deliverySent,
  });

  factory RegistrationResult.fromJson(Map<String, dynamic> json) {
    return RegistrationResult(
      email: json['email']?.toString() ?? '',
      requiresEmailVerification: json['requires_email_verification'] == true,
      deliverySent: json['delivery_sent'] == true,
    );
  }
}
