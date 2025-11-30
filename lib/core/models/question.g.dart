// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Question _$QuestionFromJson(Map<String, dynamic> json) => Question(
      id: (json['id'] as num?)?.toInt(),
      questionText: json['question_text'] as String,
      score: (json['score'] as num).toDouble(),
      questionType: json['question_type'] as String,
      section: json['section'] as String,
      image: json['image'] as String?,
      options: (json['options'] as List<dynamic>)
          .map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuestionToJson(Question instance) => <String, dynamic>{
      'id': instance.id,
      'question_text': instance.questionText,
      'image': instance.image,
      'score': instance.score,
      'question_type': instance.questionType,
      'section': instance.section,
      'options': instance.options.map((e) => e.toJson()).toList(),
    };
