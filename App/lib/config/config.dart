class Config {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3003',
  );

  static const String serverGoogleClientId = String.fromEnvironment(
    'SERVER_GOOGLE_CLIENT_ID',
    defaultValue: '',
  );
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
}
