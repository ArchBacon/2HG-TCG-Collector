// Copyright 2026 Christian Delicaat. All rights reserved.

// import 'package:app/features/home/providers/collection_summary_card.dart';
// import 'package:app/features/home/widgets/collection_value.dart';
// import 'package:app/features/home/widgets/wishlist_game_list.dart';
// import 'package:app/shared/models/tcg.dart';
// import 'package:app/shared/widgets/glass_app_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// import '../../../core/identity/token.dart';
//
// class Home extends ConsumerWidget {
//   const Home({super.key});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final token = ref.watch(storedTokenProvider);
//     // Null while loading or when the request failed; the card shows zeros until data arrives.
//     final collection = ref.watch(collectionValueProvider).value;
//
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: const GlassAppBar(title: Text('TCG Collector')),
//       // 20px side padding as in the reference; sections are 24px apart.
//       body: ListView(
//         padding: EdgeInsets.fromLTRB(12, GlassAppBar.contentTopPadding(context) + 12, 12, 12),
//         children: [
//           // Total collection value
//           CollectionSummaryCard(
//               value: collection?.value ?? 0,
//               collected: collection?.collected ?? 0,
//               wishlisted: collection?.wishlisted ?? 0
//           ),
//           const SizedBox(height: 12),
//           // TODO: load from the API; sample data for now
//           TcgGameList(
//             games: const [
//               TcgGameSummary(game: Tcg.pokemon, latestSet: '30th Celebration', value: 2485.30, cardCount: 142),
//               TcgGameSummary(game: Tcg.mtg, latestSet: 'The Hobbit', value: 1120.40, cardCount: 84),
//               TcgGameSummary(game: Tcg.onePiece, latestSet: 'THE DOMINANCE OF GOD', value: 410.00, cardCount: 39),
//               TcgGameSummary(game: Tcg.lorcana, latestSet: 'Wilds Unknown', value: 185.00, cardCount: 22),
//               TcgGameSummary(game: Tcg.dragonBallFusion, latestSet: 'Brightness of Hope', value: 95.50, cardCount: 12),
//             ],
//             onSelected: (tcg) => debugPrint('clicked ${tcg.slug}'),
//           ),
//         ],
//       ),
//     );
//   }
// }
