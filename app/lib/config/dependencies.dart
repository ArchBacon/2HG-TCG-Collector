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
    Provider(
        create: (context) =>
            CollectionRepositoryLocal(localDataService: context.read())
              as CollectionRepository,
    ),
    Provider(
        create: (context) =>
            WishlistRepositoryLocal(localDataService: context.read())
              as WishlistRepository,
    ),
    Provider(
        create: (context) =>
            CatalogRepositoryLocal(localDataService: context.read())
              as CatalogRepository,
    ),
    Provider(
        create: (context) =>
            MarketRepositoryLocal(localDataService: context.read())
              as MarketRepository,
    ),
    // ChangeNotifierProvider: the cart notifies when its lines change (e.g. for the cart button)
    ChangeNotifierProvider(
        create: (context) =>
            CartRepositoryLocal(localDataService: context.read())
              as CartRepository,
    ),
  ];
}

/// Configure dependencies for remote data.
/// This dependency list uses repositories that connect to a remote server.
List<SingleChildWidget> get providersRemote {
  return [
    Provider.value(value: RemoteDataService()),
    Provider(
        create: (context) =>
            CollectionRepositoryRemote(remoteDataService: context.read())
              as CollectionRepository,
    ),
    Provider(
        create: (context) =>
            WishlistRepositoryRemote(remoteDataService: context.read())
              as WishlistRepository,
    ),
    Provider(
        create: (context) =>
            CatalogRepositoryRemote(remoteDataService: context.read())
              as CatalogRepository,
    ),
    Provider(
        create: (context) =>
            MarketRepositoryRemote(remoteDataService: context.read())
              as MarketRepository,
    ),
    ChangeNotifierProvider(
        create: (context) =>
            CartRepositoryRemote(remoteDataService: context.read())
              as CartRepository,
    ),
  ];
}
