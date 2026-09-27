// Copyright 2026 Christian Delicaat. All rights reserved.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'tcg.freezed.dart';
part 'tcg.g.dart';

@freezed
abstract class TcgSet with _$TcgSet {
  const factory TcgSet({
    required String id,
    required String? lang,
    required String code,
    required String name,
    required int cardCount,
    required DateTime releasedAt,
    required Map<String, String?> images,
  }) = _TcgSet;

  factory TcgSet.fromJson(Map<String, Object?> json) =>
      _$TcgSetFromJson(json);
}