// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:app/data/services/scanner/card_detector.dart';
import 'package:image/image.dart' as img;

/// A camera frame in YUV 4:2:0, as the camera plugin delivers it: a brightness plane and 2 colour
/// planes at half the size. On Android the colour planes are separate ([u] and [v]); on iOS they
/// are 1 interleaved plane, given as both with [uvPixelStride] 2 and [v] starting a byte later.
class YuvFrame {
  final int width;
  final int height;
  final Uint8List y;
  final int yRowStride;
  final Uint8List u;
  final Uint8List v;
  final int uvRowStride;
  final int uvPixelStride;
  final int vOffset; // Where [v]'s samples start: 1 in an interleaved plane

  const YuvFrame({
    required this.width,
    required this.height,
    required this.y,
    required this.yRowStride,
    required this.u,
    required this.v,
    required this.uvRowStride,
    required this.uvPixelStride,
    this.vOffset = 0,
  });
}

/// Cuts the card out of a camera frame: straightened, upright, in colour, as a JPEG of
/// [outWidth] × [outHeight] (a card's 63 × 88 mm), to send for recognition.
///
/// Takes the card's corners from the detector, in the frame's pixels, and the camera's
/// [rotation] (the frame is turned that far to stand upright on screen). The card's long side is
/// made the upright one, so a card held sideways comes out upright too, and a small [margin] is
/// added around it, as a corner found a little inside the card would otherwise cut its border.
abstract final class CardCropper {
  static const outWidth = 630;
  static const outHeight = 880;
  static const margin = 0.03; // Of the card's size, each way

  /// Plain Dart and a fair amount of work: run it in an isolate.
  static Uint8List crop(YuvFrame frame, List<Corner> corners, int rotation, {int quality = 90}) {
    // The corners as seen upright, turned the same way as the preview
    final uprightW = rotation % 180 == 0 ? frame.width : frame.height;
    final uprightH = rotation % 180 == 0 ? frame.height : frame.width;
    final upright = [for (final c in corners) _toUpright(c, frame.width, frame.height, rotation)];
    final quad = _withMargin(_portraitOrder(upright), margin);

    // From the output (u, v in 0–1) onto the card's corners in the upright frame
    final map = _Homography.squareTo(quad);

    final out = img.Image(width: outWidth, height: outHeight);
    for (var oy = 0; oy < outHeight; oy++) {
      final v = (oy + 0.5) / outHeight;
      for (var ox = 0; ox < outWidth; ox++) {
        final (ux, uy) = map.apply((ox + 0.5) / outWidth, v);
        if (ux < 0 || uy < 0 || ux >= uprightW || uy >= uprightH) continue; // Off the frame: black
        final (fx, fy) = _fromUpright(ux, uy, frame.width, frame.height, rotation);
        final (r, g, b) = _rgbAt(frame, fx, fy);
        out.setPixelRgb(ox, oy, r, g, b);
      }
    }
    return img.encodeJpg(out, quality: quality);
  }

  /// A frame point as seen upright, after turning by [rotation] (as the scan screen's preview).
  static Corner _toUpright(Corner c, int w, int h, int rotation) => switch (rotation) {
    90 => (x: h - c.y, y: c.x),
    180 => (x: w - c.x, y: h - c.y),
    270 => (x: c.y, y: w - c.x),
    _ => c,
  };

  /// The frame point for an upright one: the other way around.
  static (double, double) _fromUpright(double x, double y, int w, int h, int rotation) => switch (rotation) {
    90 => (y, h - x),
    180 => (w - x, h - y),
    270 => (w - y, x),
    _ => (x, y),
  };

  /// The corners clockwise on screen from the top left, with the long sides upright.
  static List<Corner> _portraitOrder(List<Corner> corners) {
    final cx = corners.map((c) => c.x).reduce((a, b) => a + b) / 4;
    final cy = corners.map((c) => c.y).reduce((a, b) => a + b) / 4;
    // Clockwise on screen: y runs down, so by increasing angle
    final sorted = [...corners]..sort((a, b) => math.atan2(a.y - cy, a.x - cx).compareTo(math.atan2(b.y - cy, b.x - cx)));
    // Start at the top left one
    var start = 0;
    for (var i = 1; i < 4; i++) {
      if (sorted[i].x + sorted[i].y < sorted[start].x + sorted[start].y) start = i;
    }
    var ordered = [for (var i = 0; i < 4; i++) sorted[(start + i) % 4]];
    // Lying sideways (top wider than the side is long): start a corner later, so the long side is
    // the upright one. The card then comes out turned a quarter; Magic Sorter reads it either way.
    if (_distance(ordered[0], ordered[1]) > _distance(ordered[1], ordered[2])) {
      ordered = [ordered[3], ordered[0], ordered[1], ordered[2]];
    }
    return ordered;
  }

  static List<Corner> _withMargin(List<Corner> quad, double margin) {
    final cx = quad.map((c) => c.x).reduce((a, b) => a + b) / 4;
    final cy = quad.map((c) => c.y).reduce((a, b) => a + b) / 4;
    return [for (final c in quad) (x: cx + (c.x - cx) * (1 + 2 * margin), y: cy + (c.y - cy) * (1 + 2 * margin))];
  }

  static double _distance(Corner a, Corner b) => math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

  /// The colour at a frame point: brightness blended between the 4 pixels around it (the card is
  /// enlarged, so this keeps it from looking blocky), colour from the nearest sample.
  static (int, int, int) _rgbAt(YuvFrame f, double x, double y) {
    final x0 = x.floor().clamp(0, f.width - 1);
    final y0 = y.floor().clamp(0, f.height - 1);
    final x1 = math.min(x0 + 1, f.width - 1);
    final y1 = math.min(y0 + 1, f.height - 1);
    final tx = (x - x0).clamp(0.0, 1.0);
    final ty = (y - y0).clamp(0.0, 1.0);
    final top = f.y[y0 * f.yRowStride + x0] * (1 - tx) + f.y[y0 * f.yRowStride + x1] * tx;
    final bottom = f.y[y1 * f.yRowStride + x0] * (1 - tx) + f.y[y1 * f.yRowStride + x1] * tx;
    final luma = top * (1 - ty) + bottom * ty;

    final uv = (y0 >> 1) * f.uvRowStride + (x0 >> 1) * f.uvPixelStride;
    final cb = (uv < f.u.length ? f.u[uv] : 128) - 128;
    final crIndex = uv + f.vOffset;
    final cr = (crIndex < f.v.length ? f.v[crIndex] : 128) - 128;

    // BT.601, full range (as camera frames are)
    int clamp(double value) => value < 0 ? 0 : (value > 255 ? 255 : value.round());
    return (clamp(luma + 1.402 * cr), clamp(luma - 0.344136 * cb - 0.714136 * cr), clamp(luma + 1.772 * cb));
  }
}

/// A perspective mapping from the unit square onto a 4-sided shape (Heckbert's square-to-quad):
/// (0, 0), (1, 0), (1, 1) and (0, 1) go to its corners in order.
class _Homography {
  final double a, b, c, d, e, f, g, h;

  const _Homography(this.a, this.b, this.c, this.d, this.e, this.f, this.g, this.h);

  factory _Homography.squareTo(List<Corner> q) {
    final (x0, y0, x1, y1, x2, y2, x3, y3) = (q[0].x, q[0].y, q[1].x, q[1].y, q[2].x, q[2].y, q[3].x, q[3].y);
    final dx1 = x1 - x2, dx2 = x3 - x2, dx3 = x0 - x1 + x2 - x3;
    final dy1 = y1 - y2, dy2 = y3 - y2, dy3 = y0 - y1 + y2 - y3;
    if (dx3.abs() < 1e-9 && dy3.abs() < 1e-9) {
      // A parallelogram: no perspective
      return _Homography(x1 - x0, x2 - x1, x0, y1 - y0, y2 - y1, y0, 0, 0);
    }
    final det = dx1 * dy2 - dx2 * dy1;
    final g = (dx3 * dy2 - dx2 * dy3) / det;
    final h = (dx1 * dy3 - dx3 * dy1) / det;
    return _Homography(x1 - x0 + g * x1, x3 - x0 + h * x3, x0, y1 - y0 + g * y1, y3 - y0 + h * y3, y0, g, h);
  }

  (double, double) apply(double u, double v) {
    final w = g * u + h * v + 1;
    return ((a * u + b * v + c) / w, (d * u + e * v + f) / w);
  }
}
