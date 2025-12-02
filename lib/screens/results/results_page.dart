import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../core/api/user_test_api.dart';
import '../../core/models/user_test.dart';
import '../../features/test/data/models/answer_summary.dart';
import '../../router.dart';
import '../../utils/DB_answers.dart';
import '../../widgets/main_navigation_bar.dart';

class ResultsPage extends StatefulWidget {
  const ResultsPage({
    super.key,
    this.summaries = const [],
    this.userTestId,
  });

  final List<AnswerSummary> summaries;
  final int? userTestId;

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  final UserTestApi _userTestApi = UserTestApi();
  bool _loadingScores = false;
  String? _scoreError;
  UserTest? _userTest;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    if (widget.userTestId == null) return;
    setState(() {
      _loadingScores = true;
      _scoreError = null;
    });
    try {
      final userTest = await _userTestApi.getUserTestById(widget.userTestId!);
      if (!mounted) return;
      setState(() => _userTest = userTest);
    } catch (e) {
      if (!mounted) return;
      setState(() => _scoreError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingScores = false);
      } else {
        _loadingScores = false;
      }
    }
  }

  Future<void> _handleBackToHome(BuildContext context) async {
    if (widget.userTestId != null) {
      try {
        await DatabaseHelper.instance.deleteResultsByUserTestId(widget.userTestId!);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not clear local answers: $e')),
          );
        }
      }
    }
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.home,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackToHome(context),
        ),
      ),
      bottomNavigationBar: const MainNavigationBar(currentIndex: 2),
      body: SafeArea(
        child: widget.summaries.isEmpty
            ? const _EmptyResults()
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: widget.summaries.length + 2,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _ScoreHeader(
                      loading: _loadingScores,
                      error: _scoreError,
                      mathScore: _userTest?.mathScore,
                      englishScore: _userTest?.englishScore,
                    );
                  }
                  if (index == widget.summaries.length + 1) {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleBackToHome(context),
                        icon: const Icon(Icons.home),
                        label: const Text('Back to Home'),
                      ),
                    );
                  }
                  final summary = widget.summaries[index - 1];
                  return _ResultCard(summary: summary);
                },
              ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.summary});

  final AnswerSummary summary;

  @override
  Widget build(BuildContext context) {
    final isCorrect = summary.isCorrect;
    final badgeColor = isCorrect ? const Color(0xFF10B981) : Colors.red;
    final badgeLabel = isCorrect ? 'Correct' : 'Incorrect';
    final userAnswerDisplay =
        summary.userAnswer.isEmpty ? '—' : summary.userAnswer;
    final correctAnswerDisplay =
        summary.correctAnswer.isEmpty ? '—' : summary.correctAnswer;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Question',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            _MathText(
              text: summary.questionText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Your answer",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            _MathText(
              text: userAnswerDisplay,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 10),
            const Text(
              'Correct answer',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            _MathText(
              text: correctAnswerDisplay,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'No results available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.home,
                (_) => false,
              ),
              icon: const Icon(Icons.home),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({
    required this.loading,
    required this.error,
    required this.mathScore,
    required this.englishScore,
  });

  final bool loading;
  final String? error;
  final double? mathScore;
  final double? englishScore;

  double? get _total {
    if (mathScore == null || englishScore == null) return null;
    return mathScore! + englishScore!;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scores',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Loading scores...'),
                  ],
                ),
              )
            else if (error != null)
              Text(
                error!,
                style: const TextStyle(color: Colors.red),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ScoreTile(
                          label: 'Math',
                          value: mathScore,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ScoreTile(
                          label: 'English',
                          value: englishScore,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ScoreTile(
                    label: 'Total',
                    value: _total,
                    color: const Color(0xFF111827),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double? value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final display = value != null
        ? value!.toStringAsFixed(value!.truncateToDouble() == value ? 0 : 1)
        : '—';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            display,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MathText extends StatelessWidget {
  const _MathText({
    required this.text,
    this.style,
  });

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final mergedStyle = defaultStyle.merge(style);
    final effectiveStyle = mergedStyle.copyWith(
      color: mergedStyle.color ?? defaultStyle.color ?? Colors.black,
    );
    final spans = _parseSpans(text, effectiveStyle);

    final noMathFound = spans.length == 1 &&
        spans.first is TextSpan &&
        (spans.first as TextSpan).text == text;

    if (noMathFound) {
      return Text(
        text,
        style: effectiveStyle,
      );
    }

    return RichText(
      text: TextSpan(style: effectiveStyle, children: spans),
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
            padding:
                isBlock ? const EdgeInsets.symmetric(vertical: 8) : EdgeInsets.zero,
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
