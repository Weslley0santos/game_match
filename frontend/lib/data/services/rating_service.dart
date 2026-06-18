import 'dart:convert';
import 'package:http/http.dart' as http;

class RatingService {
  final String baseUrl = "http://10.0.2.2:8080/ratings";

  Future<void> sendRating({
    required int userId,
    required int gameId,
    required String type,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "gameId": gameId, "type": type}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception("Erro ao salvar avaliacao");
    }
  }

  Future<List<dynamic>> getUserRatings(int userId) async {
    final response = await http.get(Uri.parse("$baseUrl/user/$userId"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Erro ao buscar avaliacoes");
  }
}
