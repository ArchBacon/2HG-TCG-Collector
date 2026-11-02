// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:app/utils/result.dart';
import 'package:app/utils/uuid.dart';

/// Lists of one kind in memory, for while the app runs: what the local collection and wishlist
/// repositories share. Starts with one list, [firstId]. Calls [onChange] after every change.
class LocalLists {
  LocalLists({required this.firstId, required String firstName, required this.onChange}) {
    _names[firstId] = firstName;
  }

  final String firstId;
  final void Function() onChange;

  static const _previewCount = 3;

  final _names = <String, String>{}; // In the order they were made
  final _entries = <_Entry>[]; // Oldest first

  /// Puts [quantity] copies of [card] in [finish] in the first list, without telling anyone. To fill
  /// it at the start.
  void seed(TcgCard card, String finish, int quantity) => _entries.add(_Entry(firstId, card, finish, quantity));

  bool has(String listId) => _names.containsKey(listId);

  Result<List<CardCollection>> getLists(Tcg tcg) => Result.ok([
    for (final MapEntry(key: id, value: name) in _names.entries) _list(id, name, tcg),
  ]);

  CardCollection _list(String id, String name, Tcg tcg) {
    final entries = _entries.where((e) => e.listId == id && e.card.game == tcg).toList();
    final cards = [for (final (card, _) in cardsIn(tcg, listId: id)) card];
    return CardCollection(
      id: id,
      name: name,
      cards: cards.length,
      copies: entries.fold(0, (n, e) => n + e.quantity),
      value: entries.fold(0.0, (sum, e) => sum + (e.card.inStore ? e.card.price * e.quantity : 0)),
      previews: cards.take(_previewCount).toList(),
    );
  }

  Result<CardCollection> createList(String name) {
    final id = uuidV4();
    _names[id] = name;
    onChange();
    return Result.ok(CardCollection(id: id, name: name));
  }

  Result<void> renameList(String listId, String name) {
    if (!has(listId)) return Result.error(Exception('No list $listId'));
    _names[listId] = name;
    onChange();
    return const Result.ok(null);
  }

  Result<void> deleteList(String listId) {
    _names.remove(listId);
    _entries.removeWhere((e) => e.listId == listId);
    onChange();
    return const Result.ok(null);
  }

  Result<List<CollectionHolding>> getHoldings(TcgCard card) => Result.ok([
    for (final id in _names.keys)
      for (final entry in _entries.where((e) => e.listId == id && e.card.id == card.id))
        CollectionHolding(listId: id, finish: entry.finish, quantity: entry.quantity),
  ]);

  Result<int> changeQuantity(String listId, TcgCard card, String finish, int delta) {
    if (!has(listId)) return Result.error(Exception('No list $listId'));

    final index = _entries.indexWhere((e) => e.listId == listId && e.card.id == card.id && e.finish == finish);
    final quantity = ((index < 0 ? 0 : _entries[index].quantity) + delta).clamp(0, 1 << 31);
    if (index >= 0) _entries.removeAt(index);
    if (quantity > 0) _entries.add(_Entry(listId, card, finish, quantity)); // Newest last
    onChange();
    return Result.ok(quantity);
  }

  /// [tcg]'s cards in a list (or in any, without [listId]), newest first, each once with its copies
  /// over finishes.
  List<(TcgCard, int)> cardsIn(Tcg tcg, {String? listId}) {
    final copies = <String, int>{};
    final cards = <String, TcgCard>{};
    for (final entry in _entries.reversed.where((e) => e.card.game == tcg && (listId == null || e.listId == listId))) {
      copies[entry.card.id] = (copies[entry.card.id] ?? 0) + entry.quantity;
      cards.putIfAbsent(entry.card.id, () => entry.card);
    }
    return [for (final card in cards.values) (card, copies[card.id]!)];
  }
}

/// Copies of a card in one finish in one list.
class _Entry {
  final String listId;
  final TcgCard card;
  final String finish;
  final int quantity;

  const _Entry(this.listId, this.card, this.finish, this.quantity);
}
