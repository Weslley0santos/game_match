import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'api_service_helper.dart';

class FriendshipService {
  final String baseUrl = "${ApiConfig.baseUrl}/friendships";

  Future<Map<String, dynamic>> sendRequest({
    required int userId,
    required int friendId,
  }) async {
    final response = await ApiServiceHelper.request(
      () => http.post(Uri.parse("$baseUrl?userId=$userId&friendId=$friendId")),
    );

    return ApiServiceHelper.decodeMap(response);
  }

  Future<List<dynamic>> getAcceptedFriends(int userId) async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse("$baseUrl/$userId")),
    );

    return ApiServiceHelper.decodeList(response);
  }

  Future<List<dynamic>> getPendingRequests(int userId) async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse("$baseUrl/$userId/pending")),
    );

    return ApiServiceHelper.decodeList(response);
  }

  Future<Map<String, dynamic>> acceptRequest(int friendshipId) async {
    final response = await ApiServiceHelper.request(
      () => http.put(Uri.parse("$baseUrl/$friendshipId/accept")),
    );

    return ApiServiceHelper.decodeMap(response);
  }

  Future<Map<String, dynamic>> rejectRequest(int friendshipId) async {
    final response = await ApiServiceHelper.request(
      () => http.put(Uri.parse("$baseUrl/$friendshipId/reject")),
    );

    return ApiServiceHelper.decodeMap(response);
  }
}
