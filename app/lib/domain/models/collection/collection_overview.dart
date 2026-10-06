// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../tcg/tcg.dart';

part 'collection_overview.freezed.dart';
part 'collection_overview.g.dart';

/// Hands a nested field the whole object, for when the JSON has its fields inlined.
Object? _self(Map json, String key) => json;

@freezed
abstract class CollectionOverview with _$CollectionOverview {
  const factory CollectionOverview({
    @JsonKey(readValue: _self) required CollectionSummaryTcg summary,
    required List<CollectionOverviewBlock> blocks,
  }) = _CollectionOverview;

  factory CollectionOverview.fromJson(Map<String, Object?> json) =>
    _$CollectionOverviewFromJson(json);
}

@freezed
abstract class CollectionOverviewBlock with _$CollectionOverviewBlock {
  const factory CollectionOverviewBlock({
    required String? block,
    required List<CollectionOverviewSet> sets,
  }) = _CollectionOverviewBlock;

  factory CollectionOverviewBlock.fromJson(Map<String, Object?> json) =>
      _$CollectionOverviewBlockFromJson(json);
}

@freezed
abstract class CollectionOverviewSet with _$CollectionOverviewSet {
  const factory CollectionOverviewSet({
    @JsonKey(readValue: _self) required TcgSet set,
    required int collected,
  }) = _CollectionOverviewSet;

  factory CollectionOverviewSet.fromJson(Map<String, Object?> json) =>
      _$CollectionOverviewSetFromJson(json);
}