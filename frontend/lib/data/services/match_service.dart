import 'dart:convert';
import 'package:http/http.dart' as http;

class MatchService {
  final String baseUrl = "http://10.0.2.2:8080/matches";

  Future<List<dynamic>> getMatches({
    required int userId,
    required int friendId,
  }) async {
    final response = await http.get(Uri.parse("$baseUrl/$userId/$friendId"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Erro ao buscar jogos em comum");
  }

  Future<List<dynamic>> getCompatibleGames({required int userId}) async {
    final response = await http.get(Uri.parse("$baseUrl/users/$userId/games"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Erro ao buscar jogos compativeis");
  }

  Future<List<dynamic>> getInterestedFriends({
    required int userId,
    required int gameId,
  }) async {
    final response = await http.get(
      Uri.parse("$baseUrl/users/$userId/games/$gameId/friends"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Erro ao buscar amigos interessados");
  }
}
