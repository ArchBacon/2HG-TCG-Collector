// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:convert';

import 'package:app/config/assets.dart';
import 'package:app/domain/models/collection/collection_overview.dart';
import 'package:app/domain/models/collection/collection_summary.dart';
import 'package:app/tmp/shared/models/tcg.dart';
import 'package:flutter/services.dart';

class LocalDataService {
  Future<CollectionSummary> getCollectionSummary() async {
    final json = await _loadStringAsset(Assets.collectionSummary);
    return CollectionSummary.fromJson(json);
  }

  Future<CollectionOverview> getCollectionFor(Tcg tcg) async {
    final json = await _loadStringAsset(Assets.collectionFor(tcg));
    return CollectionOverview.fromJson(json);
  }

  Future<Map<String, dynamic>> _loadStringAsset(String asset) async {
    final localData = await rootBundle.loadString(asset);
    return jsonDecode(localData) as Map<String, dynamic>;
  }
}