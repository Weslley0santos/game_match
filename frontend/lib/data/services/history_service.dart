import 'dart:convert';
import 'package:http/http.dart' as http;

class HistoryService {
  final String baseUrl = "http://10.0.2.2:8080/ratings";

  Future<List<dynamic>> getUserHistory(int userId) async {
    final response = await http.get(Uri.parse("$baseUrl/user/$userId"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erro ao buscar histórico");
    }
  }
}
