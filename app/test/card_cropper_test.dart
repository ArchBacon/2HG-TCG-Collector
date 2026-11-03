// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:typed_data';

import 'package:app/data/services/scanner/card_cropper.dart';
import 'package:app/data/services/scanner/card_detector.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A camera frame (Android's 3 planes) from a picture drawn upright: turned to the sensor's
/// [rotation], as the camera would deliver it.
YuvFrame _frame(int uprightW, int uprightH, int rotation, (int, int, int) Function(int x, int y) colourAt) {
  final w = rotation % 180 == 0 ? uprightW : uprightH;
  final h = rotation % 180 == 0 ? uprightH : uprightW;
  final y = Uint8List(w * h);
  final u = Uint8List((w ~/ 2) * (h ~/ 2));
  final v = Uint8List((w ~/ 2) * (h ~/ 2));
  for (var fy = 0; fy < h; fy++) {
    for (var fx = 0; fx < w; fx++) {
      // Where this frame pixel is upright (as CardCropper turns it)
      final (ux, uy) = switch (rotation) {
        90 => (h - 1 - fy, fx),
        180 => (w - 1 - fx, h - 1 - fy),
        270 => (fy, w - 1 - fx),
        _ => (fx, fy),
      };
      final (r, g, b) = colourAt(ux, uy);
      final luma = 0.299 * r + 0.587 * g + 0.114 * b;
      y[fy * w + fx] = luma.round().clamp(0, 255);
      if (fx.isEven && fy.isEven) {
        final i = (fy ~/ 2) * (w ~/ 2) + fx ~/ 2;
        u[i] = (128 + (b - luma) / 1.772).round().clamp(0, 255);
        v[i] = (128 + (r - luma) / 1.402).round().clamp(0, 255);
      }
    }
  }
  return YuvFrame(width: w, height: h, y: y, yRowStride: w, u: u, v: v, uvRowStride: w ~/ 2, uvPixelStride: 1);
}

/// The frame point of an upright one (the other way around from the camera turning it).
Corner _toFrame(double ux, double uy, int w, int h, int rotation) => switch (rotation) {
  90 => (x: uy, y: h - ux),
  180 => (x: w - ux, y: h - uy),
  270 => (x: w - uy, y: ux),
  _ => (x: ux, y: uy),
};

void main() {
  // Upright: a card from (120, 100) to (360, 436), red in its top half, blue below, on grey
  (int, int, int) scene(int x, int y) {
    if (x < 120 || x >= 360 || y < 100 || y >= 436) return (90, 90, 90);
    return y < 268 ? (220, 30, 30) : (30, 30, 220);
  }

  for (final rotation in [0, 90, 270]) {
    test('cuts the card out upright, in colour (sensor turned $rotation°)', () {
      final frame = _frame(480, 640, rotation, scene);
      final corners = [
        for (final (x, y) in [(120.0, 100.0), (360.0, 100.0), (360.0, 436.0), (120.0, 436.0)])
          _toFrame(x, y, frame.width, frame.height, rotation),
      ];

      final jpeg = CardCropper.crop(frame, corners, rotation);
      final out = img.decodeJpg(jpeg)!;
      expect((out.width, out.height), (CardCropper.outWidth, CardCropper.outHeight));

      final top = out.getPixel(out.width ~/ 2, out.height ~/ 4);
      final bottom = out.getPixel(out.width ~/ 2, out.height * 3 ~/ 4);
      expect(top.r, greaterThan(150), reason: 'Top should be red: $top');
      expect(top.b, lessThan(90), reason: 'Top should be red: $top');
      expect(bottom.b, greaterThan(150), reason: 'Bottom should be blue: $bottom');
      expect(bottom.r, lessThan(90), reason: 'Bottom should be blue: $bottom');
    });
  }

  test('turns a card held sideways upright', () {
    // Upright on screen it's wider than tall: lying on its side
    (int, int, int) sideways(int x, int y) {
      if (x < 60 || x >= 420 || y < 200 || y >= 460) return (90, 90, 90);
      return (200, 200, 200);
    }

    final frame = _frame(480, 640, 90, sideways);
    final corners = [
      for (final (x, y) in [(60.0, 200.0), (420.0, 200.0), (420.0, 460.0), (60.0, 460.0)])
        _toFrame(x, y, frame.width, frame.height, 90),
    ];

    final out = img.decodeJpg(CardCropper.crop(frame, corners, 90))!;
    expect((out.width, out.height), (CardCropper.outWidth, CardCropper.outHeight));
    // The card fills it (bright), not a strip of it with the background around
    final middle = out.getPixel(out.width ~/ 2, out.height ~/ 2);
    final nearTop = out.getPixel(out.width ~/ 2, out.height ~/ 10);
    expect(middle.r, greaterThan(170));
    expect(nearTop.r, greaterThan(170));
  });
}
