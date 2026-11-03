// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:app/data/services/scanner/card_detector.dart';
import 'package:flutter_test/flutter_test.dart';

/// A camera-like brightness frame: a noisy background, with polygons painted on it.
class _Frame {
  final int width;
  final int height;
  final int stride;
  late final Uint8List pixels;

  _Frame(this.width, this.height, {int? stride, int background = 50, int seed = 1}) : stride = stride ?? width {
    final random = math.Random(seed);
    pixels = Uint8List(this.stride * height);
    for (var i = 0; i < pixels.length; i++) {
      pixels[i] = (background + random.nextInt(21) - 10).clamp(0, 255);
    }
  }

  void fill(List<Corner> polygon, int brightness) {
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        if (_inside(polygon, x + 0.5, y + 0.5)) pixels[y * stride + x] = brightness;
      }
    }
  }

  static bool _inside(List<Corner> polygon, double x, double y) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final a = polygon[i];
      final b = polygon[j];
      if ((a.y > y) != (b.y > y) && x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x) inside = !inside;
    }
    return inside;
  }
}

/// A card's corners: [width] × [width] · 88/63 around ([cx], [cy]), turned by [degrees].
List<Corner> _card(double cx, double cy, double width, double degrees, {double ratio = CardDetector.cardRatio}) {
  final height = width * ratio;
  final a = degrees * math.pi / 180;
  return [
    for (final (dx, dy) in [(-1, -1), (1, -1), (1, 1), (-1, 1)])
      (
        x: cx + dx * width / 2 * math.cos(a) - dy * height / 2 * math.sin(a),
        y: cy + dx * width / 2 * math.sin(a) + dy * height / 2 * math.cos(a),
      ),
  ];
}

/// Every true corner has a found corner within [tolerance] pixels.
void _expectCorners(List<Corner>? found, List<Corner> truth, {double tolerance = 8}) {
  expect(found, isNotNull, reason: 'No card found');
  for (final t in truth) {
    final nearest = found!.map((f) => math.sqrt(math.pow(f.x - t.x, 2) + math.pow(f.y - t.y, 2))).reduce(math.min);
    expect(nearest, lessThan(tolerance), reason: 'No corner near (${t.x.round()}, ${t.y.round()}): $found');
  }
}

void main() {
  const detector = CardDetector();

  // Camera frames come in landscape, like 640 × 480 from the back camera
  test('finds a straight card', () {
    final frame = _Frame(640, 480);
    final card = _card(320, 240, 220, 90); // Lying across the landscape frame: upright on screen
    frame.fill(card, 200);

    final result = detector.detect(frame.pixels, frame.width, frame.height);
    _expectCorners(result.corners, card);
  });

  test('finds a tilted card with art inside it', () {
    final frame = _Frame(640, 480, seed: 2);
    final card = _card(300, 250, 200, 70);
    frame.fill(card, 210);
    // Along the card's length (turned with it): the art box in the top half, the text box below
    final along = (x: -math.sin(70 * math.pi / 180), y: math.cos(70 * math.pi / 180));
    frame.fill(_card(300 - 40 * along.x, 250 - 40 * along.y, 160, 70, ratio: 0.8), 90);
    frame.fill(_card(300 + 85 * along.x, 250 + 85 * along.y, 150, 70, ratio: 0.3), 160);

    final result = detector.detect(frame.pixels, frame.width, frame.height);
    _expectCorners(result.corners, card);
  });

  test('finds a card seen at an angle (perspective)', () {
    final frame = _Frame(640, 480, seed: 3);
    // Narrower at the far end, as when the phone is tilted
    const card = [(x: 200.0, y: 130.0), (x: 450.0, y: 150.0), (x: 470.0, y: 360.0), (x: 180.0, y: 340.0)];
    frame.fill(card, 190);

    final result = detector.detect(frame.pixels, frame.width, frame.height);
    _expectCorners(result.corners, card);
  });

  test('reads frames with padded rows', () {
    final frame = _Frame(640, 480, stride: 704, seed: 4);
    final card = _card(320, 240, 220, 90);
    frame.fill(card, 200);

    final result = detector.detect(frame.pixels, frame.width, frame.height, rowStride: frame.stride);
    _expectCorners(result.corners, card);
  });

  test('a dark card on a light background', () {
    final frame = _Frame(640, 480, background: 200, seed: 5);
    final card = _card(320, 240, 220, 80);
    frame.fill(card, 40);

    final result = detector.detect(frame.pixels, frame.width, frame.height);
    _expectCorners(result.corners, card);
  });

  // In a hand: the hand's edges touch the card's, and fingers cover parts of its sides
  test('finds a card held in a hand, fingers over its sides', () {
    final frame = _Frame(640, 480, background: 70, seed: 10);
    const skin = 140;
    // The palm behind the card, coming in from the bottom of the frame
    frame.fill(const [(x: 180.0, y: 480.0), (x: 230.0, y: 300.0), (x: 420.0, y: 290.0), (x: 470.0, y: 480.0)], skin);
    final card = _card(320, 220, 180, 4);
    frame.fill(card, 205);
    // A thumb over the left side, 2 fingers over the right side
    frame.fill(const [(x: 200.0, y: 250.0), (x: 260.0, y: 245.0), (x: 262.0, y: 280.0), (x: 202.0, y: 285.0)], skin);
    frame.fill(const [(x: 385.0, y: 200.0), (x: 440.0, y: 205.0), (x: 438.0, y: 230.0), (x: 383.0, y: 225.0)], skin);
    frame.fill(const [(x: 383.0, y: 240.0), (x: 438.0, y: 245.0), (x: 436.0, y: 268.0), (x: 381.0, y: 263.0)], skin);

    final result = detector.detect(frame.pixels, frame.width, frame.height);
    _expectCorners(result.corners, card);
  });

  test('finds a card with a thumb over a corner', () {
    final frame = _Frame(640, 480, background: 70, seed: 11);
    const skin = 140;
    final card = _card(310, 240, 200, -8);
    frame.fill(card, 205);
    // Over the bottom right corner, and on out of the frame
    final corner = card[2];
    frame.fill([
      (x: corner.x - 35, y: corner.y - 30),
      (x: corner.x + 40, y: corner.y - 40),
      (x: 640.0, y: 480.0),
      (x: corner.x - 20, y: 480.0),
    ], skin);

    final result = detector.detect(frame.pixels, frame.width, frame.height);
    _expectCorners(result.corners, card);
  });

  test('ignores a square', () {
    final frame = _Frame(640, 480, seed: 6);
    frame.fill(_card(320, 240, 250, 0, ratio: 1), 200);

    expect(detector.detect(frame.pixels, frame.width, frame.height).corners, isNull);
  });

  test('ignores lines that only cross where a card would be', () {
    final frame = _Frame(640, 480, seed: 12);
    // Bars along a card's sides (the edges of a glass, a shelf), stopping short of its corners
    const left = 230.0, right = 410.0, top = 115.0, bottom = 365.0;
    frame.fill(const [(x: 265.0, y: top - 4), (x: 375.0, y: top - 4), (x: 375.0, y: top + 4), (x: 265.0, y: top + 4)], 200);
    frame.fill(const [(x: 265.0, y: bottom - 4), (x: 375.0, y: bottom - 4), (x: 375.0, y: bottom + 4), (x: 265.0, y: bottom + 4)], 200);
    frame.fill(const [(x: left - 4, y: 155.0), (x: left + 4, y: 155.0), (x: left + 4, y: 325.0), (x: left - 4, y: 325.0)], 200);
    frame.fill(const [(x: right - 4, y: 155.0), (x: right + 4, y: 155.0), (x: right + 4, y: 325.0), (x: right - 4, y: 325.0)], 200);

    expect(detector.detect(frame.pixels, frame.width, frame.height).corners, isNull);
  });

  test('ignores a card too small to read', () {
    final frame = _Frame(640, 480, seed: 7);
    frame.fill(_card(320, 240, 60, 90), 200);

    expect(detector.detect(frame.pixels, frame.width, frame.height).corners, isNull);
  });

  test('finds nothing in noise', () {
    final frame = _Frame(640, 480, seed: 8);

    expect(detector.detect(frame.pixels, frame.width, frame.height).corners, isNull);
  });

  test('returns the edge map when asked', () {
    final frame = _Frame(640, 480, seed: 9);
    frame.fill(_card(320, 240, 220, 90), 200);

    final result = detector.detect(frame.pixels, frame.width, frame.height, withEdges: true);
    expect(result.edges, isNotNull);
    expect(result.edges!.length, result.edgesWidth * result.edgesHeight);
    expect(result.edges!.any((e) => e == 255), isTrue);
    // ignore: avoid_print
    print('Detection took ${result.took.inMicroseconds / 1000} ms (test VM, not a phone)');
  });
}
