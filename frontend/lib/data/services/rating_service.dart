import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'api_service_helper.dart';

class RatingService {
  final String baseUrl = "${ApiConfig.baseUrl}/ratings";

  Future<void> sendRating({
    required int gameId,
    required String type,
  }) async {
    final response = await ApiServiceHelper.request(
      () => http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json", ...ApiServiceHelper.authHeaders},
        body: jsonEncode({"gameId": gameId, "type": type}),
      ),
    );

    ApiServiceHelper.ensureSuccess(response);
  }

  Future<List<dynamic>> getUserRatings(int userId) async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse("$baseUrl/user/$userId"), headers: ApiServiceHelper.authHeaders),
    );

    return ApiServiceHelper.decodeList(response);
  }
}
