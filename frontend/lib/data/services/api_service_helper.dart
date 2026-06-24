import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiServiceHelper {
  static const Duration timeoutDuration = Duration(seconds: 10);

  static Future<http.Response> request(
    Future<http.Response> Function() action,
  ) async {
    try {
      return await action().timeout(timeoutDuration);
    } on TimeoutException {
      throw Exception("Tempo de conexão esgotado. Verifique sua conexão.");
    } catch (e) {
      throw Exception("Não foi possível conectar ao servidor.");
    }
  }

  static List<dynamic> decodeList(http.Response response) {
    final decoded = _decodeSuccessResponse(response);

    if (decoded == null) {
      return [];
    }

    if (decoded is List) {
      return decoded;
    }

    throw Exception("Resposta inválida do servidor.");
  }

  static Map<String, dynamic> decodeMap(http.Response response) {
    final decoded = _decodeSuccessResponse(response);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception("Resposta inválida do servidor.");
  }

  static void ensureSuccess(http.Response response) {
    if (_isSuccess(response.statusCode)) {
      return;
    }

    throw Exception(_messageForStatus(response.statusCode));
  }

  static dynamic _decodeSuccessResponse(http.Response response) {
    if (!_isSuccess(response.statusCode)) {
      throw Exception(_messageForStatus(response.statusCode));
    }

    if (response.body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception("Resposta inválida do servidor.");
    }
  }

  static bool _isSuccess(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }

  static String _messageForStatus(int statusCode) {
    switch (statusCode) {
      case 400:
        return "Dados inválidos. Verifique as informações enviadas.";
      case 404:
        return "Registro não encontrado.";
      case 409:
        return "Essa operação já existe ou entra em conflito com os dados atuais.";
      case 500:
        return "Erro interno do servidor. Tente novamente mais tarde.";
      default:
        return "Não foi possível concluir a operação.";
    }
  }
}
