// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_test.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserTest _$UserTestFromJson(Map<String, dynamic> json) => UserTest(
  id: (json['id'] as num?)?.toInt(),
  user: (json['user_id'] as num).toInt(),
  test: (json['test_id'] as num).toInt(),
  exam: json['exam'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  mathScore: (json['math_score'] as num).toDouble(),
  englishScore: (json['english_score'] as num).toDouble(),
);

Map<String, dynamic> _$UserTestToJson(UserTest instance) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.user,
  'test_id': instance.test,
  'exam': instance.exam,
  'created_at': instance.createdAt.toIso8601String(),
  'math_score': instance.mathScore,
  'english_score': instance.englishScore,
};
