// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'collection_overview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CollectionOverview _$CollectionOverviewFromJson(Map<String, dynamic> json) =>
    _CollectionOverview(
      summary: CollectionSummaryTcg.fromJson(
        _self(json, 'summary') as Map<String, dynamic>,
      ),
      blocks: (json['blocks'] as List<dynamic>)
          .map(
            (e) => CollectionOverviewBlock.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$CollectionOverviewToJson(_CollectionOverview instance) =>
    <String, dynamic>{'summary': instance.summary, 'blocks': instance.blocks};

_CollectionOverviewBlock _$CollectionOverviewBlockFromJson(
  Map<String, dynamic> json,
) => _CollectionOverviewBlock(
  block: json['block'] as String?,
  sets: (json['sets'] as List<dynamic>)
      .map((e) => CollectionOverviewSet.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CollectionOverviewBlockToJson(
  _CollectionOverviewBlock instance,
) => <String, dynamic>{'block': instance.block, 'sets': instance.sets};

_CollectionOverviewSet _$CollectionOverviewSetFromJson(
  Map<String, dynamic> json,
) => _CollectionOverviewSet(
  set: TcgSet.fromJson(_self(json, 'set') as Map<String, dynamic>),
  collected: (json['collected'] as num).toInt(),
);

Map<String, dynamic> _$CollectionOverviewSetToJson(
  _CollectionOverviewSet instance,
) => <String, dynamic>{'set': instance.set, 'collected': instance.collected};
