import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  const User({
    this.id,
    required this.username,
    required this.firstName,
    this.lastName,
    this.school,
    this.grade,
    required this.phoneNumber,
    required this.email
  });

  final int? id;
  final String username;
  final String firstName;
  final String? lastName; // ? means it is nullable
  final String? school;
  final String? grade;
  final String phoneNumber;
  final String email;

  String get displayName => '$firstName ${lastName ?? ''}'.trim();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
