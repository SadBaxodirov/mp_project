class AnswerSummary {
  const AnswerSummary({
    required this.questionId,
    required this.questionText,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.section,
    required this.score,
  });

  final int questionId;
  final String questionText;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String section;
  final double score;
}
