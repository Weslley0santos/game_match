import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'api_service_helper.dart';

class UserService {
  final String baseUrl = "${ApiConfig.baseUrl}/users";

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiServiceHelper.request(
      () => http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      ),
    );

    return ApiServiceHelper.decodeMap(response);
  }

  Future<Map<String, dynamic>> createUser(
    String name,
    String email,
    String password,
  ) async {
    final response = await ApiServiceHelper.request(
      () => http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, "email": email, "password": password}),
      ),
    );

    return ApiServiceHelper.decodeMap(response);
  }

  Future<List<dynamic>> getUsers() async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse(baseUrl)),
    );

    return ApiServiceHelper.decodeList(response);
  }
}
