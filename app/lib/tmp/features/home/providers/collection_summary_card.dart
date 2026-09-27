// Copyright 2026 Christian Delicaat. All rights reserved.

// import 'package:app/core/config/env.dart';
// import 'package:app/features/home/data/collection_value.dart';
// import 'package:app/features/home/data/tcg_summary.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:http/http.dart' as http;
//
// import '../../../core/identity/token.dart';
//
// /// The user's overall collection totals from the API. Refresh with `ref.invalidate(collectionValueProvider)`.
// final collectionValueProvider = FutureProvider<CollectionSummary>(
//   (ref) => CollectionProvider().fetchCollectionValue(),
// );
//
// final tcgSummaryProvider = FutureProvider<TcgSummary>(
//   (ref, String tcg) => TcgSummaryProvider().fetchCollectionValue(tcg),
// );
//
// class CollectionProvider {
//   Future<CollectionSummary> fetchCollectionValue() async {
//     final stored = await getStoredToken();
//
//     final response = await http.get(
//       Uri.parse('${Env.apiBaseUrl}/api/users/collection'),
//       headers: {
//         'Authorization': 'Bearer $stored',
//         'Accept': 'application/json',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       return parseCollectionValue(response.body);
//     } else {
//       throw Exception('Failed to load collection value.');
//     }
//   }
// }
//
// class TcgSummaryProvider {
//   Future<TcgSummary> fetchCollectionValue(String tcg) async {
//     final stored = await getStoredToken();
//
//     final response = await http.get(
//       Uri.parse('${Env.apiBaseUrl}/api/users/collection/$tcg'),
//       headers: {
//         'Authorization': 'Bearer $stored',
//         'Accept': 'application/json',
//       },
//     );
//
//     if (response.statusCode == 200) {
//       return parseTcgSummary(response.body);
//     } else {
//       throw Exception('Failed to load collection value.');
//     }
//   }
// }