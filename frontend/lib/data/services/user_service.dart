import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'api_service_helper.dart';

class UsernameUnavailableException implements Exception {}

class UserService {
  final String baseUrl = "${ApiConfig.baseUrl}/users";

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await ApiServiceHelper.request(
      () => http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username.trim(), "password": password}),
      ),
    );

    return ApiServiceHelper.decodeMap(response);
  }

  Future<Map<String, dynamic>> createUser(
    String username,
    String password,
  ) async {
    final response = await ApiServiceHelper.request(
      () => http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username.trim(), "password": password}),
      ),
    );

    if (response.statusCode == 409) throw UsernameUnavailableException();
    return ApiServiceHelper.decodeMap(response);
  }

  Future<List<dynamic>> getUsers() async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse(baseUrl), headers: ApiServiceHelper.authHeaders),
    );

    return ApiServiceHelper.decodeList(response);
  }
}
