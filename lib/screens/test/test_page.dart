import 'package:flutter/material.dart';
import '../../utils/DB_tests.dart';
import '../../utils/DB_test_options.dart';
import '../../router.dart';
import '../../features/test/state/test_provider.dart';
import '../../features/test/data/models/test_model.dart';

import '../../features/auth/state/auth_provider.dart';

class TestPage extends StatefulWidget {
  final int id;
  final AuthProvider _authProvider;
  const TestPage({super.key, required this.id, required AuthProvider authProvider}) : _authProvider = authProvider;

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final _db = DatabaseHelperTests.instance;
  final _dbOptions = DatabaseHelperOptions.instance;
  late final QuestionsProvider api;
  List<QuestionModel> results = [];


  Future<void> _loadResults() async {
    
    try {
      results = [];
      final data = await _db.getTestsById(widget.id);
      for (var element in data) {
        final List<Map<String, dynamic>> dataOptions = await _dbOptions.getResultsbyQId(element['question_id']);
        List<OptionModel> options = [];
        for (var e in dataOptions) {
          OptionModel option = OptionModel(
            id: e['id'],
            text: e['option_text'],
            isCorrect: e['is_correct'] == 1,
            image: e['image'],);
          options.add(option);
        }
        
        QuestionModel question = QuestionModel(
          id: element['question_id'],
          questionText: element['question_text'],
          image: element['image'],
          score: element['score'],
          questionType: element['question_type'],
          section: element['section'],
          options: options,
        );
        
        results.add(question);
        
      }
    }
    catch (e) {
      print('Error loading results: $e');
      await api.loadQuestions(widget.id);
      results = api.questions;
    }
    finally {
      setState(() {});
    }
    
  }

  @override
  void initState() {
    super.initState();
    api = QuestionsProvider(widget._authProvider);
    _loadResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Test Page Placeholder'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, AppRouter.register),
              child: const Text('Go to Register'),
            ),
          ],
        ),
      ),
    );
  }
}
