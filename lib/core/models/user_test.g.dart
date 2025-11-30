// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_test.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserTest _$UserTestFromJson(Map<String, dynamic> json) => UserTest(
  id: (json['id'] as num?)?.toInt(),
  user: (json['user'] as num).toInt(),
  test: (json['test'] as num).toInt(),
  exam: json['exam'] as bool,
  createdAt: DateTime.parse(json['created_at'] as String),
  mathScore: (json['math_score'] as num).toDouble(),
  englishScore: (json['english_score'] as num).toDouble(),
);

Map<String, dynamic> _$UserTestToJson(UserTest instance) => <String, dynamic>{
  'id': instance.id,
  'user': instance.user,
  'test': instance.test,
  'exam': instance.exam,
  'created_at': instance.createdAt.toIso8601String(),
  'math_score': instance.mathScore,
  'english_score': instance.englishScore,
};
