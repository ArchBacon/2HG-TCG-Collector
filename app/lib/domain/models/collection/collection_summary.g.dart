// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CollectionSummary _$CollectionSummaryFromJson(
  Map<String, dynamic> json,
) => _CollectionSummary(
  total: CollectionSummaryTotal.fromJson(json['total'] as Map<String, dynamic>),
  tcgs: (json['tcgs'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry(k, CollectionSummaryTcg.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$CollectionSummaryToJson(_CollectionSummary instance) =>
    <String, dynamic>{'total': instance.total, 'tcgs': instance.tcgs};

_CollectionSummaryTotal _$CollectionSummaryTotalFromJson(
  Map<String, dynamic> json,
) => _CollectionSummaryTotal(
  value: (json['value'] as num).toDouble(),
  collected: (json['collected'] as num).toInt(),
  wishlisted: (json['wishlisted'] as num).toInt(),
);

Map<String, dynamic> _$CollectionSummaryTotalToJson(
  _CollectionSummaryTotal instance,
) => <String, dynamic>{
  'value': instance.value,
  'collected': instance.collected,
  'wishlisted': instance.wishlisted,
};

_CollectionSummaryTcg _$CollectionSummaryTcgFromJson(
  Map<String, dynamic> json,
) => _CollectionSummaryTcg(
  tcg: $enumDecode(_$TcgEnumMap, json['tcg']),
  value: (json['value'] as num).toDouble(),
  collected: (json['collected'] as num).toInt(),
  wishlisted: (json['wishlisted'] as num).toInt(),
  latestSet: json['latestSet'] == null
      ? null
      : TcgSet.fromJson(json['latestSet'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CollectionSummaryTcgToJson(
  _CollectionSummaryTcg instance,
) => <String, dynamic>{
  'tcg': _$TcgEnumMap[instance.tcg]!,
  'value': instance.value,
  'collected': instance.collected,
  'wishlisted': instance.wishlisted,
  'latestSet': instance.latestSet,
};

const _$TcgEnumMap = {
  Tcg.pokemon: 'pokemon',
  Tcg.mtg: 'mtg',
  Tcg.onePiece: 'onepiece',
  Tcg.lorcana: 'lorcana',
  Tcg.dragonBallFusion: 'dragonballfusion',
};
