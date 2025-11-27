import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  const User({
    required this.id,
    required this.email,
    this.fullName,
    this.name,
    this.username,
  });

  final int id;
  final String email;

  @JsonKey(name: 'full_name')
  final String? fullName;

  final String? name;

  final String? username;

  String get displayName => fullName ?? name ?? username ?? email;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
