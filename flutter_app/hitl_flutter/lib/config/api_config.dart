class ApiConfig {
  // Keep the ngrok endpoint as the normal phone/hotspot route. Local/offline
  // runs override it with:
  //   --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://sublabial-unpondered-tiffanie.ngrok-free.dev/api',
  );

  static String get serverUrl => baseUrl.replaceFirst(RegExp(r'/api$'), '');
}
