// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/data/repositories/collection/collection_repository.dart';
import 'package:app/data/repositories/collection/collection_repository_local.dart';
import 'package:app/data/repositories/collection/collection_repository_remote.dart';
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
  ];
}