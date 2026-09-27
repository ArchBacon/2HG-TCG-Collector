// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:convert';

import 'package:app/config/assets.dart';
import 'package:app/domain/models/collection/collection.dart';
import 'package:flutter/services.dart';

class LocalDataService {
  Future<CollectionSummary> getCollectionSummary() async {
    final json = await _loadStringAsset(Assets.collectionSummary);
    return CollectionSummary.fromJson(json);
  }

  Future<Map<String, dynamic>> _loadStringAsset(String asset) async {
    final localData = await rootBundle.loadString(asset);
    return jsonDecode(localData) as Map<String, dynamic>;
  }
}