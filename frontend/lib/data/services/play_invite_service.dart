import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'api_service_helper.dart';

class PlayInviteService {
  final String baseUrl = "${ApiConfig.baseUrl}/play-invites";

  Future<Map<String, dynamic>> sendInvite({
    required int receiverId,
    required int gameId,
  }) async {
    final response = await ApiServiceHelper.request(
      () => http.post(
        Uri.parse(
          "$baseUrl?receiverId=$receiverId&gameId=$gameId",
        ),
        headers: ApiServiceHelper.authHeaders,
      ),
    );

    return ApiServiceHelper.decodeMap(response);
  }

  Future<List<dynamic>> getReceivedInvites(int userId) async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse("$baseUrl/$userId/received"), headers: ApiServiceHelper.authHeaders),
    );

    return ApiServiceHelper.decodeList(response);
  }

  Future<List<dynamic>> getSentInvites(int userId) async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse("$baseUrl/$userId/sent"), headers: ApiServiceHelper.authHeaders),
    );

    return ApiServiceHelper.decodeList(response);
  }

  Future<Map<String, dynamic>> acceptInvite(int inviteId) async {
    final response = await ApiServiceHelper.request(
      () => http.put(Uri.parse("$baseUrl/$inviteId/accept"), headers: ApiServiceHelper.authHeaders),
    );

    return ApiServiceHelper.decodeMap(response);
  }

  Future<Map<String, dynamic>> rejectInvite(int inviteId) async {
    final response = await ApiServiceHelper.request(
      () => http.put(Uri.parse("$baseUrl/$inviteId/reject"), headers: ApiServiceHelper.authHeaders),
    );

    return ApiServiceHelper.decodeMap(response);
  }
}
