import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/game_model.dart';

class GameService {
  final String baseUrl = "http://10.0.2.2:8080/games";

  Future<List<GameModel>> fetchGames() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((game) => GameModel.fromJson(game)).toList();
    } else {
      throw Exception("Erro ao buscar games");
    }
  }
}
