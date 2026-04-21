class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );

  static const bool useRemoteApi = bool.fromEnvironment(
    'USE_REMOTE_API',
    defaultValue: true,
  );
}
