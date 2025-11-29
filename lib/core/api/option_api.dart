import 'dart:convert';

import 'api_client.dart';
import 'api_constants.dart';
import '../models/question_option.dart';

class OptionApi {
  final ApiClient client;

  OptionApi() : client = ApiClient(apiBaseUrl);

  /// get options by id
  Future<QuestionOption> getOption(int id) async {
    final response = await client.get('/options/$id');

    if (response.statusCode != 200) {
      throw Exception("Failed to load option $id");
    }

    final Map<String, dynamic> json =
    jsonDecode(utf8.decode(response.bodyBytes));

    return QuestionOption.fromJson(json);
  }
}
