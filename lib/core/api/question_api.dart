import 'dart:convert';

import 'api_client.dart';
import 'api_constants.dart';
import '../models/question.dart';

class QuestionApi {
  final ApiClient client;

  QuestionApi() : client = ApiClient(apiBaseUrl);

  /// get question by id
  Future<Question> getQuestion(int id) async {
    final response = await client.get('/questions/$id');

    if (response.statusCode != 200) {
      throw Exception("Failed to load question $id");
    }

    final Map<String, dynamic> json =
    jsonDecode(utf8.decode(response.bodyBytes));

    return Question.fromJson(json);
  }

  /// -----------------------------------------------------------
  /// GET questions by test & section
  ///
  /// Possible section values:
  ///     section_1, section_2, section_3, section_4
  /// Example request:
  ///     GET /questions/?test_id=12&section=section_1
  /// Response:
  ///     List<Question> with options included
  /// -----------------------------------------------------------
  Future<List<Question>> getQuestionsByTestAndSection({
    required int testId,
    required String section,
  }) async {
    final response = await client.get(
      '/questions/?test_id=$testId&section=$section',
    );

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load questions for test=$testId section=$section",
      );
    }

    final List<dynamic> jsonList =
    jsonDecode(utf8.decode(response.bodyBytes));

    return jsonList
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
