import 'package:flutter/material.dart';
import '../../core/engine/canvas_engine.dart';
import '../../theme/app_theme.dart';

class ToolsPanel extends StatelessWidget {
  final ESDCanvasEngine engine;
  const ToolsPanel({super.key, required this.engine});

  static const tools = [
    _Tool('move', Icons.open_with, 'Move (V)'),
    _Tool('select_rect', Icons.crop_square, 'Rectangular Select (M)'),
    _Tool('select_ellipse', Icons.circle_outlined, 'Ellipse Select'),
    _Tool('select_lasso', Icons.gesture, 'Lasso (L)'),
    _Tool('select_magic', Icons.auto_fix_high, 'Magic Wand (W)'),
    _Tool('select_subject', Icons.person_outline, 'Select Subject'),
    _Tool('crop', Icons.crop, 'Crop (C)'),
    _Tool('brush', Icons.brush, 'Brush (B)'),
    _Tool('pencil', Icons.edit, 'Pencil'),
    _Tool('eraser', Icons.auto_fix_off, 'Eraser (E)'),
    _Tool('airbrush', Icons.blur_on, 'Airbrush'),
    _Tool('smudge', Icons.blur_circular, 'Smudge'),
    _Tool('dodge', Icons.brightness_high, 'Dodge'),
    _Tool('burn', Icons.brightness_low, 'Burn'),
    _Tool('fill', Icons.format_color_fill, 'Fill (G)'),
    _Tool('gradient', Icons.gradient, 'Gradient'),
    _Tool('eyedropper', Icons.colorize, 'Eyedropper (I)'),
    _Tool('text', Icons.text_fields, 'Text (T)'),
    _Tool('pen', Icons.create, 'Pen (P)'),
    _Tool('shape_rect', Icons.rectangle_outlined, 'Rectangle Shape (U)'),
    _Tool('shape_ellipse', Icons.circle_outlined, 'Ellipse Shape'),
    _Tool('shape_polygon', Icons.hexagon_outlined, 'Polygon'),
    _Tool('shape_star', Icons.star_outline, 'Star'),
    _Tool('shape_line', Icons.horizontal_rule, 'Line'),
    _Tool('shape_arrow', Icons.arrow_forward, 'Arrow'),
    _Tool('shape_custom', Icons.category_outlined, 'Custom Shape'),
    _Tool('clone', Icons.content_copy, 'Clone Stamp (S)'),
    _Tool('heal', Icons.healing, 'Healing Brush (J)'),
    _Tool('patch', Icons.layers_outlined, 'Patch Tool'),
    _Tool('hand', Icons.pan_tool, 'Hand (H)'),
    _Tool('zoom_tool', Icons.zoom_in, 'Zoom (Z)'),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (_, __) => ListView.builder(
        itemCount: tools.length,
        itemBuilder: (_, i) {
          final tool = tools[i];
          final isActive = engine.activeTool == tool.id;

          return Tooltip(
            message: tool.label,
            preferBelow: false,
            child: GestureDetector(
              onTap: () => engine.setActiveTool(tool.id),
              child: Container(
                width: 48,
                height: 48,
                margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive ? ESDizyneTheme.primary.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? ESDizyneTheme.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  tool.icon,
                  size: 20,
                  color: isActive ? ESDizyneTheme.primary : ESDizyneTheme.textMuted,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tool {
  final String id;
  final IconData icon;
  final String label;
  const _Tool(this.id, this.icon, this.label);
}
