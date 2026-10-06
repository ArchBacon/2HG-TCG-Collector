// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/tmp/shared/models/tcg.dart';

import '../../../utils/result.dart';

abstract class CollectionRepository {
  Future<Result<CollectionSummary>> getCollectionSummary();
  Future<Result<CollectionOverview>> getCollectionFor(Tcg tcg);
}