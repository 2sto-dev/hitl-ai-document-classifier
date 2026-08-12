class ApiConfig {
  static const String baseUrl =
      'https://sublabial-unpondered-tiffanie.ngrok-free.dev/api';

  static String get serverUrl => baseUrl.replaceFirst(RegExp(r'/api$'), '');
}
