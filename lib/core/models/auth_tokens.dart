import 'package:json_annotation/json_annotation.dart';

part 'auth_tokens.g.dart';

@JsonSerializable()
class AuthTokens {
  const AuthTokens({
    required this.access,
    required this.refresh,
  });

  final String access;
  final String refresh;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokensToJson(this);
}
