import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_storage.dart';
import 'api_constants.dart';

Future<bool> getTokens(String username, String password) async {
  final res = await http.post(
    Uri.parse("$apiBaseUrl/token/"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"username": username, "password":password}),
  );

  if (res.statusCode != 200) return false;

  final data = jsonDecode(res.body);
  await TokenStorage.saveTokens(data["access"], data["refresh"]);

  return true;
}

Future<bool> refreshToken() async {
  String? refresh = await TokenStorage.getRefresh();
  if (refresh == null) return false;

  final res = await http.post(
    Uri.parse("$apiBaseUrl/token/refresh/"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"refresh": refresh}),
  );

  if (res.statusCode != 200) return false;

  final data = jsonDecode(res.body);
  await TokenStorage.saveTokens(data["access"], data["refresh"]);

  return true;
}
