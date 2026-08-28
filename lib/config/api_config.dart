class ApiConfig {
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-mobile.oysyn.asia/api/v1',
  );

  static bool get isProduction => environment == 'production';
  static bool get isStage => environment == 'stage';
}
