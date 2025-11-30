import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/state/auth_provider.dart';
import '../../features/test/data/models/test_model.dart';
import '../../features/test/state/test_provider.dart';
import '../../router.dart';
import '../../utils/DB_test_options.dart';
import '../../utils/DB_tests.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key, required this.testList});

  final List<int> testList;

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final _db = DatabaseHelperTests.instance;
  final _dbOptions = DatabaseHelperOptions.instance;
  late final QuestionsProvider _api;
  final PageController _pageController = PageController();

  List<QuestionModel> _questions = [];
  List<int?> _selectedOptions = [];
  List<bool> _flagged = [];
  int _currentQuestion = 0;
  double _textScale = 1.0;
  bool _isLoading = true;
  bool _usingSampleData = false;

  int? get _testId => widget.testList.isNotEmpty ? widget.testList.first : null;

  @override
  void initState() {
    super.initState();
    _api = QuestionsProvider(context.read<AuthProvider>());
    _loadQuestions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final List<QuestionModel> loaded = [];
    var usedSample = false;
    final testId = _testId;

    if (testId != null) {
      try {
        final data = await _db.getTestsById(testId);
        for (final element in data) {
          final optionsRaw =
              await _dbOptions.getResultsbyQId(element['question_id'] as int);
          final options = optionsRaw
              .map(
                (e) => OptionModel(
                  id: e['id'] as int,
                  text: e['option_text'] as String,
                  isCorrect: (e['is_correct'] as int) == 1,
                  image: e['image'] as String?,
                ),
              )
              .toList();

          loaded.add(
            QuestionModel(
              id: element['question_id'] as int,
              questionText: element['question_text'] as String,
              image: element['image'] as String?,
              score: (element['score'] as num).toDouble(),
              questionType: element['question_type'] as String,
              section: element['section'] as String,
              options: options,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error loading cached questions: $e');
      }
    }

    if (loaded.isEmpty && testId != null) {
      await _api.loadQuestions(testId);
      loaded.addAll(_api.questions);
    }

    if (loaded.isEmpty) {
      usedSample = true;
      loaded.addAll(
        _sampleQuestions
            .asMap()
            .entries
            .map((entry) => _questionModelFromSample(entry.key, entry.value))
            .toList(),
      );
    }

    if (!mounted) return;

    setState(() {
      _questions = loaded;
      _selectedOptions = List<int?>.filled(_questions.length, null);
      _flagged = List<bool>.filled(_questions.length, false);
      _currentQuestion = 0;
      _isLoading = false;
      _usingSampleData = usedSample;
    });
  }

  void _selectOption(int optionId) {
    if (_questions.isEmpty) return;
    setState(() {
      _selectedOptions[_currentQuestion] = optionId;
    });
  }

  void _toggleFlag(int index) {
    if (_questions.isEmpty) return;
    setState(() => _flagged[index] = !_flagged[index]);
  }

  void _goToQuestion(int index) {
    if (index < 0 || index >= _questions.length) return;
    setState(() => _currentQuestion = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _cycleTextSize() {
    const sizes = [1.0, 1.1, 1.2];
    final currentIndex = sizes.indexOf(_textScale);
    final nextIndex = (currentIndex + 1) % sizes.length;
    setState(() => _textScale = sizes[nextIndex]);
  }

  void _openQuestionList() {
    if (_questions.isEmpty) return;

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
                  final isFlagged =
                      _flagged.isNotEmpty ? _flagged[index] : false;
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

    if (!context.mounted) return shouldExit;

    if (shouldExit) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.home,
        (_) => false,
      );
    }
    return shouldExit;
  }

  Future<void> _confirmEndModule(BuildContext context) async {
    if (_questions.isEmpty) return;

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

    if (!context.mounted) return;

    if (end) {
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_questions.isEmpty) {
      return const Center(child: Text('No questions available.'));
    }

    return Column(
      children: [
        _buildToolbar(),
        const Divider(height: 1),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const ClampingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentQuestion = index);
            },
            itemCount: _questions.length,
            itemBuilder: (_, index) => _buildQuestionCard(index),
          ),
        ),
        _buildNavigation(),
      ],
    );
  }

  Widget _buildToolbar() {
    final isFlagged = _flagged.isNotEmpty && _currentQuestion < _flagged.length
        ? _flagged[_currentQuestion]
        : false;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF8FAFC),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: 8,
            children: [
              _ToolbarButton(
                icon: Icons.flag_outlined,
                label: 'Flag',
                active: isFlagged,
                onTap: () => _toggleFlag(_currentQuestion),
              ),
              _ToolbarButton(
                icon: Icons.note_alt_outlined,
                label: 'Notes',
                onTap: _showNotes,
              ),
              _ToolbarButton(
                icon: Icons.list_alt_outlined,
                label: 'List',
                onTap: _openQuestionList,
              ),
              _ToolbarButton(
                icon: Icons.text_fields,
                label: 'Text',
                onTap: _cycleTextSize,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmExit(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];
    final selectedId = _selectedOptions[index];
    final passage = _usingSampleData && index < _sampleQuestions.length
        ? _sampleQuestions[index].passage
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${question.section} • Question ${index + 1} of ${_questions.length}',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (passage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                passage,
                textScaler: TextScaler.linear(_textScale),
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            question.questionText,
            textScaler: TextScaler.linear(_textScale),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (question.image != null) ...[
            const SizedBox(height: 10),
            Image.network(
              question.image!,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ],
          const SizedBox(height: 16),
          Column(
            children: question.options.asMap().entries.map((entry) {
              final indexOption = entry.key;
              final option = entry.value;
              return _AnswerOption(
                label: String.fromCharCode(65 + indexOption),
                text: option.text,
                isSelected: selectedId == option.id,
                onTap: () => _selectOption(option.id),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    final unanswered =
        _questions.length - _selectedOptions.where((e) => e != null).length;
    final isLast = _currentQuestion == _questions.length - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$unanswered unanswered',
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _openQuestionList,
                icon: const Icon(Icons.grid_view),
                label: const Text('Questions'),
              ),
              const Spacer(),
              TextButton(
                onPressed: _currentQuestion > 0
                    ? () => _goToQuestion(_currentQuestion - 1)
                    : null,
                child: const Text('Previous'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isLast
                    ? () => _confirmEndModule(context)
                    : () => _goToQuestion(_currentQuestion + 1),
                child: Text(isLast ? 'End module' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
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
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmExit(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Test'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _confirmExit(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadQuestions,
              tooltip: 'Reload',
            ),
          ],
        ),
        body: SafeArea(child: _buildBody()),
      ),
    );
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

QuestionModel _questionModelFromSample(int index, _Question question) {
  return QuestionModel(
    id: index,
    questionText: question.prompt,
    image: null,
    score: 1,
    questionType: question.module,
    section: question.section,
    options: question.options.asMap().entries.map((entry) {
      return OptionModel(
        id: entry.key,
        text: entry.value,
        isCorrect: entry.key == 0,
        image: null,
      );
    }).toList(),
  );
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
