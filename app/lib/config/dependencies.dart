// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/cart/cart_repository.dart';
import 'package:app/data/repositories/cart/cart_repository_local.dart';
import 'package:app/data/repositories/cart/cart_repository_remote.dart';
import 'package:app/data/repositories/catalog/catalog_repository.dart';
import 'package:app/data/repositories/catalog/catalog_repository_local.dart';
import 'package:app/data/repositories/catalog/catalog_repository_remote.dart';
import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/repositories/collection/collection_repository_local.dart';
import 'package:app/data/repositories/collection/collection_repository_remote.dart';
import 'package:app/data/repositories/market/market_repository.dart';
import 'package:app/data/repositories/market/market_repository_local.dart';
import 'package:app/data/repositories/market/market_repository_remote.dart';
import 'package:app/data/repositories/notifications/notifications_repository.dart';
import 'package:app/data/repositories/notifications/notifications_repository_local.dart';
import 'package:app/data/repositories/notifications/notifications_repository_remote.dart';
import 'package:app/data/repositories/sync/sync_repository.dart';
import 'package:app/data/repositories/sync/sync_repository_local.dart';
import 'package:app/data/repositories/sync/sync_repository_remote.dart';
import 'package:app/data/repositories/wishlist/wishlist_repository.dart';
import 'package:app/data/repositories/wishlist/wishlist_repository_local.dart';
import 'package:app/data/repositories/wishlist/wishlist_repository_remote.dart';
import 'package:app/data/services/local/local_data_service.dart';
import 'package:app/data/services/local/remote_data_service.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

/// Configure dependencies for local data.
/// This dependency list uses repositories that provide local data.
/// The user is always logged in.
List<SingleChildWidget> get providersLocal {
  return [
    Provider.value(value: LocalDataService()),
    // ChangeNotifierProvider: collections notify when they change, so their pages reload
    ChangeNotifierProvider(
        create: (context) =>
            CollectionRepositoryLocal(localDataService: context.read())
              as CollectionRepository,
    ),
    ChangeNotifierProvider(
        create: (context) =>
            WishlistRepositoryLocal() as WishlistRepository,
    ),
    Provider(
        create: (context) =>
            CatalogRepositoryLocal(
              localDataService: context.read(),
              collectionRepository: context.read<CollectionRepository>() as CollectionRepositoryLocal,
              wishlistRepository: context.read<WishlistRepository>() as WishlistRepositoryLocal,
            ) as CatalogRepository,
    ),
    Provider(
        create: (context) =>
            MarketRepositoryLocal(localDataService: context.read())
              as MarketRepository,
    ),
    Provider(
        create: (context) =>
            SyncRepositoryLocal(localDataService: context.read())
              as SyncRepository,
    ),
    // ChangeNotifierProvider: the cart notifies when its lines change (e.g. for the cart button)
    ChangeNotifierProvider(
        create: (context) =>
            CartRepositoryLocal(localDataService: context.read())
              as CartRepository,
    ),
    Provider(create: (context) => NotificationsRepositoryLocal() as NotificationsRepository),
  ];
}

/// Configure dependencies for remote data.
/// This dependency list uses repositories that connect to a remote server, as the user [token].
List<SingleChildWidget> providersRemote({required String? token}) {
  return [
    Provider.value(value: RemoteDataService(token: token)),
    ChangeNotifierProvider(
        create: (context) =>
            CollectionRepositoryRemote(remoteDataService: context.read())
              as CollectionRepository,
    ),
    ChangeNotifierProvider(
        create: (context) =>
            WishlistRepositoryRemote(remoteDataService: context.read())
              as WishlistRepository,
    ),
    Provider(
        create: (context) =>
            CatalogRepositoryRemote(
              remoteDataService: context.read(),
              collectionRepository: context.read(),
              wishlistRepository: context.read(),
            ) as CatalogRepository,
    ),
    Provider(
        create: (context) =>
            MarketRepositoryRemote(remoteDataService: context.read())
              as MarketRepository,
    ),
    Provider(
        create: (context) =>
            SyncRepositoryRemote(remoteDataService: context.read())
              as SyncRepository,
    ),
    // App-only: the cart isn't stored on the server
    ChangeNotifierProvider(create: (context) => CartRepositoryRemote() as CartRepository),
    Provider(
        create: (context) =>
            NotificationsRepositoryRemote(remoteDataService: context.read())
              as NotificationsRepository,
    ),
  ];
}
