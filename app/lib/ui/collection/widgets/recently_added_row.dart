// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/ui/shared/glass/card_thumb.dart';
import 'package:app/ui/shared/glass/layout.dart';
import 'package:flutter/material.dart';

/// "Recently added" heading with the last cards added to the collection, scrolling sideways.
class RecentlyAddedRow extends StatelessWidget {
  final List<TcgCard> cards;

  const RecentlyAddedRow({super.key, required this.cards});

  static const _thumbWidth = 104.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeading('Recently added'),
        SizedBox(
          height: _thumbWidth / CardThumb.aspect,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none, // Runs past the page padding, to the screen edges
            itemCount: cards.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) => CardOverlayThumb(card: cards[i], width: _thumbWidth),
          ),
        ),
      ],
    );
  }
}
