import 'package:json_annotation/json_annotation.dart';

part 'user_test.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class UserTest {
  const UserTest({
    this.id,
    required this.user,       // user id
    required this.test,       // test id
    required this.exam,
    required this.createdAt,
    required this.mathScore,
    required this.englishScore,
  });

  final int? id;
  final int user;
  final int test;
  final bool exam;
  final DateTime createdAt;
  final double mathScore;
  final double englishScore;

  factory UserTest.fromJson(Map<String, dynamic> json) =>
      _$UserTestFromJson(json);

  Map<String, dynamic> toJson() => _$UserTestToJson(this);
}
