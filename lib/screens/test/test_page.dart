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

  void _toggleFlag(int index) {
    setState(() {
      _flagged[index] = !_flagged[index];
    });
  }

  void _goToQuestion(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() => _currentQuestion = index);
  }

  void _openQuestionList() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Question list',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                _questions.length,
                (index) {
                  final isAnswered = _selectedOptions[index] != null;
                  final isFlagged = _flagged[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _goToQuestion(index);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: index == _currentQuestion
                            ? const Color(0xFF2557D6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAnswered
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: index == _currentQuestion
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isFlagged)
                            const Positioned(
                              top: 6,
                              right: 6,
                              child: Icon(
                                Icons.flag,
                                size: 14,
                                color: Color(0xFFF97316),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${_questions.length - _selectedOptions.where((e) => e != null).length} unanswered',
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Leave test?'),
            content: const Text(
              'Your answers will be saved. Do you want to exit to the dashboard?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        ) ??
        false;

    if (shouldExit && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.home,
        (_) => false,
      );
    }
    return shouldExit;
  }

  Future<void> _confirmEndModule(BuildContext context) async {
    final unanswered =
        _questions.length - _selectedOptions.where((e) => e != null).length;
    final end = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('End module?'),
            content: Text(
              'You still have $unanswered unanswered questions. Are you sure you want to end this module?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continue answering'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('End module'),
              ),
            ],
          ),
        ) ??
        false;

    if (end && context.mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.results);
    }
  }

  Future<void> _showNotes() async {
    final controller = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scratchpad',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Jot down quick notes or calculations...',
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.flagged,
    required this.onFlag,
    required this.onNotes,
    required this.onCalculator,
    required this.onTextSize,
  });

  final bool flagged;
  final VoidCallback onFlag;
  final VoidCallback onNotes;
  final VoidCallback onCalculator;
  final VoidCallback onTextSize;

  @override
  void initState() {
    super.initState();
    api = QuestionsProvider(widget._authProvider);
    _loadResults();
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8EDFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: active ? const Color(0xFF2557D6) : const Color(0xFF475569),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    required this.label,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8EDFF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF2557D6) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2557D6)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 15, height: 1.3),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF2557D6)),
          ],
        ),
      ),
    );
  }
}

class _Question {
  const _Question({
    required this.section,
    required this.module,
    required this.prompt,
    required this.options,
    this.passage,
  });

  final String section;
  final String module;
  final String prompt;
  final List<String> options;
  final String? passage;
}

const _sampleQuestions = <_Question>[
  _Question(
    section: 'Reading & Writing',
    module: 'Module 1',
    passage:
        'The school newspaper is planning to launch a new science column.\n'
        'Students will submit short articles describing experiments, inventions, or\n'
        'discoveries that interest them. The editors hope the column will encourage\n'
        'more students to explore science outside their classes.',
    prompt:
        'Which choice best states the main purpose of the new science column?',
    options: [
      'To explain difficult science topics in advanced detail',
      'To replace traditional science classes at the school',
      'To give students a space to share their interest in science',
      'To report only on science competitions and awards',
    ],
  ),
  _Question(
    section: 'Math',
    module: 'Module 2',
    prompt:
        'A tutoring center charges a fixed registration fee of \$10 plus \$8 per hour of tutoring. '
        'Which equation represents the total cost C (in dollars) for h hours of tutoring?',
    options: [
      'C = 10h + 8',
      'C = 8h + 10',
      'C = 18h',
      'C = 10h - 8',
    ],
  ),
];
