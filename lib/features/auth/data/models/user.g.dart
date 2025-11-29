// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      name: json['name'] as String?,
      username: json['username'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'full_name': instance.fullName,
      'name': instance.name,
      'username': instance.username,
    };
