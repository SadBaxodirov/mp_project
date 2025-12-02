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

    final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
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

  Future<void> submitAnswers({
    required int userTestId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final formattedAnswers = answers
        .map((a) => {
              'id': null,
              'user_test': userTestId,
              'question': a['question_id'] ?? a['question'],
              'selected_option':
                  a['selected_option_id'] ?? a['selected_option'],
              'is_correct': a['is_correct'] ?? false,
            })
        .toList();

    final response = await client.post('/submit-answers/', {
      'user_test': userTestId,
      'answers': formattedAnswers,
    });

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to submit answers (status: ${response.statusCode}): ${response.body}',
      );
    }
  }
}
