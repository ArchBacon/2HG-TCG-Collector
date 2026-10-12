// Copyright 2026 Christian Delicaat. All rights reserved.

// The local catalog: there's no card data in the app, so it's generated. 48 cards per game (3 sets
// of 16), with made-up rarities, prices, owned counts and store state. Stable between runs (fixed
// random seed per game).

import 'dart:math';

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/tmp/shared/models/tcg.dart';

abstract final class LocalCatalog {
  static final _catalogs = <Tcg, List<TcgCard>>{};

  /// The catalog of [game]; generated once, then the same list every time.
  static List<TcgCard> catalog(Tcg game) => _catalogs[game] ??= _generate(game);

  static List<TcgCard> _generate(Tcg game) {
    final spec = _specs[game]!;
    final random = Random(game.index * 1000 + 7);
    const perSet = 16;

    return [
      for (var i = 0; i < spec.sets.length * perSet; i++)
        () {
          final (setCode, setName, setSize) = spec.sets[i ~/ perSet];
          final numberInSet = 1 + (i % perSet) * (setSize ~/ perSet) + random.nextInt(3);
          final rarityIndex = _weightedRarity(random, spec.rarities.length);
          final inStore = random.nextDouble() < 0.6;
          return TcgCard(
            id: '${game.slug}-$i',
            game: game,
            name: spec.names[(i * 7) % spec.names.length],
            number: spec.number(setCode, numberInSet, setSize),
            rarity: spec.rarities[rarityIndex],
            setCode: setCode,
            setName: setName,
            price: _price(random, rarityIndex),
            owned: random.nextDouble() < 0.4 ? 1 + random.nextInt(3) : 0,
            wishlisted: random.nextDouble() < 0.15,
            inStore: inStore,
            isNew: inStore && random.nextDouble() < 0.15,
          );
        }(),
    ];
  }

  // Low rarities are much more common.
  static int _weightedRarity(Random random, int count) {
    final roll = random.nextDouble();
    return min(count - 1, (pow(roll, 2.2) * count).floor());
  }

  static double _price(Random random, int rarityIndex) {
    const base = [0.15, 0.4, 1.8, 7.5, 24.0, 85.0];
    final price = base[min(rarityIndex, base.length - 1)] * (0.6 + random.nextDouble() * 1.4);
    return (price * 100).roundToDouble() / 100;
  }
}

// ---------------------------------------------------------------------------------------------
// What the generated catalog looks like per game
// ---------------------------------------------------------------------------------------------

class _CatalogSpec {
  final List<(String code, String name, int size)> sets;
  final List<String> names;
  final List<String> rarities;
  final String Function(String setCode, int n, int setSize) number;

  const _CatalogSpec({required this.sets, required this.names, required this.rarities, required this.number});
}

String _pad(int n, int width) => n.toString().padLeft(width, '0');

final _specs = <Tcg, _CatalogSpec>{
  Tcg.pokemon: _CatalogSpec(
    sets: const [('me02', 'Phantasmal Flames', 130), ('me01', 'Mega Evolution', 188), ('sv10', 'Destined Rivals', 244)],
    names: const [
      'Pikachu ex', 'Charizard ex', 'Umbreon ex', 'Sylveon ex', 'Eevee', 'Mega Gardevoir ex', 'Mewtwo ex', 'Gengar',
      'Lucario', 'Snorlax', 'Dragonite', 'Greninja ex', 'Rayquaza', 'Mimikyu', 'Bulbasaur', 'Squirtle', 'Charmander',
      'Jigglypuff',
    ],
    rarities: const ['Common', 'Uncommon', 'Rare', 'Double Rare', 'Illustration Rare', 'Special Illustration Rare'],
    number: (code, n, size) => '${_pad(n, 3)}/${_pad(size, 3)}',
  ),
  Tcg.mtg: _CatalogSpec(
    sets: const [('tla', 'Avatar: The Last Airbender', 286), ('spm', "Marvel's Spider-Man", 286), ('eoe', 'Edge of Eternities', 276)],
    names: const [
      'Aang, Airbending Master', 'Zuko, Exiled Prince', 'Katara, Waterbender', 'Toph, Earth Rumbler', 'Iroh, Tea Master',
      'Appa, Sky Bison', 'Sokka, Boomerang Hero', 'Azula, Firebender', 'Lightning Bolt', 'Counterspell', 'Sol Ring',
      'Llanowar Elves', 'Swords to Plowshares', 'Spider-Man, Web-Slinger', 'Miles Morales', 'Doctor Octopus',
    ],
    rarities: const ['Common', 'Uncommon', 'Rare', 'Mythic Rare'],
    number: (code, n, size) => '$n',
  ),
  Tcg.onePiece: _CatalogSpec(
    sets: const [('OP-17', "The World's Strongest Warriors", 169), ('OP-16', 'The Time of Battle', 170), ('OP-13', 'Carrying On His Will', 174)],
    names: const [
      'Monkey.D.Luffy', 'Roronoa Zoro', 'Nami', 'Usopp', 'Sanji', 'Tony Tony.Chopper', 'Nico Robin', 'Franky', 'Brook',
      'Jinbe', 'Portgas.D.Ace', 'Shanks', 'Trafalgar Law', 'Boa Hancock', 'Yamato', 'Kaido',
    ],
    rarities: const ['Common', 'Uncommon', 'Rare', 'Super Rare', 'Secret Rare', 'Leader'],
    number: (code, n, size) => '${code.replaceAll('-', '')}-${_pad(n, 3)}',
  ),
  Tcg.lorcana: _CatalogSpec(
    sets: const [('aov', 'Attack of the Vine!', 207), ('wun', 'Wilds Unknown', 204), ('win', 'Winterspell', 204)],
    names: const [
      'Elsa - Ice Maker', 'Mickey Mouse - Brave Tailor', 'Stitch - Carefree Surfer', 'Maleficent - Monstrous Dragon',
      'Ariel - Spectacular Singer', 'Tinker Bell - Garden Guardian', 'Genie - Powers Unleashed', 'Moana - Of Motunui',
      'Simba - Rightful Heir', 'Belle - Strange but Special', 'Hades - Lord of the Underworld', 'Rapunzel - Gifted with Healing',
    ],
    rarities: const ['Common', 'Uncommon', 'Rare', 'Super Rare', 'Legendary', 'Enchanted'],
    number: (code, n, size) => '$n/$size',
  ),
  Tcg.dragonBallFusion: _CatalogSpec(
    sets: const [('fb06', 'Rivals Clash', 143), ('sb01', 'Manga Booster 01', 177), ('fb05', 'New Adventure', 150)],
    names: const [
      'Son Goku', 'Vegeta', 'Son Gohan', 'Piccolo', 'Frieza', 'Trunks', 'Broly', 'Gogeta', 'Vegito', 'Beerus', 'Whis',
      'Android 18',
    ],
    rarities: const ['Common', 'Uncommon', 'Rare', 'Super Rare', 'Secret Rare'],
    number: (code, n, size) => '${code.toUpperCase()}-${_pad(n, 3)}',
  ),
};
