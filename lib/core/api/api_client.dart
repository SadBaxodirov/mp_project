import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage.dart';
import 'auth_tokens.dart';

class ApiClient {
  final String baseUrl;

  ApiClient(this.baseUrl);

  Future<http.Response> get(String endpoint) {
    return _sendRequest((token) {
      final uri = Uri.parse(baseUrl + endpoint);

      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      return http.get(uri, headers: headers);
    });
  }

  Future<http.Response> post(String endpoint, Map body) {
    return _sendRequest((token) {
      final uri = Uri.parse(baseUrl + endpoint);

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      return http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
    });
  }

  Future<http.Response> _sendRequest(
      Future<http.Response> Function(String? token) request) async {
    String? token = await TokenStorage.getAccess();

    http.Response response = await request(token);

    if (response.statusCode == 401) {
      final refreshed = await refreshToken();
      if (!refreshed) {
        await TokenStorage.clear();
        throw Exception("Unauthorized — login again.");
      }

      // retry
      final newToken = await TokenStorage.getAccess();
      return request(newToken);
    }

    return response;
  }

}
