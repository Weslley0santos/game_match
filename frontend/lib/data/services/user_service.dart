import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  final String baseUrl = "http://10.0.2.2:8080/users";

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception("Login inválido");
    }
  }

  Future<Map<String, dynamic>> createUser(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "email": email, "password": password}),
    );

    return jsonDecode(response.body);
  }

  Future<List<dynamic>> getUsers() async {
    final response = await http.get(Uri.parse(baseUrl));

    return jsonDecode(response.body);
  }
}
