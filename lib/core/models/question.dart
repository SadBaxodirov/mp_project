import 'package:json_annotation/json_annotation.dart';
import 'question_option.dart';

part 'question.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Question {
  const Question({
    this.id,
    required this.questionText,
    required this.score,
    required this.questionType,
    required this.section,
    this.image,
    required this.options,
  });

  final int? id;
  final String questionText;
  final String? image;
  final double score;
  final String questionType;
  final String section;
  final List<QuestionOption> options;

  factory Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionToJson(this);
}
