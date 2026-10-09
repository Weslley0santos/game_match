import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'api_service_helper.dart';

class FriendshipService {
  final String baseUrl = "${ApiConfig.baseUrl}/friendships";

  Future<Map<String, dynamic>> sendRequest({
    required int friendId,
  }) async {
    final response = await ApiServiceHelper.request(
      () => http.post(Uri.parse("$baseUrl?friendId=$friendId"), headers: ApiServiceHelper.authHeaders),
    );

    return ApiServiceHelper.decodeMap(response);
  }

  Future<List<dynamic>> getAcceptedFriends(int userId) async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse("$baseUrl/$userId"), headers: ApiServiceHelper.authHeaders),
    );

    return ApiServiceHelper.decodeList(response);
  }

  Future<List<dynamic>> getPendingRequests(int userId) async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse("$baseUrl/$userId/pending"), headers: ApiServiceHelper.authHeaders),
    );

    return ApiServiceHelper.decodeList(response);
  }

  Future<Map<String, dynamic>> acceptRequest(int friendshipId) async {
    final response = await ApiServiceHelper.request(
      () => http.put(Uri.parse("$baseUrl/$friendshipId/accept"), headers: ApiServiceHelper.authHeaders),
    );

    return ApiServiceHelper.decodeMap(response);
  }

  Future<Map<String, dynamic>> rejectRequest(int friendshipId) async {
    final response = await ApiServiceHelper.request(
      () => http.put(Uri.parse("$baseUrl/$friendshipId/reject"), headers: ApiServiceHelper.authHeaders),
    );

    return ApiServiceHelper.decodeMap(response);
  }
}
