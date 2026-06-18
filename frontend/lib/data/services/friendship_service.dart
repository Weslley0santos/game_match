import 'dart:convert';
import 'package:http/http.dart' as http;

class FriendshipService {
  final String baseUrl = "http://10.0.2.2:8080/friendships";

  Future<Map<String, dynamic>> sendRequest({
    required int userId,
    required int friendId,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl?userId=$userId&friendId=$friendId"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Erro ao enviar solicitacao");
  }

  Future<List<dynamic>> getAcceptedFriends(int userId) async {
    final response = await http.get(Uri.parse("$baseUrl/$userId"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Erro ao buscar amigos");
  }

  Future<List<dynamic>> getPendingRequests(int userId) async {
    final response = await http.get(Uri.parse("$baseUrl/$userId/pending"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Erro ao buscar solicitacoes pendentes");
  }

  Future<Map<String, dynamic>> acceptRequest(int friendshipId) async {
    final response = await http.put(Uri.parse("$baseUrl/$friendshipId/accept"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Erro ao aceitar solicitacao");
  }

  Future<Map<String, dynamic>> rejectRequest(int friendshipId) async {
    final response = await http.put(Uri.parse("$baseUrl/$friendshipId/reject"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Erro ao recusar solicitacao");
  }
}
