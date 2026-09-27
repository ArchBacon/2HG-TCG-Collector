// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:freezed_annotation/freezed_annotation.dart';

import '../tcg/tcg.dart';

part 'collection.freezed.dart';
part 'collection.g.dart';

@freezed
abstract class CollectionSummary with _$CollectionSummary {
  const factory CollectionSummary({
    required CollectionSummaryTotal total,
    required Map<String, CollectionSummaryTcg> tcgs,
  }) = _CollectionSummary;

  factory CollectionSummary.fromJson(Map<String, Object?> json) => _$CollectionSummaryFromJson(json);
}

@freezed
abstract class CollectionSummaryTotal with _$CollectionSummaryTotal {
  const factory CollectionSummaryTotal({
    required double value,
    required int collected,
    required int wishlisted,
  }) = _CollectionSummaryTotal;

  factory CollectionSummaryTotal.fromJson(Map<String, Object?> json) => _$CollectionSummaryTotalFromJson(json);
}

@freezed
abstract class CollectionSummaryTcg with _$CollectionSummaryTcg {
  const factory CollectionSummaryTcg({
    required String name,
    required double value,
    required int collected,
    required int wishlisted,
    required TcgSet latestSet,
  }) = _CollectionSummaryTcg;

  factory CollectionSummaryTcg.fromJson(Map<String, Object?> json) =>
      _$CollectionSummaryTcgFromJson(json);
}