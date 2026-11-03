// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:app/data/services/scanner/card_detector.dart';

/// Runs a [CardDetector] in its own isolate, so detecting on camera frames doesn't stutter the
/// preview. One frame at a time: call [detect] again once the last one answered (frames that come
/// in meanwhile are best skipped, so the border follows the camera without lagging behind).
class CardDetectorWorker {
  CardDetectorWorker._(this._isolate, this._requests, this._responses);

  final Isolate _isolate;
  final SendPort _requests;
  final ReceivePort _responses;
  Completer<CardDetection>? _pending;

  static Future<CardDetectorWorker> spawn() async {
    final responses = ReceivePort();
    final isolate = await Isolate.spawn(_run, responses.sendPort);
    final ready = Completer<SendPort>();

    late final CardDetectorWorker worker;
    responses.listen((message) {
      if (message is SendPort) {
        ready.complete(message);
      } else if (message is CardDetection) {
        final pending = worker._pending;
        worker._pending = null;
        pending?.complete(message);
      }
    });

    worker = CardDetectorWorker._(isolate, await ready.future, responses);
    return worker;
  }

  /// Detects a card in a frame's brightness plane; see [CardDetector.detect].
  Future<CardDetection> detect(Uint8List luma, int width, int height, {required int rowStride, bool withEdges = false}) {
    if (_pending != null) throw StateError('Wait for the last frame before sending the next.');
    final pending = _pending = Completer<CardDetection>();
    _requests.send(_Request(TransferableTypedData.fromList([luma]), width, height, rowStride, withEdges));
    return pending.future;
  }

  void dispose() {
    _isolate.kill(priority: Isolate.immediate);
    _responses.close();
  }

  static void _run(SendPort responses) {
    const detector = CardDetector();
    final requests = ReceivePort();
    responses.send(requests.sendPort);
    requests.listen((message) {
      final request = message as _Request;
      responses.send(detector.detect(
        request.luma.materialize().asUint8List(),
        request.width,
        request.height,
        rowStride: request.rowStride,
        withEdges: request.withEdges,
      ));
    });
  }
}

class _Request {
  final TransferableTypedData luma;
  final int width;
  final int height;
  final int rowStride;
  final bool withEdges;

  const _Request(this.luma, this.width, this.height, this.rowStride, this.withEdges);
}
