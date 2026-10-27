// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:ui' as ui;

import 'package:app/data/services/local/card_image_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// A card image from the device's [CardImageStore], downloaded and kept there the first time.
@immutable
class StoredCardImage extends ImageProvider<StoredCardImage> {
  final String url;

  const StoredCardImage(this.url);

  @override
  Future<StoredCardImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(StoredCardImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(
        codec: CardImageStore.load(url).then((bytes) async => decode(await ui.ImmutableBuffer.fromUint8List(bytes))),
        scale: 1,
        debugLabel: url,
      );

  @override
  bool operator ==(Object other) => other is StoredCardImage && other.url == url;

  @override
  int get hashCode => url.hashCode;
}
