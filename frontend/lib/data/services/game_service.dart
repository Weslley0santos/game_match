import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import '../models/game_model.dart';
import 'api_service_helper.dart';

class GameService {
  final String baseUrl = "${ApiConfig.baseUrl}/games";

  Future<List<GameModel>> fetchGames() async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse(baseUrl)),
    );
    final data = ApiServiceHelper.decodeList(response);

    return data
        .whereType<Map>()
        .map((game) => GameModel.fromJson(Map<String, dynamic>.from(game)))
        .toList();
  }
}
