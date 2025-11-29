import 'package:json_annotation/json_annotation.dart';

part 'question_option.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class QuestionOption {
  const QuestionOption({
    required this.id,
    required this.text,
    required this.isCorrect,
    this.image,
  });

  final int id;
  final String text;
  final bool isCorrect;
  final String? image;

  factory QuestionOption.fromJson(Map<String, dynamic> json) => _$QuestionOptionFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionOptionToJson(this);
}
