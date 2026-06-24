import 'package:http/http.dart' as http;

import '../../core/config/api_config.dart';
import 'api_service_helper.dart';

class HistoryService {
  final String baseUrl = "${ApiConfig.baseUrl}/ratings";

  Future<List<dynamic>> getUserHistory(int userId) async {
    final response = await ApiServiceHelper.request(
      () => http.get(Uri.parse("$baseUrl/user/$userId")),
    );

    return ApiServiceHelper.decodeList(response);
  }
}
