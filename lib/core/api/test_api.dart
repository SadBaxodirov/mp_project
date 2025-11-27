import 'dart:convert';

import 'api_client.dart';
import 'api_constants.dart';
import '../models/test.dart';

class TestApi {
  final ApiClient client;

  TestApi() : client = ApiClient(apiBaseUrl);

  Future<List<Test>> getTests() async {
    final response = await client.get('/tests');
    if (response.statusCode != 200) {
      throw Exception("Failed to load tests");
    }

    final List<dynamic> jsonList =
    jsonDecode(utf8.decode(response.bodyBytes));
    return jsonList
        .map((json) => Test.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Test> getTest(int id) async {
    final response = await client.get('/tests/$id');
    if (response.statusCode != 200) {
      throw Exception("Failed to load test $id");
    }

    final Map<String, dynamic> json =
    jsonDecode(utf8.decode(response.bodyBytes));
    return Test.fromJson(json);
  }
}
