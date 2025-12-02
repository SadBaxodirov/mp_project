import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/api/api_constants.dart';
import '../../../core/api/test_api.dart';
import '../../../core/api/user_test_api.dart';
import '../../auth/state/auth_provider.dart';
import '../data/models/test_model.dart';

/// Manages questions, answers, and user-test lifecycle for a test run.
class QuestionsProvider extends ChangeNotifier {
  QuestionsProvider(this._auth);

  final AuthProvider _auth;
  final String _baseUrl = apiBaseUrl;
  final UserTestApi _userTestApi = UserTestApi();
  final TestApi _testApi = TestApi();

  final Map<String, List<QuestionModel>> _sectionQuestions = {};
  final Map<int, int?> _answers = {}; // questionId -> optionId

  bool _isLoading = false;
  String? _currentSection;
  int? userTestId;

  bool get isLoading => _isLoading;
  String? get currentSection => _currentSection;
  Map<int, int?> get answers => Map.unmodifiable(_answers);

  List<QuestionModel> questionsForSection(String sectionId) =>
      _sectionQuestions[sectionId] ?? [];

  List<QuestionModel> get currentQuestions => _currentSection == null
      ? []
      : (_sectionQuestions[_currentSection!] ?? []);

  Future<void> createUserTest({
    required int testId,
    bool exam = false,
  }) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not found while creating user_test');
    }
    final created = await _userTestApi.createUserTest(
      userId: userId,
      testId: testId,
      exam: exam,
    );
    userTestId = created.id;
    notifyListeners();
  }

  Future<void> loadSection({
    required int testId,
    required String sectionId,
  }) async {
    _isLoading = true;
    _currentSection = sectionId;
    notifyListeners();

    try {
      final access = _auth.accessToken;
      if (access == null || access.isEmpty) {
        throw Exception('Not authenticated');
      }

      final url =
          Uri.parse('$_baseUrl/questions/?test=$testId&section=$sectionId');

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

      _sectionQuestions[sectionId] =
          data.map((e) => QuestionModel.fromJson(e)).toList();
    } catch (e) {
      _sectionQuestions[sectionId] = [];
      debugPrint('Error loading questions for $sectionId: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectAnswer(int questionId, int? optionId) {
    _answers[questionId] = optionId;
    notifyListeners();
  }

  List<Map<String, dynamic>> answersForSection(String sectionId) {
    final questions = _sectionQuestions[sectionId] ?? [];
    return questions.map((q) {
      final selected = _answers[q.id];
      final isCorrect = selected == null
          ? false
          : q.options.any((o) => o.id == selected && o.isCorrect);
      return {
        'question_id': q.id,
        'selected_option_id': selected,
        'is_correct': isCorrect,
      };
    }).toList();
  }

  List<Map<String, dynamic>> allAnswers() {
    final all = <Map<String, dynamic>>[];
    for (final entry in _sectionQuestions.entries) {
      all.addAll(answersForSection(entry.key));
    }
    return all;
  }

  Future<void> submitAllAnswers() async {
    if (userTestId == null) {
      throw Exception('user_test not created');
    }
    final prepared =
        allAnswers().where((a) => a['selected_option_id'] != null).toList();
    if (prepared.isEmpty) {
      throw Exception('No answers to submit.');
    }
    await _testApi.submitAnswers(userTestId: userTestId!, answers: prepared);
  }

  void reset() {
    _sectionQuestions.clear();
    _answers.clear();
    _isLoading = false;
    _currentSection = null;
    userTestId = null;
    notifyListeners();
  }
}
