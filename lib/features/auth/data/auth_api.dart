import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import 'models/auth_tokens.dart';
import 'models/user.dart';

class AuthApi {
  AuthApi({http.Client? client})
      : _client = client ?? http.Client(),
        _apiClient = ApiClient(apiBaseUrl);

  final http.Client _client;
  final ApiClient _apiClient;

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/token/'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'username': email,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_errorFromResponse(response.body, fallback: 'Login failed'));
    }

    final Map<String, dynamic> data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return AuthTokens.fromJson(data);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('$apiBaseUrl/users/'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'full_name': fullName,
        'email': email,
        'username': email,
        'password': password,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        _errorFromResponse(
          response.body,
          fallback: 'Registration failed',
        ),
      );
    }
  }

  Future<User> getCurrentUser() async {
    final candidates = <String>[
      '/users/me/',
      '/users/me',
      '/auth/user/',
    ];

    for (final path in candidates) {
      final response = await _apiClient.get(path);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return User.fromJson(data);
      }

      if (response.statusCode == 401) {
        throw Exception('Unauthorized — please login again');
      }
    }

    throw Exception('Could not load current user');
  }

  String _errorFromResponse(String body, {required String fallback}) {
    try {
      final Map<String, dynamic> data =
          jsonDecode(body) as Map<String, dynamic>;
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
      return data.values.first.toString();
    } catch (_) {
      return fallback;
    }
  }
}
