// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tcg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TcgSet _$TcgSetFromJson(Map<String, dynamic> json) => _TcgSet(
  id: json['id'] as String,
  lang: json['lang'] as String?,
  code: json['code'] as String,
  name: json['name'] as String,
  cardCount: (json['cardCount'] as num?)?.toInt(),
  releasedAt: json['releasedAt'] == null
      ? null
      : DateTime.parse(json['releasedAt'] as String),
  images: Map<String, String?>.from(json['images'] as Map),
);

Map<String, dynamic> _$TcgSetToJson(_TcgSet instance) => <String, dynamic>{
  'id': instance.id,
  'lang': instance.lang,
  'code': instance.code,
  'name': instance.name,
  'cardCount': instance.cardCount,
  'releasedAt': instance.releasedAt?.toIso8601String(),
  'images': instance.images,
};
