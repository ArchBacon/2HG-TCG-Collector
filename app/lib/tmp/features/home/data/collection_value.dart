// Copyright 2026 Christian Delicaat. All rights reserved.

// import 'dart:convert';
//
// class CollectionValueTotal {
//   final double value;
//   final int collected;
//   final int wishlisted;
//
//   CollectionValueTotal({
//     required this.value,
//     required this.collected,
//     required this.wishlisted
//   });
//
//   factory CollectionValueTotal.fromJson(Map<String, dynamic> json) {
//     return CollectionValueTotal(
//       value: (json['value'] as num).toDouble(),
//       collected: json['collected'] as int,
//       wishlisted: json['wishlisted'] as int,
//     );
//   }
// }
//
// class TcgSet {
//   final String id;
//   final String? lang;
//   final String code;
//   final String name;
//   final int cardCount;
//   final DateTime releasedAt;
//   final Map<String, String> images;
// }
//
// class CollectionTcgSummary {
//   final String name;
//   final double value;
//   final int collected;
//   final int wishlisted;
//   final TcgSet? latestSet;
//
//   CollectionTcgSummary({
//     required this.name,
//     required this.value,
//     required this.collected,
//     required this.wishlisted,
//     this.latestSet,
//   });
//
//   factory CollectionTcgSummary.fromJson(Map<String, dynamic> json) {
//     return CollectionTcgSummary(
//       value: (json['value'] as num).toDouble(),
//       collected: json['collected'] as int,
//       wishlisted: json['wishlisted'] as int,
//     );
//   }
// }
//
// class CollectionSummary {
//   final CollectionValueTotal total;
//   final Map<String, CollectionTcgSummary> tcgs;
//
//   CollectionSummary({
//     required this.total,
//     required this.tcgs,
//   });
//
//   factory CollectionSummary.fromJson(Map<String, dynamic> json) {
//     final total = json['total'] as Map<String, dynamic>;
//
//     return CollectionSummary(
//       total: CollectionValueTotal.fromJson(total),
//       tcgs: {},
//     );
//   }
// }
//
// CollectionSummary parseCollectionValue(String responseBody) {
//   final json = jsonDecode(responseBody) as Map<String, dynamic>;
//   return CollectionSummary.fromJson(json);
// }
