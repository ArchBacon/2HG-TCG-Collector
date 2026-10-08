// Copyright 2026 Christian Delicaat. All rights reserved.

// Mock data for the screens until there are view models and repositories for them. The wishlist
// comes from assets/data/wishlist.json, collection stats from assets/data/collection/, and the
// catalog is generated. Store availability, prices and owned counts are made up (but stable
// between runs).

import 'dart:convert';
import 'dart:math';

import 'package:app/config/assets.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/collection_stats.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:flutter/services.dart';

abstract final class MockData {
  // Every card handed out, by id, so the card details page can find it.
  static final _byId = <String, TcgCard>{};

  static TcgCard? card(String id) => _byId[id];

  // ---------------------------------------------------------------------------------------------
  // Wishlist
  // ---------------------------------------------------------------------------------------------

  static Future<List<TcgCard>>? _wishlist;

  // Loaded once and shared by all screens.
  static Future<List<TcgCard>> wishlist() => _wishlist ??= _loadWishlist();

  static Future<List<TcgCard>> _loadWishlist() async {
    final json = jsonDecode(await rootBundle.loadString(Assets.wishlist)) as Map<String, dynamic>;
    final tcgs = json['tcgs'] as Map<String, dynamic>;

    return [
      for (final group in tcgs.values)
        for (final entry in (group as Map<String, dynamic>)['entries'] as List)
          _register(_parseWishlistEntry(entry as Map<String, dynamic>)),
    ];
  }

  static TcgCard _parseWishlistEntry(Map<String, dynamic> entry) {
    final card = entry['card'] as Map<String, dynamic>;
    final set = card['set'] as Map<String, dynamic>;
    final id = card['id'] as String;

    // Made-up but stable store state, derived from the card id
    final hash = int.parse(id.substring(id.length - 4), radix: 16);
    final inStore = hash % 3 != 0;

    return TcgCard(
      id: id,
      game: Tcg.values.firstWhere((t) => t.slug == card['tcg']),
      name: card['name'] as String,
      number: card['number'] as String,
      rarity: card['rarity'] as String?,
      setCode: set['code'] as String,
      setName: set['name'] as String,
      quantity: entry['quantity'] as int,
      price: (entry['price'] as num).toDouble(),
      wishlisted: true,
      inStore: inStore,
      isNew: inStore && hash % 2 == 0,
    );
  }

  // ---------------------------------------------------------------------------------------------
  // Catalog (generated)
  // ---------------------------------------------------------------------------------------------

  static final _catalogs = <Tcg, List<TcgCard>>{};

  static List<TcgCard> catalog(Tcg game) => _catalogs[game] ??= _generateCatalog(game);

  static List<TcgCard> _generateCatalog(Tcg game) {
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
          return _register(TcgCard(
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
          ));
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

  static TcgCard _register(TcgCard card) => _byId[card.id] = card;

  // ---------------------------------------------------------------------------------------------
  // Collection
  // ---------------------------------------------------------------------------------------------

  static final _collections = <Tcg, Future<CollectionStats>>{};

  static Future<CollectionStats> collection(Tcg game) => _collections[game] ??= _loadCollection(game);

  static Future<CollectionStats> _loadCollection(Tcg game) async {
    final json = jsonDecode(await rootBundle.loadString(Assets.collectionFor(game))) as Map<String, dynamic>;
    return CollectionStats(
      value: (json['value'] as num).toDouble(),
      collected: json['collected'] as int,
      wishlisted: json['wishlisted'] as int,
      sets: [
        for (final block in json['blocks'] as List)
          for (final set in (block as Map<String, dynamic>)['sets'] as List)
            SetProgress(
              name: (set as Map<String, dynamic>)['name'] as String,
              code: set['code'] as String,
              collected: set['collected'] as int? ?? 0,
              total: set['cardCount'] as int,
            ),
      ],
    );
  }

  static Future<Map<Tcg, CollectionStats>>? _allCollections;

  // Collection stats for every game, for the "All games" overview.
  static Future<Map<Tcg, CollectionStats>> allCollections() => _allCollections ??= () async {
    return {for (final game in Tcg.values) game: await collection(game)};
  }();
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
