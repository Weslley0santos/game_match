import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'api_service_helper.dart';

class MatchService {
  final String baseUrl = "${ApiConfig.baseUrl}/matches";

  Future<List<dynamic>> getMatches({
    required int userId,
    required int friendId,
  }) async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse("$baseUrl/$userId/$friendId")),
    );

    return ApiServiceHelper.decodeList(response);
  }

  Future<List<dynamic>> getCompatibleGames({required int userId}) async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse("$baseUrl/users/$userId/games")),
    );

    return ApiServiceHelper.decodeList(response);
  }

  Future<List<dynamic>> getInterestedFriends({
    required int userId,
    required int gameId,
  }) async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse("$baseUrl/users/$userId/games/$gameId/friends")),
    );

    return ApiServiceHelper.decodeList(response);
  }
}
