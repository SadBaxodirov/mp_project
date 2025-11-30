class OptionModel {
  final int id;
  final String text;
  final bool isCorrect;
  final String? image;

  OptionModel({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.image,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['id'],
      text: json['text'],
      isCorrect: json['is_correct'],
      image: json['image'],
    );
  }
}

class QuestionModel {
  final int id;
  final String questionText;
  final String? image;
  final double score;
  final String questionType;
  final String section;
  final List<OptionModel> options;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.image,
    required this.score,
    required this.questionType,
    required this.section,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'],
      questionText: json['question_text'],
      image: json['image'],
      score: (json['score'] as num).toDouble(),
      questionType: json['question_type'],
      section: json['section'],
      options: (json['options'] as List)
          .map((e) => OptionModel.fromJson(e))
          .toList(),
    );
  }
}
