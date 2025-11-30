import 'dart:convert';
import 'api_client.dart';
import 'api_constants.dart';
import 'package:http/http.dart' as http;

import '../models/user.dart';
import '../models/auth_tokens.dart';

String _errorFromResponse(String body, {required String fallback}) {
  try {
    final Map<String, dynamic> data = jsonDecode(body) as Map<String, dynamic>;
    if (data.containsKey('detail')) return data['detail'].toString();
    return data.values.first.toString();
  } catch (_) {
    return fallback;
  }
}

class UserApi {
  final ApiClient client;

  UserApi() : client = ApiClient(apiBaseUrl);

  /// Login → returns access + refresh tokens
  Future<AuthTokens> login(
      {required String username, required String password}) async {
    final response = await client
        .post('/token/', {"username": username, "password": password});

    if (response.statusCode != 200) {
      throw Exception(
          _errorFromResponse(response.body, fallback: "Login failed"));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthTokens.fromJson(data);
  }

  Future<bool> register({required User user, required String password}) async {
    final Map<String, dynamic> payload = {
      ...user.toJson(),
      "password": password,
    };
    //create user
    final response = await client.post('/user/register/', payload);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
          _errorFromResponse(response.body, fallback: "Registration failed"));
    }
    return true;
  }

  Future<User> getCurrentUser() async {
    final response = await client.get('/user/me/');

    if (response.statusCode != 200) {
      throw Exception("Failed to load current user");
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(data);
  }

  Future<User> updateCurrentUser({
    String? username,
    String? firstName,
    String? lastName,
    String? school,
    String? grade,
    String? phoneNumber,
    String? email,
    required User existing,
  }) async {
    final payload = <String, dynamic>{
      "username": username ?? existing.username,
      "first_name": firstName ?? existing.firstName,
      "last_name": lastName ?? existing.lastName,
      "school": school ?? existing.school,
      "grade": grade ?? existing.grade,
      "phone_number": phoneNumber ?? existing.phoneNumber,
      "email": email ?? existing.email,
    };

    http.Response response = await client.patch('/user/me/', payload);

    if (response.statusCode != 200) {
      response = await client.put('/user/me/', payload);
    }

    if (response.statusCode != 200) {
      throw Exception(
        _errorFromResponse(response.body, fallback: "Profile update failed"),
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(data);
  }
}
