// ═══════════════════════════════════════════════════════════
// CANVAS WIDGET
// ═══════════════════════════════════════════════════════════
// lib/widgets/canvas/canvas_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../core/engine/canvas_engine.dart';
import '../../theme/app_theme.dart';

class CanvasWidget extends StatefulWidget {
  final ESDProject project;
  final ESDCanvasEngine engine;
  const CanvasWidget({super.key, required this.project, required this.engine});

  @override
  State<CanvasWidget> createState() => _CanvasWidgetState();
}

class _CanvasWidgetState extends State<CanvasWidget> {
  Offset? _lastPanPosition;
  double _lastScale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<ESDCanvasEngine>(
      builder: (_, engine, __) => Container(
        color: ESDizyneTheme.canvasBg,
        child: RepaintBoundary(
          child: GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onScaleEnd: _onScaleEnd,
            child: Listener(
              onPointerDown: (e) => _onPointerDown(e, engine),
              onPointerMove: (e) => _onPointerMove(e, engine),
              onPointerUp: (e) => _onPointerUp(e, engine),
              child: CustomPaint(
                painter: ESDCanvasPainter(engine: engine, project: widget.project),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _lastScale = widget.engine.zoom;
    _lastPanPosition = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final engine = widget.engine;

    if (details.scale != 1.0) {
      // Pinch zoom
      engine.setZoom(_lastScale * details.scale);
    } else if (_lastPanPosition != null &&
        (engine.activeTool == 'move' || engine.activeTool == 'hand')) {
      // Pan
      final delta = details.focalPoint - _lastPanPosition!;
      engine.pan(delta);
      _lastPanPosition = details.focalPoint;
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _lastPanPosition = null;
  }

  void _onPointerDown(PointerDownEvent event, ESDCanvasEngine engine) {
    if (engine.activeTool == 'brush' || engine.activeTool == 'pencil' ||
        engine.activeTool == 'eraser' || engine.activeTool == 'airbrush') {
      final canvasPos = engine.screenToCanvas(event.localPosition);
      engine.startStroke(canvasPos, event.pressure);
    }
  }

  void _onPointerMove(PointerMoveEvent event, ESDCanvasEngine engine) {
    if (engine.isDrawing) {
      final canvasPos = engine.screenToCanvas(event.localPosition);
      engine.continueStroke(canvasPos, event.pressure);
    }
  }

  void _onPointerUp(PointerUpEvent event, ESDCanvasEngine engine) {
    if (engine.isDrawing) {
      engine.endStroke();
    }
  }
}
