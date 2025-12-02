import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:provider/provider.dart';

import '../../core/api/test_api.dart';
import '../../features/auth/state/auth_provider.dart';
import '../../features/test/data/models/answer_summary.dart';
import '../../features/test/data/models/test_model.dart';
import '../../features/test/state/test_provider.dart';
import '../../router.dart';
import '../../utils/DB_answers.dart';
import '../../utils/DB_tests.dart';

class TestPage extends StatefulWidget {
  const TestPage({
    super.key,
    required this.testId,
    this.resumeUserTestId,
    this.resumeAnswers,
    this.resumeSectionIndex = 0,
  });

  final int testId;
  final int? resumeUserTestId;
  final Map<int, int?>? resumeAnswers;
  final int resumeSectionIndex;

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  static const _sections = ['section_1', 'section_2', 'section_3', 'section_4'];

  late final QuestionsProvider _questionsProvider;
  final DatabaseHelper _answersDb = DatabaseHelper.instance;
  final DatabaseHelperTests _testsDb = DatabaseHelperTests.instance;
  final TestApi _testApi = TestApi();
  final PageController _pageController = PageController();
  final Map<int, TextEditingController> _textControllers = {};
  final Map<int, String> _textInputs = {};
  bool _submitting = false;

  int _currentQuestion = 0;
  late int _currentSectionIndex;
  double _textScale = 1.0;
  bool _initializing = true;
  String? _error;
  List<bool> _flagged = [];
  final Map<int, int?> _resumeAnswers = {};

  @override
  void initState() {
    super.initState();
    _currentSectionIndex = widget.resumeSectionIndex;
    _questionsProvider = QuestionsProvider(context.read<AuthProvider>());
    if (widget.resumeAnswers != null) {
      _resumeAnswers.addAll(widget.resumeAnswers!);
    }
    _initTest();
  }

  Future<void> _cacheQuestions(
    String sectionId,
    List<QuestionModel> questions,
  ) async {
    for (final q in questions) {
      await _testsDb.insertTest({
        'test_id': widget.testId,
        'question_id': q.id,
        'question_text': q.questionText,
        'image': q.image,
        'score': q.score,
        'question_type': q.questionType,
        'section': sectionId,
        'ansver': null,
      });
    }
  }

  Future<void> _saveAnswer(QuestionModel question, int? optionId) async {
    if (kIsWeb) return;
    final userTestId = _questionsProvider.userTestId;
    if (userTestId == null) return;
    final isCorrect = question.options
        .any((option) => option.id == optionId && option.isCorrect);
    await _answersDb.upsertResult({
      'user_test_id': userTestId,
      'question_id': question.id,
      'selected_option_id': optionId,
      'is_correct': isCorrect ? 1 : 0,
    });
  }

  @override
  void dispose() {
    _questionsProvider.dispose();
    _pageController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _initTest() async {
    setState(() {
      _initializing = true;
      _error = null;
    });

    try {
      if (widget.resumeUserTestId != null) {
        _questionsProvider.userTestId = widget.resumeUserTestId;
      } else {
        await _questionsProvider.createUserTest(testId: widget.testId);
      }
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
        testId: widget.testId,
        sectionId: sectionId,
      );

      final questions = _questionsProvider.questionsForSection(sectionId);
      _flagged = List<bool>.filled(questions.length, false);

      // Cache questions locally for resume.
      await _cacheQuestions(sectionId, questions);

      // Apply any resumed answers for this section.
      await _loadSavedAnswersIntoProvider(sectionId, questions);

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

  Future<void> _loadSavedAnswersIntoProvider(
    String sectionId,
    List<QuestionModel> questions,
  ) async {
    if (_resumeAnswers.isEmpty && !kIsWeb) {
      final userTestId = _questionsProvider.userTestId;
      if (userTestId != null) {
        final stored = await _answersDb.getByUserTestId(userTestId);
        for (final row in stored) {
          _resumeAnswers[row['question_id'] as int] =
              row['selected_option_id'] as int?;
        }
      }
    }

    if (_resumeAnswers.isEmpty) return;

    for (final q in questions) {
      final answered = _resumeAnswers[q.id];
      if (answered != null) {
        _questionsProvider.selectAnswer(q.id, answered);
      }
    }
  }

  void _selectOption(QuestionModel question, int optionId) {
    _questionsProvider.selectAnswer(question.id, optionId);
    setState(() {});
    _saveAnswer(question, optionId);
  }

  OptionModel? _findCorrectOption(QuestionModel question) {
    for (final option in question.options) {
      if (option.isCorrect) return option;
    }
    return null;
  }

  OptionModel? _findOptionById(QuestionModel question, int? optionId) {
    if (optionId == null) return null;
    for (final option in question.options) {
      if (option.id == optionId) return option;
    }
    return null;
  }

  TextEditingController _controllerForQuestion(QuestionModel question) {
    return _textControllers.putIfAbsent(question.id, () {
      final controller = TextEditingController();
      final prefill = _textInputs[question.id] ??
          (question.questionType == 'text'
              ? _prefillTextInput(question)
              : null);
      if (prefill != null) {
        controller.text = prefill;
      }
      return controller;
    });
  }

  String? _prefillTextInput(QuestionModel question) {
    final selectedId = _questionsProvider.answers[question.id];
    final correctOption = _findCorrectOption(question);
    if (selectedId != null &&
        correctOption != null &&
        selectedId == correctOption.id) {
      _textInputs[question.id] = correctOption.text;
      return correctOption.text;
    }
    return _textInputs[question.id];
  }

  Future<void> _handleTextInput(
    QuestionModel question,
    String rawValue,
  ) async {
    final value = rawValue.trim();
    setState(() {
      _textInputs[question.id] = value;
    });

    final correctOption = _findCorrectOption(question);
    int? optionId;

    if (value.isNotEmpty && correctOption != null) {
      final correctAnswer = correctOption.text.trim();
      if (value == correctAnswer) {
        optionId = correctOption.id;
      }
    }

    _questionsProvider.selectAnswer(question.id, optionId);
    await _saveAnswer(question, optionId);
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openPreviewPage();
                },
                icon: const Icon(Icons.view_comfy_alt_outlined),
                label: const Text('Go to preview page'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPreviewPage({bool launchedFromLastQuestion = false}) async {
    final questions = _questionsProvider.currentQuestions;
    if (questions.isEmpty) return;

    final isLastSection = _currentSectionIndex == _sections.length - 1;
    final selectedIndex = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => _QuestionPreviewPage(
          sectionLabel: 'Section ${_currentSectionIndex + 1}',
          questions: questions,
          flagged: List<bool>.from(_flagged),
          answeredMap: Map<int, int?>.from(_questionsProvider.answers),
          currentIndex: _currentQuestion,
          isLastSection: isLastSection,
        ),
      ),
    );

    if (selectedIndex == -1) {
      await _completeSection();
    } else if (selectedIndex != null) {
      _goToQuestion(selectedIndex);
    } else if (launchedFromLastQuestion &&
        selectedIndex == null &&
        isLastSection) {
      // no-op fallback
    }
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
    if (kIsWeb) {
      // Skip local persistence on web (avoids wasm init issues).
      return;
    }
    final userTestId = _questionsProvider.userTestId;
    if (userTestId == null) return;

    final sectionId = _sections[_currentSectionIndex];
    final answers = _questionsProvider.answersForSection(sectionId);

    for (final answer in answers) {
      await _answersDb.upsertResult({
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

  List<AnswerSummary> _buildAnswerSummaries() {
    final summaries = <AnswerSummary>[];
    for (final sectionId in _sections) {
      final questions = _questionsProvider.questionsForSection(sectionId);
      for (final q in questions) {
        final selectedId = _questionsProvider.answers[q.id];
        final correctOption = _findCorrectOption(q);
        final selectedOption = _findOptionById(q, selectedId);

        final userAnswer = q.questionType == 'text'
            ? (_textInputs[q.id]?.trim() ?? '')
            : (selectedOption?.text ?? '');

        final isCorrect = q.questionType == 'text'
            ? (selectedId != null &&
                correctOption != null &&
                selectedId == correctOption.id)
            : (selectedOption?.isCorrect ?? false);

        summaries.add(
          AnswerSummary(
            questionId: q.id,
            questionText: q.questionText,
            userAnswer: userAnswer,
            correctAnswer: correctOption?.text ?? '',
            isCorrect: isCorrect,
            section: q.section,
            score: q.score,
          ),
        );
      }
    }
    return summaries;
  }

  Future<void> _completeSection() async {
    final isLastSection = _currentSectionIndex == _sections.length - 1;
    if (isLastSection && _submitting) return;
    if (isLastSection) {
      setState(() => _submitting = true);
    }

    try {
      await _persistSectionAnswers();

      if (isLastSection) {
        final userTestId = _questionsProvider.userTestId;
        final answers = _gatherAllAnswers();
        final summaries = _buildAnswerSummaries();
        if (userTestId != null && answers.isNotEmpty) {
          try {
            await _testApi.submitAnswers(
              userTestId: userTestId,
              answers: answers,
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Submit failed: $e')),
            );
            return;
          }
        } else if (answers.isEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No answers to submit.')),
          );
          return;
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          AppRouter.results,
          arguments: {
            'userTestId': userTestId,
            'summaries': summaries,
          },
        );
        return;
      }

      setState(() => _currentSectionIndex += 1);
      await _loadSection();
    } finally {
      if (isLastSection) {
        if (mounted) {
          setState(() => _submitting = false);
        } else {
          _submitting = false;
        }
      }
    }
  }

  Future<void> _onNext() async {
    if (_submitting) return;
    final questions = _questionsProvider.currentQuestions;
    if (questions.isEmpty) return;

    final isLastQuestion = _currentQuestion == questions.length - 1;
    if (isLastQuestion) {
      await _openPreviewPage(launchedFromLastQuestion: true);
    } else {
      _goToQuestion(_currentQuestion + 1);
    }
  }

  Widget _buildBody(BuildContext context) {
    final provider = context.watch<QuestionsProvider>();
    final questions = provider.currentQuestions;

    if (_submitting) {
      return Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Submitting...',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
    }

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
                icon: Icons.view_comfy_alt_outlined,
                label: 'Preview',
                onTap: _openPreviewPage,
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
          _MathText(
            text: question.questionText,
            textScale: _textScale,
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
          if (question.questionType == 'text')
            _TextAnswerField(
              controller: _controllerForQuestion(question),
              onChanged: (value) => _handleTextInput(question, value),
              textScale: _textScale,
            )
          else
            Column(
              children: question.options.asMap().entries.map((entry) {
                final indexOption = entry.key;
                final option = entry.value;
                return _AnswerOption(
                  label: String.fromCharCode(65 + indexOption),
                  text: option.text,
                  isSelected: selectedId == option.id,
                  onTap: () => _selectOption(question, option.id),
                  textScale: _textScale,
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
                  onPressed: _submitting ? null : _onNext,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
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
    required this.textScale,
  });

  final String label;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final double textScale;

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
              child: _MathText(
                text: text,
                textScale: textScale,
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

class _QuestionPreviewPage extends StatelessWidget {
  const _QuestionPreviewPage({
    required this.sectionLabel,
    required this.questions,
    required this.flagged,
    required this.answeredMap,
    required this.currentIndex,
    required this.isLastSection,
  });

  final String sectionLabel;
  final List<QuestionModel> questions;
  final List<bool> flagged;
  final Map<int, int?> answeredMap;
  final int currentIndex;
  final bool isLastSection;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$sectionLabel preview'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$sectionLabel • ${questions.length} questions',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final isAnswered = answeredMap[questions[index].id] != null;
                  final isFlagged = flagged.isNotEmpty && index < flagged.length
                      ? flagged[index]
                      : false;
                  final isCurrent = index == currentIndex;

                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Navigator.pop(context, index),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isCurrent ? const Color(0xFF2557D6) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAnswered
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrent
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, -1),
                icon: const Icon(Icons.check_circle_outline),
                label:
                    Text(isLastSection ? 'Submit and finish' : 'Next section'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TextAnswerField extends StatelessWidget {
  const _TextAnswerField({
    required this.controller,
    required this.onChanged,
    required this.textScale,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter the answer',
          textScaler: TextScaler.linear(textScale),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.text,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.\-/]')),
            LengthLimitingTextInputFormatter(5),
          ],
          decoration: const InputDecoration(
            hintText: 'e.g. 1.2 or 6/5',
            border: OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MathText extends StatelessWidget {
  const _MathText({
    required this.text,
    this.style,
    this.textScale = 1.0,
  });

  final String text;
  final TextStyle? style;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final mergedStyle = defaultStyle.merge(style);
    final effectiveStyle = mergedStyle.copyWith(
      color: mergedStyle.color ?? defaultStyle.color ?? Colors.black,
    );
    final spans = _parseSpans(text, effectiveStyle);

    // If no LaTeX markup was found, fall back to a regular Text widget.
    final noMathFound = spans.length == 1 &&
        spans.first is TextSpan &&
        (spans.first as TextSpan).text == text;

    if (noMathFound) {
      return Text(
        text,
        style: effectiveStyle,
        textScaler: TextScaler.linear(textScale),
        textAlign: TextAlign.start,
      );
    }

    return RichText(
      text: TextSpan(style: effectiveStyle, children: spans),
      textScaler: TextScaler.linear(textScale),
      textAlign: TextAlign.start,
    );
  }

  List<InlineSpan> _parseSpans(String input, TextStyle baseStyle) {
    final regex = RegExp(r'(\\\[.*?\\\]|\\\(.*?\\\))', dotAll: true);
    final spans = <InlineSpan>[];
    var currentIndex = 0;

    for (final match in regex.allMatches(input)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: input.substring(currentIndex, match.start)));
      }

      final fullMatch = match.group(0)!;
      final isBlock = fullMatch.startsWith(r'\[');
      final content = fullMatch.substring(2, fullMatch.length - 2);

      final needsLineBreak = isBlock &&
          spans.isNotEmpty &&
          !(spans.last is TextSpan &&
              ((spans.last as TextSpan).text ?? '').endsWith('\n'));
      if (needsLineBreak) {
        spans.add(const TextSpan(text: '\n'));
      }

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: isBlock
                ? const EdgeInsets.symmetric(vertical: 8)
                : EdgeInsets.zero,
            child: Math.tex(
              content.trim(),
              mathStyle: isBlock ? MathStyle.display : MathStyle.text,
              textStyle: baseStyle.copyWith(height: baseStyle.height),
            ),
          ),
        ),
      );

      if (isBlock) {
        spans.add(const TextSpan(text: '\n'));
      }

      currentIndex = match.end;
    }

    if (currentIndex < input.length) {
      spans.add(TextSpan(text: input.substring(currentIndex)));
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: input));
    }

    return spans;
  }
}
