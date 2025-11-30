import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/test_api.dart';
import '../../features/auth/state/auth_provider.dart';
import '../../features/test/data/models/test_model.dart';
import '../../features/test/state/test_provider.dart';
import '../../router.dart';
import '../../utils/DB_ansvers.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key, required this.testList});

  final List<int> testList;

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  static const _sections = ['section_1', 'section_2', 'section_3', 'section_4'];

  late final QuestionsProvider _questionsProvider;
  final DatabaseHelper _answersDb = DatabaseHelper.instance;
  final TestApi _testApi = TestApi();
  final PageController _pageController = PageController();

  int _currentQuestion = 0;
  int _currentSectionIndex = 0;
  double _textScale = 1.0;
  bool _initializing = true;
  String? _error;
  List<bool> _flagged = [];

  int get _testId => widget.testList.isNotEmpty ? widget.testList.first : 0;

  @override
  void initState() {
    super.initState();
    _questionsProvider = QuestionsProvider(context.read<AuthProvider>());
    _initTest();
  }

  @override
  void dispose() {
    _questionsProvider.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initTest() async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    try {
      await _questionsProvider.createUserTest(testId: _testId);
      await _loadSection();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _initializing = false);
      }
    }
  }

  Future<void> _loadSection() async {
    setState(() {
      _initializing = true;
      _error = null;
      _currentQuestion = 0;
    });

    try {
      final sectionId = _sections[_currentSectionIndex];
      await _questionsProvider.loadSection(
        testId: _testId,
        sectionId: sectionId,
      );

      final questions = _questionsProvider.questionsForSection(sectionId);
      _flagged = List<bool>.filled(questions.length, false);

      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(0);
          }
        });
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _initializing = false);
      }
    }
  }

  void _selectOption(QuestionModel question, int optionId) {
    _questionsProvider.selectAnswer(question.id, optionId);
    setState(() {});
  }

  void _toggleFlag(int index) {
    if (index < 0 || index >= _flagged.length) return;
    setState(() => _flagged[index] = !_flagged[index]);
  }

  void _goToQuestion(int index) {
    final questions = _questionsProvider.currentQuestions;
    if (index < 0 || index >= questions.length) return;
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
    final questions = _questionsProvider.currentQuestions;
    if (questions.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Section ${_currentSectionIndex + 1} questions',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                questions.length,
                    (index) {
                  final isAnswered =
                      _questionsProvider.answers[questions[index].id] != null;
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
              '${questions.length - questions.where((q) => _questionsProvider.answers[q.id] != null).length} unanswered',
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

  Future<void> _persistSectionAnswers() async {
    final userTestId = _questionsProvider.userTestId;
    if (userTestId == null) return;

    final sectionId = _sections[_currentSectionIndex];
    final answers = _questionsProvider.answersForSection(sectionId);

    for (final answer in answers) {
      await _answersDb.insertResult({
        'user_test_id': userTestId,
        'question_id': answer['question_id'],
        'selected_option_id': answer['selected_option_id'],
        'is_correct': (answer['is_correct'] as bool) ? 1 : 0,
      });
    }
  }

  List<Map<String, dynamic>> _gatherAllAnswers() {
    final List<Map<String, dynamic>> all = [];
    for (final section in _sections) {
      all.addAll(_questionsProvider.answersForSection(section));
    }
    return all.where((a) => a['selected_option_id'] != null).toList();
  }

  Future<void> _completeSection() async {
    await _persistSectionAnswers();

    final isLastSection = _currentSectionIndex == _sections.length - 1;
    if (isLastSection) {
      final userTestId = _questionsProvider.userTestId;
      if (userTestId != null) {
        await _testApi.submitAnswers(
          userTestId: userTestId,
          answers: _gatherAllAnswers(),
        );
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRouter.results);
      return;
    }

    setState(() => _currentSectionIndex += 1);
    await _loadSection();
  }

  Future<void> _onNext() async {
    final questions = _questionsProvider.currentQuestions;
    if (questions.isEmpty) return;

    final isLastQuestion = _currentQuestion == questions.length - 1;
    if (isLastQuestion) {
      await _completeSection();
    } else {
      _goToQuestion(_currentQuestion + 1);
    }
  }

  Widget _buildBody(BuildContext context) {
    final provider = context.watch<QuestionsProvider>();
    final questions = provider.currentQuestions;

    if (_initializing || provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Error: $_error',
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadSection,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (questions.isEmpty) {
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
            itemCount: questions.length,
            itemBuilder: (_, index) => _buildQuestionCard(questions, index),
          ),
        ),
        _buildNavigation(questions),
      ],
    );
  }

  Widget _buildToolbar() {
    final questions = _questionsProvider.currentQuestions;
    final isFlagged = _flagged.isNotEmpty &&
        _currentQuestion < _flagged.length &&
        _flagged[_currentQuestion];

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
          Text(
            'Section ${_currentSectionIndex + 1} of ${_sections.length} (${questions.length} Qs)',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _confirmExit(context),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(List<QuestionModel> questions, int index) {
    final question = questions[index];
    final selectedId = _questionsProvider.answers[question.id];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${question.section} • Question ${index + 1} of ${questions.length}',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
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
                onTap: () => _selectOption(question, option.id),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation(List<QuestionModel> questions) {
    final answeredCount =
        questions.where((q) => _questionsProvider.answers[q.id] != null).length;
    final unanswered = questions.length - answeredCount;
    final isLast = _currentQuestion == questions.length - 1;
    final isLastSection = _currentSectionIndex == _sections.length - 1;

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
              Flexible(
                child: TextButton(
                  onPressed: _currentQuestion > 0
                      ? () => _goToQuestion(_currentQuestion - 1)
                      : null,
                  child: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ElevatedButton(
                  onPressed: _onNext,
                  child: Text(
                    isLast
                        ? (isLastSection ? 'Submit' : 'Next Section')
                        : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _questionsProvider,
      child: PopScope(
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
                onPressed: _loadSection,
                tooltip: 'Reload section',
              ),
            ],
          ),
          body: SafeArea(
            child: Builder(
              builder: (ctx) => _buildBody(ctx),
            ),
          ),
        ),
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
