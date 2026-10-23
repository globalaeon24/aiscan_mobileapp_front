class ApiConfig {
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'stage',
  );

  static const String _baseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String stageBaseUrl =
      'https://api-mobile-stage.oysyn.asia/api/v1';
  static const String productionBaseUrl =
      'https://api-mobile.oysyn.asia/api/v1';

  static const String baseUrl = _baseUrlOverride != ''
      ? _baseUrlOverride
      : environment == 'production'
          ? productionBaseUrl
          : stageBaseUrl;

  static bool get isProduction => environment == 'production';
  static bool get isStage => environment == 'stage';
}
