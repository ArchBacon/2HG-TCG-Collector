// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE: Collection tab. For one game: value, recently added cards and set progress. With
// "All games" picked: total value and a tile per game (tapping one picks that game).

import 'package:app/tmp/core/utils/format.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/ui/prototype/game_switcher.dart';
import 'package:app/ui/prototype/glass.dart';
import 'package:app/ui/prototype/proto_common.dart';
import 'package:app/ui/prototype/proto_data.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProtoCollectionScreen extends StatelessWidget {
  const ProtoCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: protoGame,
      builder: (context, game, _) => game == null ? const _AllGames() : _Game(game: game),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// One game
// ---------------------------------------------------------------------------------------------

class _Game extends StatelessWidget {
  final Tcg game;

  const _Game({required this.game});

  @override
  Widget build(BuildContext context) {
    final palette = GamePalette.of(game);
    final recent = ProtoData.catalog(game).where((c) => c.owned > 0).take(10).toList();

    return FutureBuilder(
      future: ProtoData.collection(game),
      builder: (context, snapshot) {
        final collection = snapshot.data;
        final sets = collection?.sets ?? const <ProtoSetProgress>[];
        final started = sets.where((s) => s.collected > 0).toList();
        final totalCards = sets.fold(0, (n, s) => n + s.total);

        return ProtoScaffold(
          title: 'Collection',
          game: game,
          children: [
            // Value
            GlassCard(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collection value',
                    style: TextStyle(color: GlassText.secondary, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          formatEuro(collection?.value ?? 0),
                          style: TextStyle(
                            color: GlassText.primary,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GlassChip(
                        icon: LucideIcons.trendingUp,
                        label: '+${((collection?.value ?? 0) * 0.014).toStringAsFixed(2)} this week',
                        color: GlassText.positive,
                        filled: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(child: ProtoStat(value: '${collection?.collected ?? 0}', label: 'Cards')),
                      Expanded(child: ProtoStat(value: '${started.length}', label: 'Sets started')),
                      Expanded(
                        child: ProtoStat(
                          value: totalCards == 0 ? '–' : '${((collection?.collected ?? 0) / totalCards * 100).toStringAsFixed(1)}%',
                          label: 'Complete',
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recently added
            const ProtoHeading('Recently added'),
            SizedBox(
              height: 104 / CardThumb.aspect,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: recent.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => ProtoOverlayThumb(card: recent[i], width: 104),
              ),
            ),
            const SizedBox(height: 24),

            // Sets
            ProtoHeading(
              'Sets',
              trailing: Text(
                '${started.length} of ${sets.length} started',
                style: TextStyle(color: GlassText.tertiary, fontSize: 13),
              ),
            ),
            ProtoListCard(
              rows: [
                for (final set in started.take(8)) _SetRow(set: set, accent: palette.accent),
                _ShowAllRow(label: 'All ${sets.length} sets'),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SetRow extends StatelessWidget {
  final ProtoSetProgress set;
  final Color accent;

  const _SetRow({required this.set, required this.accent});

  @override
  Widget build(BuildContext context) {
    final progress = set.total == 0 ? 0.0 : set.collected / set.total;

    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    set.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: GlassText.primary, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${set.collected}/${set.total}',
                  style: TextStyle(
                    color: GlassText.secondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: accent,
                backgroundColor: GlassColors.current.track,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowAllRow extends StatelessWidget {
  final String label;

  const _ShowAllRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(label, style: TextStyle(color: GlassText.secondary, fontSize: 14, fontWeight: FontWeight.w600))),
            Icon(LucideIcons.chevronRight, size: 18, color: GlassText.tertiary),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------------------------
// All games
// ---------------------------------------------------------------------------------------------

class _AllGames extends StatelessWidget {
  const _AllGames();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ProtoData.allCollections(),
      builder: (context, snapshot) {
        final collections = snapshot.data ?? const <Tcg, ProtoCollection>{};
        final total = collections.values.fold(0.0, (sum, c) => sum + c.value);
        final cards = collections.values.fold(0, (n, c) => n + c.collected);
        final games = collections.entries.toList()..sort((a, b) => b.value.value.compareTo(a.value.value));

        return ProtoScaffold(
          title: 'Collection',
          game: null,
          children: [
            GlassCard(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total collection value',
                    style: TextStyle(color: GlassText.secondary, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatEuro(total),
                    style: TextStyle(
                      color: GlassText.primary,
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$cards cards across ${collections.length} games',
                    style: TextStyle(color: GlassText.secondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ProtoGrid(
              columns: 2,
              children: [
                for (final MapEntry(key: game, value: collection) in games)
                  ProtoGameTile(
                    game: game,
                    stats: [
                      (LucideIcons.layers, '${collection.collected}'),
                      (LucideIcons.euro, collection.value.toStringAsFixed(0)),
                    ],
                    onTap: () => protoGame.value = game,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
