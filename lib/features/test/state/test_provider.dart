import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/api/api_constants.dart';
import '../../auth/state/auth_provider.dart';
import '../data/models/test_model.dart';

class QuestionsProvider extends ChangeNotifier {
  QuestionsProvider(this._auth);

  final AuthProvider _auth;
  final String _baseUrl = apiBaseUrl; 

  List<QuestionModel> questions = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> loadQuestions(int testId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final access = _auth.accessToken;
      if (access == null || access.isEmpty) {
        throw Exception("Not authenticated");
      }

      final url = Uri.parse('$_baseUrl/questions/?test_id=$testId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $access',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load questions: ${response.body}');
      }

      final List data = jsonDecode(response.body);

      questions = data.map((e) => QuestionModel.fromJson(e)).toList();
    } catch (e) {
      questions = [];
      debugPrint("Error loading questions: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
