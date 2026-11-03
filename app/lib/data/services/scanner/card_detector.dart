// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:math' as math;
import 'dart:typed_data';

/// A point in image pixels.
typedef Corner = ({double x, double y});

/// What [CardDetector.detect] found in one frame.
class CardDetection {
  /// The card's 4 corners in the frame's pixels (as the camera delivers it, before any rotation
  /// for display), in order around the card; null when no card was found.
  final List<Corner>? corners;

  /// The frame's size in pixels.
  final int width;
  final int height;

  /// The edge map the detector worked on, for debugging: 1 byte per pixel (255 = edge), at
  /// [edgesWidth] × [edgesHeight] (the frame scaled down). Null unless asked for.
  final Uint8List? edges;
  final int edgesWidth;
  final int edgesHeight;

  /// How long the detection took.
  final Duration took;

  const CardDetection({
    required this.corners,
    required this.width,
    required this.height,
    this.edges,
    this.edgesWidth = 0,
    this.edgesHeight = 0,
    required this.took,
  });
}

/// A straight line in normal form: the points where `x * nx + y * ny == rho`, with ([nx], [ny])
/// a unit vector at [angle] degrees (0–180) across the line.
typedef _Line = ({double nx, double ny, double rho, double angle});

/// Finds a trading card in a camera frame: the biggest 4-sided outline with a card's proportions
/// (63 × 88 mm), whose sides follow real edges in the image. Light enough to run on every frame
/// on a phone, in plain Dart: no OpenCV.
///
/// Works on brightness only (the Y plane of a YUV frame), scaled down to about [workSize] pixels
/// on the long side:
/// 1. Blur, then edges (Canny: gradients, thinning to 1 pixel, two thresholds).
/// 2. The long straight lines among the edges (a Hough transform, each edge voting only for lines
///    along its own direction), each fitted to its edges.
/// 3. Every 2 pairs of facing lines make a 4-sided outline; kept when it looks like a card: big
///    enough, about a card's proportions (allowing for tilt), corners near 90°, and edges along
///    most of every side. The best by size and edge cover wins.
///
/// Built on lines rather than outlines so a card in a hand works: fingers over a side leave the
/// rest of that side a straight line, a thumb over a corner leaves the 2 sides that meet there,
/// and the hand's own edges, touching the card, don't change its lines.
///
/// Struggles with what edges can't see: a card on a background of the same brightness (a black
/// border on a dark table), strong glare on a sleeve, or cards that overlap.
class CardDetector {
  /// The long side of the scaled-down frame the detector works on.
  final int workSize;

  const CardDetector({this.workSize = 320});

  /// Height / width of a card: 88 / 63 mm.
  static const cardRatio = 88 / 63;

  // What counts as a card
  static const _minAreaShare = 0.06; // Of the frame
  static const _maxAreaShare = 0.95;
  static const _minRatio = 1.15; // Proportions, allowing for tilt
  static const _maxRatio = 1.75;
  static const _minAngle = 55.0; // Degrees, per corner
  static const _maxAngle = 125.0;
  static const _minSideSupport = 0.4; // Of each side, this much runs along edges (fingers cover the rest)...
  static const _minTotalSupport = 0.6; // ...and of all 4 sides together
  // A card's sides run on into its corners; lines that only happen to cross (a glass's sides and
  // a table's edge) mostly stop short of where they meet. A thumb may cover 1 corner.
  static const _minCornersSeen = 3;
  static const _cornerReach = 0.2; // Of a side, the part next to a corner that's checked
  static const _minCornerSupport = 0.5; // Of that part, this much runs along edges

  // Finding lines
  static const _voteSpread = 5; // Degrees either way of an edge's own direction it votes for
  static const _maxLines = 24; // The strongest lines kept, to build outlines from
  static const _maxParallel = 30.0; // Degrees between facing sides (perspective tilts them)

  /// Looks for a card in a frame's brightness plane: [width] × [height] pixels, rows of
  /// [rowStride] bytes (at least [width]; cameras often pad rows). With [withEdges], also returns
  /// the edge map, for debugging.
  CardDetection detect(Uint8List luma, int width, int height, {int? rowStride, bool withEdges = false}) {
    final watch = Stopwatch()..start();
    final stride = rowStride ?? width;

    // Scale down by a whole factor, averaging the pixels it merges
    final factor = math.max(1, (math.max(width, height) / workSize).round());
    final w = width ~/ factor;
    final h = height ~/ factor;
    final small = _downscale(luma, width, stride, factor, w, h);

    final (:edges, :gx, :gy) = _edges(_blur(small, w, h), w, h);
    final thick = _dilate(edges, w, h); // Sides are checked against these: forgiving by a pixel

    // The shortest side a card of the minimum size has
    final minSide = math.sqrt(_minAreaShare * w * h / cardRatio);
    final lines = _lines(edges, gx, gy, w, h, minVotes: math.max(16, (minSide * 0.4).round()));

    List<Corner>? best;
    var bestScore = 0.0;
    for (final quad in _quads(lines, w, h, minSeparation: minSide * 0.7)) {
      final score = _score(quad, thick, w, h);
      if (score > bestScore) {
        bestScore = score;
        best = quad;
      }
    }

    return CardDetection(
      // Back to the frame's pixels: the middle of each scaled-down pixel
      corners: best?.map((c) => (x: (c.x + 0.5) * factor, y: (c.y + 0.5) * factor)).toList(),
      width: width,
      height: height,
      edges: withEdges ? _edgeImage(thick) : null,
      edgesWidth: w,
      edgesHeight: h,
      took: watch.elapsed,
    );
  }

  static Uint8List _downscale(Uint8List luma, int width, int stride, int factor, int w, int h) {
    final out = Uint8List(w * h);
    final area = factor * factor;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var sum = 0;
        for (var dy = 0; dy < factor; dy++) {
          final row = (y * factor + dy) * stride + x * factor;
          for (var dx = 0; dx < factor; dx++) {
            sum += luma[row + dx];
          }
        }
        out[y * w + x] = sum ~/ area;
      }
    }
    return out;
  }

  /// 5 × 5 Gaussian blur ([1 4 6 4 1] both ways), so noise and print texture don't become edges.
  static Int32List _blur(Uint8List src, int w, int h) {
    const kernel = [1, 4, 6, 4, 1];
    final across = Int32List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var sum = 0;
        for (var k = -2; k <= 2; k++) {
          sum += src[y * w + (x + k).clamp(0, w - 1)] * kernel[k + 2];
        }
        across[y * w + x] = sum;
      }
    }
    final out = Int32List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        var sum = 0;
        for (var k = -2; k <= 2; k++) {
          sum += across[(y + k).clamp(0, h - 1) * w + x] * kernel[k + 2];
        }
        out[y * w + x] = sum >> 8; // Both kernels sum to 16
      }
    }
    return out;
  }

  /// Canny edges (1 where there's an edge), with the gradient of every pixel: which way the
  /// brightness changes, so across the edge.
  static ({Uint8List edges, Int32List gx, Int32List gy}) _edges(Int32List img, int w, int h) {
    final magnitude = Int32List(w * h);
    final gxs = Int32List(w * h);
    final gys = Int32List(w * h);
    final direction = Uint8List(w * h); // 0: across, 1: diagonal \, 2: up-down, 3: diagonal /
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final i = y * w + x;
        final gx = (img[i - w + 1] + 2 * img[i + 1] + img[i + w + 1]) - (img[i - w - 1] + 2 * img[i - 1] + img[i + w - 1]);
        final gy = (img[i + w - 1] + 2 * img[i + w] + img[i + w + 1]) - (img[i - w - 1] + 2 * img[i - w] + img[i - w + 1]);
        gxs[i] = gx;
        gys[i] = gy;
        final ax = gx.abs();
        final ay = gy.abs();
        magnitude[i] = ax + ay;
        // tan(22.5°) ≈ 0.4142, tan(67.5°) ≈ 2.4142
        direction[i] = ay * 10000 <= ax * 4142
            ? 0
            : ay * 10000 >= ax * 24142
            ? 2
            : (gx > 0) == (gy > 0)
            ? 1
            : 3;
      }
    }

    // Thin to the ridge: keep a pixel only where it's the strongest across the edge
    final thin = Int32List(w * h);
    final histogram = Int32List(2048);
    var counted = 0;
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final i = y * w + x;
        final m = magnitude[i];
        if (m == 0) continue;
        final (a, b) = switch (direction[i]) {
          0 => (magnitude[i - 1], magnitude[i + 1]),
          1 => (magnitude[i - w - 1], magnitude[i + w + 1]),
          2 => (magnitude[i - w], magnitude[i + w]),
          _ => (magnitude[i - w + 1], magnitude[i + w - 1]),
        };
        if (m >= a && m >= b) {
          thin[i] = m;
          histogram[math.min(m, 2047)]++;
          counted++;
        }
      }
    }

    // Thresholds from this frame: the strongest 15% of the ridges are certain edges (at least a
    // clear step in brightness), ridges half as strong count where they touch one
    var high = 2047;
    var seen = 0;
    while (high > 0 && seen < counted * 0.15) {
      seen += histogram[high--];
    }
    high = math.max(high, 48);
    final low = high ~/ 2;

    final edges = Uint8List(w * h);
    final stack = <int>[];
    for (var i = 0; i < w * h; i++) {
      if (thin[i] < high || edges[i] == 1) continue;
      edges[i] = 1;
      stack.add(i);
      while (stack.isNotEmpty) {
        final j = stack.removeLast();
        final jx = j % w;
        final jy = j ~/ w;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final nx = jx + dx;
            final ny = jy + dy;
            if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
            final n = ny * w + nx;
            if (edges[n] == 0 && thin[n] >= low) {
              edges[n] = 1;
              stack.add(n);
            }
          }
        }
      }
    }
    return (edges: edges, gx: gxs, gy: gys);
  }

  /// Thickens edges by a pixel each way, closing small gaps in an outline.
  static Uint8List _dilate(Uint8List edges, int w, int h) {
    final out = Uint8List(w * h);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (edges[y * w + x] == 0) continue;
        for (var dy = -1; dy <= 1; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= h) continue;
          for (var dx = -1; dx <= 1; dx++) {
            final nx = x + dx;
            if (nx >= 0 && nx < w) out[ny * w + nx] = 1;
          }
        }
      }
    }
    return out;
  }

  /// The strongest straight lines among the edges, strongest first, each fitted to the edges
  /// along it. A Hough transform: every edge pixel votes for the lines through it, but only those
  /// within [_voteSpread]° of its own direction, which keeps texture and curves from adding up to
  /// lines. A line needs [minVotes] edge pixels on it.
  static List<_Line> _lines(Uint8List edges, Int32List gx, Int32List gy, int w, int h, {required int minVotes}) {
    const angles = 180; // 1° steps
    final cosines = Float64List.fromList([for (var a = 0; a < angles; a++) math.cos(a * math.pi / 180)]);
    final sines = Float64List.fromList([for (var a = 0; a < angles; a++) math.sin(a * math.pi / 180)]);
    final maxRho = (math.sqrt(w * w + h * h)).ceil();
    final rhos = 2 * maxRho + 1; // Rho runs from -maxRho to maxRho, in 1 pixel steps
    final votes = Int32List(angles * rhos);

    // The edge pixels, with the direction across them in degrees (0–180)
    final xs = <int>[];
    final ys = <int>[];
    final directions = <double>[];
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        if (edges[i] == 0 || (gx[i] == 0 && gy[i] == 0)) continue;
        final direction = (math.atan2(gy[i], gx[i]) * 180 / math.pi) % 180;
        xs.add(x);
        ys.add(y);
        directions.add(direction);

        final center = direction.round();
        for (var a = center - _voteSpread; a <= center + _voteSpread; a++) {
          final angle = a % angles;
          final rho = (x * cosines[angle] + y * sines[angle]).round();
          votes[angle * rhos + rho + maxRho]++;
        }
      }
    }

    // Peaks: cells with enough votes that no neighbor beats
    final peaks = <(int angle, int rho, int votes)>[];
    for (var a = 0; a < angles; a++) {
      for (var r = 1; r < rhos - 1; r++) {
        final v = votes[a * rhos + r];
        if (v < minVotes) continue;
        var isPeak = true;
        for (var da = -1; da <= 1 && isPeak; da++) {
          final na = a + da;
          if (na < 0 || na >= angles) continue;
          for (var dr = -1; dr <= 1; dr++) {
            if ((da != 0 || dr != 0) && votes[na * rhos + r + dr] > v) {
              isPeak = false;
              break;
            }
          }
        }
        if (isPeak) peaks.add((a, r - maxRho, v));
      }
    }
    peaks.sort((a, b) => b.$3.compareTo(a.$3));

    // Strongest first, skipping lines next to one already kept (the same line, voted for twice)
    final lines = <_Line>[];
    for (final (angle, rho, _) in peaks) {
      final candidate = (nx: cosines[angle], ny: sines[angle], rho: rho.toDouble(), angle: angle.toDouble());
      if (lines.any((l) => _sameLine(l, candidate))) continue;
      final fitted = _fit(candidate, xs, ys, directions, minPoints: minVotes ~/ 2) ?? candidate;
      if (lines.any((l) => _sameLine(l, fitted))) continue;
      lines.add(fitted);
      if (lines.length == _maxLines) break;
    }
    return lines;
  }

  /// Whether 2 lines are about the same: under 4° apart, and under 6 pixels apart.
  static bool _sameLine(_Line a, _Line b) {
    final dot = a.nx * b.nx + a.ny * b.ny;
    if (dot.abs() < math.cos(4 * math.pi / 180)) return false;
    return (a.rho - b.rho * dot.sign).abs() < 6;
  }

  /// [line] moved onto the edge pixels along it (within 2 pixels, and running the same way): their
  /// best-fitting line. The Hough grid is coarse; a card's corners come from where its lines meet,
  /// so they need to be exact. Null when too few pixels are along it.
  static _Line? _fit(_Line line, List<int> xs, List<int> ys, List<double> directions, {required int minPoints}) {
    var n = 0;
    var sx = 0.0, sy = 0.0, sxx = 0.0, syy = 0.0, sxy = 0.0;
    for (var i = 0; i < xs.length; i++) {
      final x = xs[i].toDouble();
      final y = ys[i].toDouble();
      if ((x * line.nx + y * line.ny - line.rho).abs() > 2) continue;
      final turn = (directions[i] - line.angle).abs() % 180;
      if (math.min(turn, 180 - turn) > 10) continue;
      n++;
      sx += x;
      sy += y;
      sxx += x * x;
      syy += y * y;
      sxy += x * y;
    }
    if (n < minPoints) return null;

    // The direction the points spread along most (principal axis); across it is the normal
    final mx = sx / n;
    final my = sy / n;
    final cxx = sxx / n - mx * mx;
    final cyy = syy / n - my * my;
    final cxy = sxy / n - mx * my;
    final along = 0.5 * math.atan2(2 * cxy, cxx - cyy);
    var nx = -math.sin(along);
    var ny = math.cos(along);
    if (nx * line.nx + ny * line.ny < 0) {
      // Same side as before, so nothing that compares lines is thrown off
      nx = -nx;
      ny = -ny;
    }
    final angle = (math.atan2(ny, nx) * 180 / math.pi) % 180;
    return (nx: nx, ny: ny, rho: mx * nx + my * ny, angle: angle);
  }

  /// The 4-sided outlines that pairs of facing lines make: 2 nearly parallel lines at least
  /// [minSeparation] apart, crossed by 2 others. Each with its corners inside the frame, in the
  /// same order around it (positive area), so the screen can follow them from frame to frame.
  static Iterable<List<Corner>> _quads(List<_Line> lines, int w, int h, {required double minSeparation}) sync* {
    final pairs = <(_Line, _Line)>[];
    for (var i = 0; i < lines.length; i++) {
      for (var j = i + 1; j < lines.length; j++) {
        final a = lines[i];
        final b = lines[j];
        if (_angleBetween(a, b) > _maxParallel) continue;
        final dot = a.nx * b.nx + a.ny * b.ny;
        if ((a.rho - b.rho * dot.sign).abs() < minSeparation) continue;
        pairs.add((a, b));
      }
    }

    for (var i = 0; i < pairs.length; i++) {
      for (var j = i + 1; j < pairs.length; j++) {
        final (a1, a2) = pairs[i];
        final (b1, b2) = pairs[j];
        // The 2 pairs cross, as a card's sides do (its corners are checked closer later)
        if (_angleBetween(a1, b1) < 40) continue;

        final corners = [_cross(a1, b1), _cross(b1, a2), _cross(a2, b2), _cross(b2, a1)];
        if (corners.any((c) => c == null || c.x < -1 || c.y < -1 || c.x > w || c.y > h)) continue;
        final quad = corners.cast<Corner>();
        if (!_isConvex(quad)) continue; // A bow tie: one pair's lines cross between the others
        yield _signedArea(quad) >= 0 ? quad : quad.reversed.toList();
      }
    }
  }

  /// Whether [quad] turns the same way at every corner.
  static bool _isConvex(List<Corner> quad) {
    var positive = 0;
    for (var i = 0; i < 4; i++) {
      final a = quad[i];
      final b = quad[(i + 1) % 4];
      final c = quad[(i + 2) % 4];
      if ((b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x) > 0) positive++;
    }
    return positive == 0 || positive == 4;
  }

  /// Degrees between 2 lines' directions, 0–90.
  static double _angleBetween(_Line a, _Line b) {
    final turn = (a.angle - b.angle).abs() % 180;
    return math.min(turn, 180 - turn);
  }

  /// Where 2 lines meet; null when they're (about) parallel.
  static Corner? _cross(_Line a, _Line b) {
    final det = a.nx * b.ny - a.ny * b.nx;
    if (det.abs() < 1e-6) return null;
    return (x: (a.rho * b.ny - b.rho * a.ny) / det, y: (a.nx * b.rho - b.nx * a.rho) / det);
  }

  /// How likely [quad] is a card: its area, times how well edges follow its sides (weighed
  /// heavily, so a bigger outline with a side through empty space loses to the card inside it);
  /// 0 when it doesn't look like one at all.
  static double _score(List<Corner> quad, Uint8List edges, int w, int h) {
    final area = _area(quad);
    final frame = (w * h).toDouble();
    if (area < frame * _minAreaShare || area > frame * _maxAreaShare) return 0;

    final sides = [for (var i = 0; i < 4; i++) _distance(quad[i], quad[(i + 1) % 4])];
    final across = (sides[0] + sides[2]) / 2;
    final along = (sides[1] + sides[3]) / 2;
    final ratio = math.max(across, along) / math.min(across, along);
    if (ratio < _minRatio || ratio > _maxRatio) return 0;

    for (var i = 0; i < 4; i++) {
      final angle = _angle(quad[(i + 3) % 4], quad[i], quad[(i + 1) % 4]);
      if (angle < _minAngle || angle > _maxAngle) return 0;
    }

    var total = 0.0;
    for (var i = 0; i < 4; i++) {
      final support = _support(quad[i], quad[(i + 1) % 4], edges, w, h);
      if (support < _minSideSupport) return 0;
      total += support;
    }
    total /= 4;
    if (total < _minTotalSupport) return 0;

    // Corners where both sides run on into it
    var cornersSeen = 0;
    for (var i = 0; i < 4; i++) {
      final corner = quad[i];
      final before = quad[(i + 3) % 4];
      final after = quad[(i + 1) % 4];
      if (_support(corner, before, edges, w, h, reach: _cornerReach) >= _minCornerSupport &&
          _support(corner, after, edges, w, h, reach: _cornerReach) >= _minCornerSupport) {
        cornersSeen++;
      }
    }
    if (cornersSeen < _minCornersSeen) return 0;

    // Closer to a card's proportions scores a little higher, among shapes that pass
    final shape = 1 - (ratio - cardRatio).abs() / cardRatio;
    return area * total * total * total * shape;
  }

  /// Share of the points along a side that lie on an edge: from [from] to [to], or only the first
  /// [reach] of the way (0–1). The corners themselves are left out: the blur rounds them off.
  static double _support(Corner from, Corner to, Uint8List edges, int w, int h, {double reach = 1}) {
    const samples = 40;
    const first = 2;
    final last = reach >= 1 ? samples - 2 : (samples * reach).round();
    var hits = 0;
    for (var s = first; s < last; s++) {
      final t = s / samples;
      final x = (from.x + (to.x - from.x) * t).round();
      final y = (from.y + (to.y - from.y) * t).round();
      if (x >= 0 && y >= 0 && x < w && y < h && edges[y * w + x] == 1) hits++;
    }
    return hits / (last - first);
  }

  static Uint8List _edgeImage(Uint8List edges) {
    final out = Uint8List(edges.length);
    for (var i = 0; i < edges.length; i++) {
      out[i] = edges[i] * 255;
    }
    return out;
  }

  static double _signedArea(List<Corner> polygon) {
    var sum = 0.0;
    for (var i = 0; i < polygon.length; i++) {
      final a = polygon[i];
      final b = polygon[(i + 1) % polygon.length];
      sum += a.x * b.y - b.x * a.y;
    }
    return sum / 2;
  }

  static double _area(List<Corner> polygon) => _signedArea(polygon).abs();

  static double _distance(Corner a, Corner b) => math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

  /// The angle at [at], between [from] and [to], in degrees.
  static double _angle(Corner from, Corner at, Corner to) {
    final ax = from.x - at.x;
    final ay = from.y - at.y;
    final bx = to.x - at.x;
    final by = to.y - at.y;
    final cos = (ax * bx + ay * by) / (math.sqrt(ax * ax + ay * ay) * math.sqrt(bx * bx + by * by));
    return math.acos(cos.clamp(-1.0, 1.0)) * 180 / math.pi;
  }
}
