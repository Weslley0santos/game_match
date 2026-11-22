import 'package:flutter/foundation.dart';

class ApiConfig {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isEmpty) {
      return kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
    }
    return _configuredBaseUrl.replaceFirst(RegExp(r'/+$'), '');
  }
}
