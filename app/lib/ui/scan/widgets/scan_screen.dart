// Copyright 2026 Christian Delicaat. All rights reserved.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:app/data/services/scanner/card_detector.dart';
import 'package:app/data/services/scanner/card_detector_worker.dart';
import 'package:app/themes/game_palette.dart';
import 'package:app/ui/shared/app_state.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';

/// The camera with a border around the card it sees (CardDetector, on every frame it can keep up
/// with). For now a test screen for the detection: nothing is captured or recognised yet. The
/// edges button shows what the detector sees, and the time it takes per frame.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  static final _log = Logger('ScanScreen');

  /// Frames in a row without a card before the border goes.
  static const _missesToLose = 6;

  /// Frames in a row with the same card before the border shows: a card holds still, while a
  /// shape that only looks like one (reflections in a glass) comes and goes.
  static const _hitsToShow = 3;

  /// A border further than this from the last one (share of the screen, per corner) is a new
  /// card, not the same one moved: it jumps instead of gliding.
  static const _jumpDistance = 0.08;

  /// The game being scanned: the one picked when the scanner opened. Its cards are the ones to
  /// look for, also once scans go to Magic Sorter.
  final _game = selectedGame.value;

  CameraController? _controller;
  CardDetectorWorker? _worker;
  String? _error;
  var _starting = false;
  var _busy = false;

  /// The card's corners on the preview, 0–1 across and down; null when there's none.
  List<Offset>? _corners;
  var _misses = 0;

  /// A card seen in the last [_hits] frames in a row but not shown yet, until it's [_hitsToShow].
  List<Offset>? _candidate;
  var _hits = 0;

  var _showEdges = false;
  ui.Image? _edges;
  Duration? _took;

  /// Debug builds: the next frame is saved, to tune the detector on (see [_saveFrame]).
  var _saveNext = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _worker?.dispose();
    _edges?.dispose();
    super.dispose();
  }

  // The camera is released while the app is in the background, and taken again when it's back
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      final controller = _controller;
      _controller = null;
      if (mounted) setState(() {});
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _start();
    }
  }

  Future<void> _start() async {
    if (_starting) return;
    _starting = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium, // Plenty for finding the card; the detector scales it down anyway
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // The first plane is brightness on both platforms
      );
      await controller.initialize();
      _worker ??= await CardDetectorWorker.spawn();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.startImageStream(_onFrame);
      setState(() {
        _controller = controller;
        _error = null;
      });
    } on CameraException catch (e) {
      _log.warning('Starting the camera failed', e);
      if (mounted) {
        setState(
          () => _error = e.code.contains('AccessDenied')
              ? 'The app may not use the camera. Allow it in the phone\'s settings to scan cards.'
              : 'The camera could not be started.',
        );
      }
    } finally {
      _starting = false;
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    final worker = _worker;
    if (_busy || worker == null) return; // Still on the last frame: skip this one
    _busy = true;
    try {
      final luma = image.planes.first;
      if (_saveNext) {
        _saveNext = false;
        // Copied now: the camera reuses the frame's buffer
        unawaited(_saveFrame(Uint8List.fromList(luma.bytes), image.width, image.height, luma.bytesPerRow));
      }
      final detection = await worker.detect(
        luma.bytes,
        image.width,
        image.height,
        rowStride: luma.bytesPerRow,
        withEdges: _showEdges,
      );
      if (mounted) await _apply(detection);
    } catch (e) {
      _log.warning('Detecting a card failed', e);
    } finally {
      _busy = false;
    }
  }

  Future<void> _apply(CardDetection detection) async {
    final rotation = _controller?.description.sensorOrientation ?? 90;
    final found = detection.corners
        ?.map((c) => _toPreview(c.x / detection.width, c.y / detection.height, rotation))
        .toList();

    ui.Image? edges;
    if (_showEdges && detection.edges != null) {
      edges = await _edgeImage(detection.edges!, detection.edgesWidth, detection.edgesHeight);
    }
    if (!mounted) return;

    setState(() {
      _took = detection.took;
      if (found == null) {
        if (++_misses > _missesToLose) _corners = null;
        _candidate = null;
        _hits = 0;
      } else if (_corners != null) {
        _misses = 0;
        _corners = _follow(_corners, found);
      } else {
        // Not showing one yet: wait until the same card is found a few frames in a row
        final last = _candidate;
        _hits = last != null && _match(last, found).distance <= _jumpDistance ? _hits + 1 : 1;
        _candidate = found;
        if (_hits >= _hitsToShow) {
          _misses = 0;
          _corners = found;
          _candidate = null;
          _hits = 0;
        }
      }
      _edges?.dispose();
      _edges = edges;
    });
  }

  /// Saves a frame's brightness plane as a PGM image (the detector's input, padding left out), for
  /// running the detector on it on a computer and keeping it as a test frame. Named after the time
  /// and the sensor rotation (the frame isn't turned upright). On Android, in the app's external
  /// files, so it can be copied off without root:
  /// `adb pull /sdcard/Android/data/nl.twohg.tcgcollector.dev/files/scanner_frames`
  Future<void> _saveFrame(Uint8List luma, int width, int height, int rowStride) async {
    try {
      final base = Platform.isAndroid ? await getExternalStorageDirectory() : null;
      final dir = Directory('${(base ?? await getApplicationDocumentsDirectory()).path}/scanner_frames');
      await dir.create(recursive: true);

      final pixels = Uint8List(width * height);
      for (var y = 0; y < height; y++) {
        pixels.setRange(y * width, (y + 1) * width, luma, y * rowStride);
      }
      final rotation = _controller?.description.sensorOrientation ?? 0;
      final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      final file = File('${dir.path}/frame_${stamp}_r$rotation.pgm');
      await file.writeAsBytes([...'P5\n$width $height\n255\n'.codeUnits, ...pixels]);

      _log.info('Saved a frame to ${file.path}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Frame saved: ${file.uri.pathSegments.last}')));
      }
    } catch (e) {
      _log.warning('Saving a frame failed', e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saving the frame failed')));
    }
  }

  /// A frame position (0–1 across and down, as the camera delivers it) on the preview, which shows
  /// the frame turned by the sensor's [rotation] to stand upright.
  static Offset _toPreview(double x, double y, int rotation) => switch (rotation) {
    90 => Offset(1 - y, x),
    180 => Offset(1 - x, 1 - y),
    270 => Offset(y, 1 - x),
    _ => Offset(x, y),
  };

  /// Glides the border from [last] to [found], so it doesn't jitter; jumps for another card.
  static List<Offset> _follow(List<Offset>? last, List<Offset> found) {
    if (last == null) return found;
    final (:shift, :distance) = _match(last, found);
    if (distance > _jumpDistance) return found;
    return [for (var i = 0; i < 4; i++) Offset.lerp(last[i], found[(i + shift) % 4], 0.5)!];
  }

  /// How [found] lines up with [last]: the detector may start its corners at another one each
  /// frame, so [shift] is where to start in [found], and [distance] the average distance between
  /// matching corners.
  static ({int shift, double distance}) _match(List<Offset> last, List<Offset> found) {
    var bestShift = 0;
    var bestDistance = double.infinity;
    for (var shift = 0; shift < 4; shift++) {
      var distance = 0.0;
      for (var i = 0; i < 4; i++) {
        distance += (found[(i + shift) % 4] - last[i]).distance;
      }
      if (distance < bestDistance) {
        bestDistance = distance;
        bestShift = shift;
      }
    }
    return (shift: bestShift, distance: bestDistance / 4);
  }

  static Future<ui.Image> _edgeImage(Uint8List edges, int width, int height) {
    final rgba = Uint8List(width * height * 4);
    for (var i = 0; i < edges.length; i++) {
      if (edges[i] == 0) continue;
      rgba[i * 4] = 255;
      rgba[i * 4 + 1] = 255;
      rgba[i * 4 + 2] = 255;
      rgba[i * 4 + 3] = 200;
    }
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(rgba, width, height, ui.PixelFormat.rgba8888, completer.complete);
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final accent = GamePalette.of(context, _game).accent;
    final controller = _controller;
    final found = _corners != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller.value.isInitialized)
            _CameraView(
              controller: controller,
              overlay: _BorderPainter(
                corners: _corners,
                edges: _showEdges ? _edges : null,
                rotation: controller.description.sensorOrientation,
                color: accent,
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white54)),

          // A dark fade behind the status bar and the top bar, so its icons and text stay readable
          // over a bright camera image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.paddingOf(context).top + 160,
            child: const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // Dark under the bar itself, then fading out below it
                    colors: [Color(0xE0000000), Color(0xB3000000), Color(0x00000000)],
                    stops: [0, 0.5, 1],
                  ),
                ),
              ),
            ),
          ),

          // Top: back, title, and the detection's debug tools. Aligned, as the stack would
          // otherwise stretch the row over the screen and center it.
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'Scan a ${_game.shortName} card',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (_took != null)
                      Text(
                        '${(_took!.inMicroseconds / 1000).toStringAsFixed(1)} ms',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontFeatures: [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                    // Debug builds: save the next frame, to tune the detector on
                    if (kDebugMode)
                      IconButton(
                        tooltip: 'Save frame',
                        onPressed: () => _saveNext = true,
                        icon: const Icon(LucideIcons.download, color: Colors.white),
                      ),
                    IconButton(
                      tooltip: _showEdges ? 'Hide edges' : 'Show edges',
                      onPressed: () => setState(() => _showEdges = !_showEdges),
                      icon: Icon(LucideIcons.scanEye, color: _showEdges ? accent : Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom: what to do
          if (controller != null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: found ? accent.withValues(alpha: 0.9) : Colors.black54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      found ? 'Card found' : 'Hold a card in view, on a plain surface',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The camera preview filling the screen (cropped at the sides as needed), with [overlay] painted
/// over exactly the area of the frame.
class _CameraView extends StatelessWidget {
  final CameraController controller;
  final CustomPainter overlay;

  const _CameraView({required this.controller, required this.overlay});

  @override
  Widget build(BuildContext context) {
    // The preview size is the camera's, in landscape; the app is upright
    final size = controller.value.previewSize!;

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(controller),
              CustomPaint(painter: overlay),
            ],
          ),
        ),
      ),
    );
  }
}

/// The border around the card: a soft fill and a line along the sides. With
/// [edges], first the detector's edge map over the preview.
class _BorderPainter extends CustomPainter {
  final List<Offset>? corners;
  final ui.Image? edges;
  final int rotation;
  final Color color;

  const _BorderPainter({required this.corners, required this.edges, required this.rotation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final edges = this.edges;
    if (edges != null) {
      // Turned like the preview: the edge map is in the camera's orientation
      final w = edges.width.toDouble();
      final h = edges.height.toDouble();
      canvas.save();
      switch (rotation) {
        case 90:
          canvas
            ..translate(size.width, 0)
            ..rotate(math.pi / 2)
            ..scale(size.height / w, size.width / h);
        case 180:
          canvas
            ..translate(size.width, size.height)
            ..rotate(math.pi)
            ..scale(size.width / w, size.height / h);
        case 270:
          canvas
            ..translate(0, size.height)
            ..rotate(-math.pi / 2)
            ..scale(size.height / w, size.width / h);
        default:
          canvas.scale(size.width / w, size.height / h);
      }
      canvas.drawImage(edges, Offset.zero, Paint()..filterQuality = FilterQuality.none);
      canvas.restore();
    }

    final corners = this.corners;
    if (corners == null) return;
    final points = [for (final c in corners) Offset(c.dx * size.width, c.dy * size.height)];
    final path = Path()..addPolygon(points, true);

    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.18));
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BorderPainter old) =>
      !listEquals(old.corners, corners) || old.edges != edges || old.rotation != rotation || old.color != color;
}
