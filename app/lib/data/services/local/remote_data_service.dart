// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:convert';
import 'dart:io';

import 'package:app/config/api.dart';
import 'package:app/domain/models/card/market_info.dart';
import 'package:app/domain/models/card/tcg_card.dart';
import 'package:app/domain/models/catalog/catalog_query.dart';
import 'package:app/domain/models/collection/card_collection.dart';
import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/domain/models/collection/list_kind.dart';
import 'package:app/domain/models/notification/received_notification.dart';
import 'package:app/domain/models/user/sync_code.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:http/http.dart' as http;

/// Data from the API, as the user of [token].
class RemoteDataService {
  RemoteDataService({required this.token});

  /// The user's API token (UserToken), or null when the API couldn't be reached on startup.
  final String? token;

  /// Headers for every API call: the token, so the API knows which user it is.
  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<CollectionSummary> getCollectionSummary() async {
    final json = await _get('/api/users/collection');
    // The API lists the games; the app looks them up by slug
    final tcgs = {for (final tcg in json['tcgs'] as List) (tcg as Map<String, dynamic>)['tcg'] as String: tcg};
    return CollectionSummary.fromJson({...json, 'tcgs': tcgs});
  }

  /// [tcg]'s collection, over all collections or only [collectionId].
  Future<CollectionOverview> getCollectionFor(Tcg tcg, {String? collectionId}) async {
    return CollectionOverview.fromJson(
      await _get('/api/users/collection/${tcg.slug}', {'list': ?collectionId}),
    );
  }

  /// The cards most recently added to [tcg]'s collection (or only [collectionId]), newest first.
  Future<List<TcgCard>> getRecentlyAdded(Tcg tcg, {String? collectionId}) async {
    final json = await _get('/api/users/collection/${tcg.slug}/recent', {'list': ?collectionId});
    return [for (final entry in json['cards'] as List) _parseCard(entry as Map<String, dynamic>)];
  }

  /// The user's lists of [kind], oldest first, with their counts and value for [tcg].
  Future<List<CardCollection>> getLists(ListKind kind, Tcg tcg) async {
    final json = await _get('/api/users/lists', {'type': kind.name, 'game': tcg.slug});
    return [
      for (final list in (json['lists'] as List).cast<Map<String, dynamic>>())
        CardCollection(
          id: list['id'] as String,
          name: list['name'] as String,
          cards: list['cards'] as int,
          copies: list['copies'] as int,
          value: (list['value'] as num).toDouble(),
          previews: [for (final card in list['previews'] as List) _parseCard({'card': card, 'price': 0, 'inStore': false, 'isNew': false})],
        ),
    ];
  }

  /// Makes a list of [kind] with the id [id] (the app's; making it again is harmless).
  Future<CardCollection> createList(ListKind kind, String id, String name) async {
    final json = await _send('POST', '/api/users/lists', {'id': id, 'type': kind.name, 'name': name});
    return CardCollection(id: json!['id'] as String, name: json['name'] as String);
  }

  Future<void> renameList(String id, String name) => _send('PATCH', '/api/users/lists/$id', {'name': name});

  Future<void> deleteList(String id) => _send('DELETE', '/api/users/lists/$id');

  /// Where the user has [card] in their lists of [kind]: copies per list and finish.
  Future<List<CollectionHolding>> getHoldings(ListKind kind, TcgCard card) async {
    final json = await _get('/api/users/cards/${card.id}/lists');
    return [
      for (final row in (json['lists'] as List).cast<Map<String, dynamic>>())
        if (row['type'] == kind.name)
          CollectionHolding(
            listId: row['listId'] as String,
            finish: row['finish'] as String,
            quantity: row['quantity'] as int,
          ),
    ];
  }

  /// Adds [delta] copies of [card] to a collection or wishlist, and returns the copies now in it.
  /// [changeId] makes a retried call count once.
  Future<int> changeQuantity(String listId, TcgCard card, String finish, int delta, {required String changeId}) async {
    final json = await _send('POST', '/api/users/lists/$listId/entries', {
      'changeId': changeId,
      'game': card.game.slug,
      'cardId': card.id,
      'finish': finish,
      'delta': delta,
    });
    return json!['quantity'] as int;
  }

  /// The cards on any of the user's wishlists, of every game.
  Future<List<TcgCard>> getWishlist() async {
    final json = await _get('/api/users/wishlist');
    return [
      for (final group in json['tcgs'] as List)
        for (final entry in (group as Map<String, dynamic>)['entries'] as List)
          _parseCard(entry as Map<String, dynamic>, wishlisted: true),
    ];
  }

  /// One page of [tcg]'s cards that match [query].
  Future<CatalogPage> getCatalogPage(Tcg tcg, CatalogQuery query, int page) async {
    final json = await _get('/api/users/catalog/${tcg.slug}', {...query.toParams(), 'page': '$page'});
    return CatalogPage(
      cards: [for (final entry in json['cards'] as List) _parseCard(entry as Map<String, dynamic>)],
      total: json['total'] as int,
      page: json['page'] as int,
      perPage: json['perPage'] as int,
    );
  }

  /// What [tcg]'s catalog can be filtered on; with [listId], only what's in that list.
  Future<CatalogFilterOptions> getCatalogFilters(Tcg tcg, {String? listId}) async {
    final json = await _get('/api/users/catalog/${tcg.slug}/filters', {'list': ?listId});
    return CatalogFilterOptions(
      sets: [
        for (final set in (json['sets'] as List).cast<Map<String, dynamic>>())
          (code: set['code'] as String, name: set['name'] as String),
      ],
      rarities: (json['rarities'] as List).cast<String>(),
      artists: (json['artists'] as List).cast<String>(),
    );
  }

  /// One card of any game. Throws an [HttpException] when there's no such card.
  Future<TcgCard> getCard(String id) async => _parseCard(await _get('/api/users/cards/$id'));

  Future<MarketInfo> getMarketInfo(TcgCard card) async {
    final json = await _get('/api/users/cards/${card.id}/market');
    return MarketInfo(
      finishes: [for (final finish in (json['finishes'] as List).cast<String>()) CardFinish(finish, _finishLabel(finish))],
      change7d: (json['change7d'] as num).toDouble(),
      history: [for (final price in json['history'] as List) (price as num).toDouble()],
      have: json['have'] as int,
      want: json['want'] as int,
      listings: [
        for (final listing in (json['listings'] as List).cast<Map<String, dynamic>>())
          StoreListing(
            productId: listing['productId'] as String,
            finish: _finishLabel(listing['finish'] as String),
            condition: listing['condition'] as String,
            price: (listing['price'] as num).toDouble(),
            stock: listing['stock'] as int,
          ),
      ],
    );
  }

  /// A new code to continue as this user on another device.
  Future<SyncCode> createSyncCode() async {
    final json = await _post('/api/users/sync-codes');
    return SyncCode(code: json['code'] as String, expiresAt: DateTime.parse(json['expiresAt'] as String));
  }

  /// Redeems another device's sync code, and returns the token to continue as its user with. Throws
  /// a [RedeemSyncCodeException] when the API turns it down, an [HttpException] for other errors.
  Future<String> redeemSyncCode(String code) async {
    final uri = Uri.parse('${Api.baseUrl}/api/users/sync-codes/redeem');
    final response = await http
        .post(uri, headers: {..._headers, 'Content-Type': 'application/json'}, body: jsonEncode({'code': code}))
        .timeout(const Duration(seconds: 10));
    final failure = switch (response.statusCode) {
      200 => null,
      404 => RedeemFailure.invalidCode,
      422 => RedeemFailure.ownCode,
      429 => RedeemFailure.tooManyAttempts,
      _ => throw HttpException('POST ${uri.path} failed with status ${response.statusCode}', uri: uri),
    };
    if (failure != null) throw RedeemSyncCodeException(failure);
    return (jsonDecode(response.body) as Map<String, dynamic>)['token'] as String;
  }

  /// A card entry from the API: `{card: {...}, price, inStore, isNew}` plus the user's state for
  /// it, where the endpoint has it (`owned`, `wishlisted`, `quantity`).
  TcgCard _parseCard(Map<String, dynamic> entry, {bool wishlisted = false}) {
    final card = entry['card'] as Map<String, dynamic>;
    final set = card['set'] as Map<String, dynamic>;
    final images = card['images'] as Map<String, dynamic>; // Paths on the API
    String? url(String size) => images[size] == null ? null : '${Api.baseUrl}${images[size]}';
    return TcgCard(
      id: card['id'] as String,
      game: Tcg.values.firstWhere((t) => t.slug == card['tcg']),
      name: card['name'] as String,
      number: card['number'] as String,
      rarity: card['rarity'] as String?,
      artist: card['artist'] as String?,
      lang: card['lang'] as String?,
      setCode: set['code'] as String,
      setName: set['name'] as String,
      imageUrl: url('small'),
      mediumImageUrl: url('medium'),
      quantity: entry['quantity'] as int? ?? 1,
      price: (entry['price'] as num).toDouble(),
      owned: entry['owned'] as int? ?? 0,
      wishlisted: entry['wishlisted'] as bool? ?? wishlisted,
      inStore: entry['inStore'] as bool,
      isNew: entry['isNew'] as bool,
    );
  }

  /// Registers this device for push notifications by its Firebase Installation ID [fid], or
  /// updates it: the [platform] (`android` or `ios`), and whether it wants wishlist notifications
  /// and the shop's announcements.
  Future<void> registerDevice(
    String fid, {
    required String platform,
    required bool wishlistInStore,
    required bool announcements,
  }) => _send('PUT', '/api/users/devices', {
    'token': fid,
    'platform': platform,
    'wishlistInStore': wishlistInStore,
    'announcements': announcements,
  });

  /// The notifications the device with Firebase Installation ID [fid] received, and how many are
  /// unread.
  Future<ReceivedNotifications> getReceivedNotifications(String fid) async {
    final json = await _get('/api/users/devices/notifications', {'token': fid});
    return ReceivedNotifications(
      unread: json['unread'] as int,
      notifications: [
        for (final n in (json['notifications'] as List).cast<Map<String, dynamic>>()) ReceivedNotification.fromJson(n),
      ],
    );
  }

  /// Marks all notifications of the device with Firebase Installation ID [fid] read.
  Future<void> markNotificationsRead(String fid) => _send('POST', '/api/users/devices/notifications/read', {'token': fid});

  /// The API's finish names (e.g. `nonfoil`, or Pokémon's `reverse`) as the screens show them.
  static String _finishLabel(String finish) => switch (finish) {
    'nonfoil' => 'Normal',
    'reverse' => 'Reverse Holo',
    'firstEdition' => '1st Edition',
    'wPromo' => 'W Promo',
    _ => finish.isEmpty ? finish : finish[0].toUpperCase() + finish.substring(1),
  };

  /// POSTs to [path] on the API as the user, and returns the JSON body. Throws an [HttpException]
  /// for anything but a 200 or 201.
  Future<Map<String, dynamic>> _post(String path) async {
    final uri = Uri.parse('${Api.baseUrl}$path');
    final response = await http.post(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw HttpException('POST $path failed with status ${response.statusCode}', uri: uri);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Sends a [method] request with the JSON [body] to [path] as the user, and returns the JSON body
  /// (null when there is none). Throws an [HttpException] for anything but a 2xx.
  Future<Map<String, dynamic>?> _send(String method, String path, [Map<String, Object?>? body]) async {
    final uri = Uri.parse('${Api.baseUrl}$path');
    final request = http.Request(method, uri)..headers.addAll({..._headers, 'Content-Type': 'application/json'});
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(await request.send().timeout(const Duration(seconds: 10)));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('$method $path failed with status ${response.statusCode}', uri: uri);
    }
    return response.body.isEmpty ? null : jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GETs [path] from the API as the user, with the query [params], and returns the JSON body.
  /// Throws an [HttpException] for anything but a 200.
  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? params]) async {
    final uri = Uri.parse('${Api.baseUrl}$path').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw HttpException('GET $path failed with status ${response.statusCode}', uri: uri);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
