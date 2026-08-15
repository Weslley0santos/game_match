import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl => kIsWeb
      ? "http://localhost:8080"
      : "http://10.0.2.2:8080";
}
