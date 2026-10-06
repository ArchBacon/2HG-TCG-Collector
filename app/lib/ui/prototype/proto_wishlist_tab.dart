// Copyright 2026 Christian Delicaat. All rights reserved.

// PROTOTYPE: Wishlist tab. Prototype A for one game, prototype C with "All games" picked.

import 'package:app/ui/prototype/game_switcher.dart';
import 'package:app/ui/prototype/proto_all_games_screen.dart';
import 'package:app/ui/prototype/proto_mesh_screen.dart';
import 'package:flutter/material.dart';

class ProtoWishlistTab extends StatelessWidget {
  const ProtoWishlistTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: protoGame,
      builder: (context, game, _) => game == null ? const ProtoAllGamesScreen() : const ProtoMeshScreen(),
    );
  }
}
