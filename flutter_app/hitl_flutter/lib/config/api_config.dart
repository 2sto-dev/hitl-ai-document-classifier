class ApiConfig {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    return '${Uri.base.origin}/api';
  }

  static String get serverUrl =>
      baseUrl.replaceFirst(RegExp(r'/api$'), '');
}