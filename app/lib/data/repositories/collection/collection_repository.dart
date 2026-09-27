// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/collection/collection.dart';

import '../../../utils/result.dart';

abstract class CollectionRepository {
  Future<Result<CollectionSummary>> getCollectionSummary();
}