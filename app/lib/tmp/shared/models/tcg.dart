// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:json_annotation/json_annotation.dart';

/// The supported trading card games. [slug] matches the API's game names and the
/// image file names in assets/tcgs/.
@JsonEnum(valueField: 'slug')
enum Tcg {
  pokemon('Pokémon TCG', 'Pokémon', 'pokemon'),
  mtg('Magic: The Gathering', 'Magic', 'mtg'),
  onePiece('One Piece Card Game', 'One Piece', 'onepiece'),
  lorcana('Disney Lorcana', 'Lorcana', 'lorcana'),
  dragonBallFusion('Dragon Ball Super Fusion World', 'Fusion World', 'dragonballfusion');

  const Tcg(this.displayName, this.shortName, this.slug);

  final String displayName;

  /// For in a sentence, e.g. "Scan a Magic card".
  final String shortName;
  final String slug;

  String get imageAsset => 'assets/tcgs/$slug.webp';
}
