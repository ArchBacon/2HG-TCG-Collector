// Copyright 2026 Christian Delicaat. All rights reserved.

/// The supported trading card games. [slug] matches the API's game names and the
/// image file names in assets/tcgs/.
enum Tcg {
  pokemon('Pokémon TCG', 'pokemon'),
  mtg('Magic: The Gathering', 'mtg'),
  onePiece('One Piece Card Game', 'onepiece'),
  lorcana('Disney Lorcana', 'lorcana'),
  dragonBallFusion('Dragon Ball Super Fusion World', 'dragonballfusion');

  const Tcg(this.displayName, this.slug);

  final String displayName;
  final String slug;

  String get imageAsset => 'assets/tcgs/$slug.webp';
}
