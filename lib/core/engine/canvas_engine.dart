import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/models.dart';

// ─────────────────────────────────────────────
// CANVAS ENGINE
// ─────────────────────────────────────────────
class ESDCanvasEngine extends ChangeNotifier {
  // Viewport
  double zoom = 1.0;
  Offset panOffset = Offset.zero;
  Size canvasSize = const Size(1920, 1080);

  // Active state
  ESDLayer? activeLayer;
  List<ESDLayer> selectedLayers = [];
  String activeTool = 'move';
  ESDBrush activeBrush = ESDBrush(name: 'Round Brush');

  // Drawing state
  List<DrawnStroke> currentStrokes = [];
  DrawnStroke? activeStroke;
  bool isDrawing = false;

  // Grid & Guides
  bool showGrid = false;
  bool showGuides = true;
  bool snapToGrid = false;
  bool snapToGuides = true;
  bool snapToObjects = true;
  bool snapToPixels = true;
  double gridSize = 20;
  List<GuideLineModel> guides = [];

  // Symmetry
  bool symmetryEnabled = false;
  SymmetryType symmetryType = SymmetryType.vertical;
  int symmetryCount = 4;

  // Selection
  List<Offset> selectionPath = [];
  Rect? selectionRect;

  // History
  final List<HistoryAction> _history = [];
  int _historyIndex = -1;
  static const int maxHistory = 100;

  void setZoom(double value) {
    zoom = value.clamp(0.01, 64.0);
    notifyListeners();
  }

  void zoomIn() => setZoom(zoom * 1.2);
  void zoomOut() => setZoom(zoom / 1.2);
  void zoomFit(Size screenSize) {
    final scaleX = screenSize.width / canvasSize.width;
    final scaleY = screenSize.height / canvasSize.height;
    zoom = (scaleX < scaleY ? scaleX : scaleY) * 0.9;
    panOffset = Offset(
      (screenSize.width - canvasSize.width * zoom) / 2,
      (screenSize.height - canvasSize.height * zoom) / 2,
    );
    notifyListeners();
  }

  void pan(Offset delta) {
    panOffset += delta;
    notifyListeners();
  }

  Offset screenToCanvas(Offset screenPoint) {
    return Offset(
      (screenPoint.dx - panOffset.dx) / zoom,
      (screenPoint.dy - panOffset.dy) / zoom,
    );
  }

  Offset canvasToScreen(Offset canvasPoint) {
    return Offset(
      canvasPoint.dx * zoom + panOffset.dx,
      canvasPoint.dy * zoom + panOffset.dy,
    );
  }

  void startStroke(Offset position, double pressure) {
    if (activeLayer == null) return;
    activeStroke = DrawnStroke(
      layerId: activeLayer!.id,
      brush: activeBrush,
      color: _activeColor,
      points: [StrokePoint(position: position, pressure: pressure)],
    );
    isDrawing = true;
    notifyListeners();
  }

  void continueStroke(Offset position, double pressure) {
    if (!isDrawing || activeStroke == null) return;
    activeStroke!.points.add(StrokePoint(position: position, pressure: pressure));

    if (symmetryEnabled) {
      _addSymmetryPoints(position, pressure);
    }
    notifyListeners();
  }

  void endStroke() {
    if (activeStroke != null) {
      currentStrokes.add(activeStroke!);
      _pushHistory(HistoryAction(
        type: HistoryActionType.paintStroke,
        description: 'Paint stroke',
        before: {},
        after: {'stroke': activeStroke!.id},
      ));
      activeStroke = null;
    }
    isDrawing = false;
    notifyListeners();
  }

  void _addSymmetryPoints(Offset position, double pressure) {
    switch (symmetryType) {
      case SymmetryType.vertical:
        final mirrored = Offset(canvasSize.width - position.dx, position.dy);
        activeStroke!.symmetryPoints.add(StrokePoint(position: mirrored, pressure: pressure));
        break;
      case SymmetryType.horizontal:
        final mirrored = Offset(position.dx, canvasSize.height - position.dy);
        activeStroke!.symmetryPoints.add(StrokePoint(position: mirrored, pressure: pressure));
        break;
      case SymmetryType.radial:
        final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
        for (int i = 1; i < symmetryCount; i++) {
          final angle = (360 / symmetryCount) * i * (3.14159 / 180);
          final dx = position.dx - center.dx;
          final dy = position.dy - center.dy;
          final rotatedX = dx * cos(angle) - dy * sin(angle) + center.dx;
          final rotatedY = dx * sin(angle) + dy * cos(angle) + center.dy;
          activeStroke!.symmetryPoints.add(
            StrokePoint(position: Offset(rotatedX, rotatedY), pressure: pressure),
          );
        }
        break;
      default:
        break;
    }
  }

  double cos(double angle) => angle == 0 ? 1 : (1 - angle * angle / 2);
  double sin(double angle) => angle;

  ESDColor _activeColor = ESDColor(r: 0, g: 0, b: 0);

  void setActiveColor(ESDColor color) {
    _activeColor = color;
    notifyListeners();
  }

  ESDColor get activeColor => _activeColor;

  void setActiveTool(String tool) {
    activeTool = tool;
    notifyListeners();
  }

  void setActiveBrush(ESDBrush brush) {
    activeBrush = brush;
    notifyListeners();
  }

  void toggleGrid() {
    showGrid = !showGrid;
    notifyListeners();
  }

  void toggleGuides() {
    showGuides = !showGuides;
    notifyListeners();
  }

  void addGuide(GuideLineModel guide) {
    guides.add(guide);
    notifyListeners();
  }

  void removeGuide(String id) {
    guides.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  // History management
  void _pushHistory(HistoryAction action) {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(action);
    if (_history.length > maxHistory) {
      _history.removeAt(0);
    } else {
      _historyIndex++;
    }
  }

  bool get canUndo => _historyIndex >= 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  void undo() {
    if (!canUndo) return;
    _historyIndex--;
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _historyIndex++;
    notifyListeners();
  }

  List<HistoryAction> get history => List.unmodifiable(_history);
}

// ─────────────────────────────────────────────
// STROKE MODELS
// ─────────────────────────────────────────────
class StrokePoint {
  final Offset position;
  final double pressure;
  final double tilt;
  final double velocity;

  StrokePoint({
    required this.position,
    this.pressure = 1.0,
    this.tilt = 0,
    this.velocity = 0,
  });
}

class DrawnStroke {
  final String id = const Uuid().v4();
  final String layerId;
  final ESDBrush brush;
  final ESDColor color;
  final List<StrokePoint> points;
  final List<StrokePoint> symmetryPoints = [];

  DrawnStroke({
    required this.layerId,
    required this.brush,
    required this.color,
    List<StrokePoint>? points,
  }) : points = points ?? [];
}

// ─────────────────────────────────────────────
// GUIDE MODEL
// ─────────────────────────────────────────────
enum GuideOrientation { horizontal, vertical }

class GuideLineModel {
  final String id;
  GuideOrientation orientation;
  double position;
  Color color;
  bool isLocked;

  GuideLineModel({
    String? id,
    required this.orientation,
    required this.position,
    this.color = Colors.blue,
    this.isLocked = false,
  }) : id = id ?? const Uuid().v4();
}

// ─────────────────────────────────────────────
// SYMMETRY
// ─────────────────────────────────────────────
enum SymmetryType { vertical, horizontal, both, radial, mandala }

// ─────────────────────────────────────────────
// CANVAS PAINTER
// ─────────────────────────────────────────────
class ESDCanvasPainter extends CustomPainter {
  final ESDCanvasEngine engine;
  final ESDProject project;

  ESDCanvasPainter({required this.engine, required this.project});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(engine.panOffset.dx, engine.panOffset.dy);
    canvas.scale(engine.zoom);

    // Draw canvas background
    _drawCanvasBackground(canvas);

    // Draw grid
    if (engine.showGrid) {
      _drawGrid(canvas);
    }

    // Draw artboards
    for (final artboard in project.artboards) {
      _drawArtboard(canvas, artboard);
    }

    // Draw layers
    for (final layer in project.layers.reversed) {
      if (layer.isVisible) {
        _drawLayer(canvas, layer);
      }
    }

    // Draw active stroke
    if (engine.activeStroke != null) {
      _drawStroke(canvas, engine.activeStroke!);
    }

    // Draw selection
    if (engine.selectionRect != null) {
      _drawSelection(canvas, engine.selectionRect!);
    }

    // Draw guides
    if (engine.showGuides) {
      _drawGuides(canvas);
    }

    // Draw symmetry axis
    if (engine.symmetryEnabled) {
      _drawSymmetryAxis(canvas);
    }

    canvas.restore();
  }

  void _drawCanvasBackground(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, project.width.toDouble(), project.height.toDouble()),
      paint,
    );

    // Checkerboard for transparency
    _drawCheckerboard(canvas);
  }

  void _drawCheckerboard(Canvas canvas) {
    const cellSize = 10.0;
    final paint1 = Paint()..color = const Color(0xFFCCCCCC);
    final paint2 = Paint()..color = const Color(0xFFFFFFFF);

    for (double x = 0; x < project.width; x += cellSize) {
      for (double y = 0; y < project.height; y += cellSize) {
        final isEven = ((x / cellSize).floor() + (y / cellSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  void _drawGrid(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0x336C63FF)
      ..strokeWidth = 0.5 / engine.zoom
      ..style = PaintingStyle.stroke;

    for (double x = 0; x <= project.width; x += engine.gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, project.height.toDouble()), paint);
    }
    for (double y = 0; y <= project.height; y += engine.gridSize) {
      canvas.drawLine(Offset(0, y), Offset(project.width.toDouble(), y), paint);
    }
  }

  void _drawArtboard(Canvas canvas, ESDArtboard artboard) {
    // Artboard shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawRect(
      Rect.fromLTWH(artboard.x + 5, artboard.y + 5, artboard.width, artboard.height),
      shadowPaint,
    );

    // Artboard background
    if (artboard.showBackground) {
      final bgPaint = Paint()..color = artboard.backgroundColor;
      canvas.drawRect(
        Rect.fromLTWH(artboard.x, artboard.y, artboard.width, artboard.height),
        bgPaint,
      );
    }

    // Artboard border
    final borderPaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 1 / engine.zoom
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(artboard.x, artboard.y, artboard.width, artboard.height),
      borderPaint,
    );

    // Artboard name
    final textPainter = TextPainter(
      text: TextSpan(
        text: artboard.name,
        style: TextStyle(
          color: const Color(0xFF6C63FF),
          fontSize: 12 / engine.zoom,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(artboard.x, artboard.y - 20 / engine.zoom));
  }

  void _drawLayer(Canvas canvas, ESDLayer layer) {
    // Apply layer opacity and blend mode
    final paint = Paint()..color = Colors.white.withOpacity(layer.opacity);

    // Draw based on layer type
    switch (layer.type) {
      case LayerType.pixel:
        _drawPixelLayer(canvas, layer);
        break;
      case LayerType.vector:
        _drawVectorLayer(canvas, layer);
        break;
      case LayerType.text:
        _drawTextLayer(canvas, layer);
        break;
      case LayerType.adjustment:
        _drawAdjustmentLayer(canvas, layer);
        break;
      case LayerType.group:
        for (final child in layer.children) {
          if (child.isVisible) _drawLayer(canvas, child);
        }
        break;
      default:
        break;
    }
  }

  void _drawPixelLayer(Canvas canvas, ESDLayer layer) {
    // Draw stored strokes for this layer
    final layerStrokes = engine.currentStrokes.where((s) => s.layerId == layer.id);
    for (final stroke in layerStrokes) {
      _drawStroke(canvas, stroke);
    }
  }

  void _drawVectorLayer(Canvas canvas, ESDLayer layer) {
    if (layer.data['shape'] != null) {
      // Draw vector shape
    }
  }

  void _drawTextLayer(Canvas canvas, ESDLayer layer) {
    if (layer.data['text'] != null) {
      final textObj = ESDTextObject.fromJson(layer.data['text']);
      final textPainter = TextPainter(
        text: TextSpan(
          text: textObj.resolvedContent,
          style: TextStyle(
            fontFamily: textObj.fontFamily,
            fontSize: textObj.fontSize,
            color: textObj.color.toFlutterColor(),
            fontWeight: textObj.fontWeight,
            fontStyle: textObj.isItalic ? FontStyle.italic : FontStyle.normal,
            decoration: textObj.isUnderline ? TextDecoration.underline : TextDecoration.none,
            letterSpacing: textObj.letterSpacing,
            height: textObj.lineHeight,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: _mapAlignment(textObj.alignment),
      );
      textPainter.layout();
      textPainter.paint(canvas, layer.position);
    }
  }

  void _drawAdjustmentLayer(Canvas canvas, ESDLayer layer) {
    // Adjustment layers affect layers below them
  }

  void _drawStroke(Canvas canvas, DrawnStroke stroke) {
    if (stroke.points.length < 2) return;

    final paint = Paint()
      ..color = stroke.color.toFlutterColor().withOpacity(stroke.brush.opacity)
      ..strokeWidth = stroke.brush.size
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final path = Path();
    path.moveTo(stroke.points[0].position.dx, stroke.points[0].position.dy);

    for (int i = 1; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];
      final midX = (p1.position.dx + p2.position.dx) / 2;
      final midY = (p1.position.dy + p2.position.dy) / 2;
      path.quadraticBezierTo(p1.position.dx, p1.position.dy, midX, midY);
    }

    final last = stroke.points.last;
    path.lineTo(last.position.dx, last.position.dy);

    canvas.drawPath(path, paint);

    // Draw symmetry strokes
    for (final sp in stroke.symmetryPoints) {
      // Mirror strokes
    }
  }

  void _drawSelection(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 1 / engine.zoom
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 1 / engine.zoom
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, paint);

    // Draw handles
    _drawHandle(canvas, rect.topLeft);
    _drawHandle(canvas, rect.topCenter);
    _drawHandle(canvas, rect.topRight);
    _drawHandle(canvas, rect.centerLeft);
    _drawHandle(canvas, rect.centerRight);
    _drawHandle(canvas, rect.bottomLeft);
    _drawHandle(canvas, rect.bottomCenter);
    _drawHandle(canvas, rect.bottomRight);
  }

  void _drawHandle(Canvas canvas, Offset position) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 / engine.zoom;

    final size = 6 / engine.zoom;
    canvas.drawRect(
      Rect.fromCenter(center: position, width: size, height: size),
      paint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: position, width: size, height: size),
      borderPaint,
    );
  }

  void _drawGuides(Canvas canvas) {
    for (final guide in engine.guides) {
      final paint = Paint()
        ..color = guide.color.withOpacity(0.8)
        ..strokeWidth = 1 / engine.zoom
        ..style = PaintingStyle.stroke;

      if (guide.orientation == GuideOrientation.horizontal) {
        canvas.drawLine(
          Offset(0, guide.position),
          Offset(project.width.toDouble(), guide.position),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(guide.position, 0),
          Offset(guide.position, project.height.toDouble()),
          paint,
        );
      }
    }
  }

  void _drawSymmetryAxis(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..strokeWidth = 1 / engine.zoom
      ..style = PaintingStyle.stroke;

    final cx = project.width / 2.0;
    final cy = project.height / 2.0;

    switch (engine.symmetryType) {
      case SymmetryType.vertical:
        canvas.drawLine(Offset(cx, 0), Offset(cx, project.height.toDouble()), paint);
        break;
      case SymmetryType.horizontal:
        canvas.drawLine(Offset(0, cy), Offset(project.width.toDouble(), cy), paint);
        break;
      case SymmetryType.both:
        canvas.drawLine(Offset(cx, 0), Offset(cx, project.height.toDouble()), paint);
        canvas.drawLine(Offset(0, cy), Offset(project.width.toDouble(), cy), paint);
        break;
      default:
        break;
    }
  }

  TextAlign _mapAlignment(TextAlignment alignment) {
    switch (alignment) {
      case TextAlignment.left: return TextAlign.left;
      case TextAlignment.center: return TextAlign.center;
      case TextAlignment.right: return TextAlign.right;
      case TextAlignment.justify: return TextAlign.justify;
    }
  }

  @override
  bool shouldRepaint(ESDCanvasPainter oldDelegate) => true;
}

// UUID helper for stroke
class Uuid {
  const Uuid();
  String v4() => DateTime.now().microsecondsSinceEpoch.toString();
}
