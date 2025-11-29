import 'dart:convert';

import 'api_client.dart';
import 'api_constants.dart';
import '../models/user_test.dart';

class UserTestApi {
  final ApiClient client;

  UserTestApi() : client = ApiClient(apiBaseUrl);

  ///create user test when user starts solving test, userId and testId required
  ///exam is not required, default: false
  Future<UserTest> createUserTest({
    required int userId,
    required int testId,
    bool exam = false,
  }) async {
    final response = await client.post('/user-tests/', {
      "user": userId,
      "test": testId,
      "exam": exam,
    });

    if (response.statusCode != 201) {
      throw Exception(
        "Failed to create user_test for user=$userId test=$testId "
        "(status: ${response.statusCode})",
      );
    }

    final Map<String, dynamic> json =
        jsonDecode(utf8.decode(response.bodyBytes));

    return UserTest.fromJson(json);
  }

  ///delete user test if unnecessary
  ///e.g user cancels test, user_test can be deleted
  Future<void> deleteUserTest(int userTestId) async {
    final response = await client.delete('/user-tests/$userTestId/');

    if (response.statusCode != 204) {
      throw Exception(
        "Failed to delete user_test $userTestId "
        "(status: ${response.statusCode})",
      );
    }
  }
}
