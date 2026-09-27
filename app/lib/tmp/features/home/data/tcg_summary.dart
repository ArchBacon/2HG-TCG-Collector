// Copyright 2026 Christian Delicaat. All rights reserved.

// import 'dart:convert';
//
// class TcgSummary {
//   final String name;
//   final double value;
//   final int collected;
//   final int wishlisted;
//
//   TcgSummary({
//     required this.name,
//     required this.value,
//     required this.collected,
//     required this.wishlisted
//   });
//
//   factory TcgSummary.fromJson(Map<String, dynamic> json) {
//     return TcgSummary(
//         name: json['tcg'],
//         value: (json['value'] as num).toDouble(),
//         collected: json['collected'] as int,
//         wishlisted: json['wishlisted'] as int,
//     );
//   }
// }
//
// TcgSummary parseTcgSummary(String responseBody) {
//   final json = jsonDecode(responseBody) as Map<String, dynamic>;
//   return TcgSummary.fromJson(json);
// }