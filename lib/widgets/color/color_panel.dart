import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../models/models.dart';
import '../../core/engine/canvas_engine.dart';
import '../../theme/app_theme.dart';

class ColorPanel extends StatefulWidget {
  final ESDCanvasEngine engine;
  final ESDProject project;
  const ColorPanel({super.key, required this.engine, required this.project});

  @override
  State<ColorPanel> createState() => _ColorPanelState();
}

class _ColorPanelState extends State<ColorPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _hexInput = '000000';

  double _r = 0, _g = 0, _b = 0, _a = 1;
  double _c = 0, _m = 0, _y = 0, _k = 0;
  double _h = 0, _s = 0, _l = 0;

  bool get _isCMYK => widget.project.colorMode == ColorMode.cmyk;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _syncFromEngine();
  }

  void _syncFromEngine() {
    final c = widget.engine.activeColor;
    _r = c.r * 255;
    _g = c.g * 255;
    _b = c.b * 255;
    _a = c.a;
    _hexInput = c.toHex().substring(1);
  }

  void _updateColor() {
    final color = ESDColor(r: _r / 255, g: _g / 255, b: _b / 255, a: _a);
    widget.engine.setActiveColor(color);
    _hexInput = color.toHex().substring(1);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Color preview
        Container(
          height: 60,
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.engine.activeColor.toFlutterColor(),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: widget.engine.activeColor.toFlutterColor().withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#$_hexInput',
              style: TextStyle(
                color: _r * 0.299 + _g * 0.587 + _b * 0.114 > 150 ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ),
        ),

        // Tabs
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Wheel'),
            Tab(text: _isCMYK ? 'CMYK' : 'RGB'),
            Tab(text: 'HEX'),
            Tab(text: 'Palettes'),
          ],
          indicatorColor: ESDizyneTheme.primary,
          labelColor: ESDizyneTheme.primary,
          unselectedLabelColor: ESDizyneTheme.textMuted,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildWheelTab(),
              _isCMYK ? _buildCMYKTab() : _buildRGBTab(),
              _buildHexTab(),
              _buildPalettesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWheelTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: ColorPicker(
        pickerColor: widget.engine.activeColor.toFlutterColor(),
        onColorChanged: (color) {
          _r = color.red.toDouble();
          _g = color.green.toDouble();
          _b = color.blue.toDouble();
          _updateColor();
        },
        pickerAreaHeightPercent: 0.5,
        enableAlpha: true,
        displayThumbColor: true,
        paletteType: PaletteType.hsvWithHue,
        labelTypes: const [],
        pickerAreaBorderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildRGBTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _colorSlider('R', _r, 0, 255, const Color(0xFFFF4444), (v) { _r = v; _updateColor(); }),
          _colorSlider('G', _g, 0, 255, const Color(0xFF44FF44), (v) { _g = v; _updateColor(); }),
          _colorSlider('B', _b, 0, 255, const Color(0xFF4444FF), (v) { _b = v; _updateColor(); }),
          _colorSlider('A', _a * 100, 0, 100, ESDizyneTheme.primary, (v) { _a = v / 100; _updateColor(); }),

          const SizedBox(height: 12),

          // Hex input
          Row(
            children: [
              const Text('#', style: TextStyle(color: ESDizyneTheme.textMuted, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: _hexInput),
                  style: const TextStyle(color: ESDizyneTheme.textPrimary, fontFamily: 'monospace'),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onSubmitted: (hex) => _applyHex(hex),
                  maxLength: 6,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCMYKTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _colorSlider('C', _c, 0, 100, const Color(0xFF00FFFF), (v) { _c = v; _cmykToRGB(); }),
          _colorSlider('M', _m, 0, 100, const Color(0xFFFF00FF), (v) { _m = v; _cmykToRGB(); }),
          _colorSlider('Y', _y, 0, 100, const Color(0xFFFFFF00), (v) { _y = v; _cmykToRGB(); }),
          _colorSlider('K', _k, 0, 100, Colors.grey, (v) { _k = v; _cmykToRGB(); }),
        ],
      ),
    );
  }

  void _cmykToRGB() {
    final c = _c / 100, m = _m / 100, y = _y / 100, k = _k / 100;
    _r = 255 * (1 - c) * (1 - k);
    _g = 255 * (1 - m) * (1 - k);
    _b = 255 * (1 - y) * (1 - k);
    _updateColor();
  }

  Widget _buildHexTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HEX Color', style: TextStyle(color: ESDizyneTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: _hexInput),
            style: const TextStyle(
              color: ESDizyneTheme.textPrimary,
              fontFamily: 'monospace',
              fontSize: 20,
              letterSpacing: 4,
            ),
            decoration: const InputDecoration(
              prefixText: '# ',
              prefixStyle: TextStyle(color: ESDizyneTheme.textMuted, fontSize: 20),
            ),
            onSubmitted: _applyHex,
            maxLength: 6,
          ),

          const SizedBox(height: 20),

          // Recent colors
          const Text('Recent', style: TextStyle(color: ESDizyneTheme.textMuted, fontSize: 11)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              Colors.red, Colors.green, Colors.blue, Colors.yellow,
              Colors.orange, Colors.purple, Colors.pink, Colors.teal,
              Colors.white, Colors.black,
            ].map((c) => GestureDetector(
              onTap: () {
                _r = c.red.toDouble();
                _g = c.green.toDouble();
                _b = c.blue.toDouble();
                _updateColor();
              },
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ESDizyneTheme.darkBorder),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  void _applyHex(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        _r = int.parse(clean.substring(0, 2), radix: 16).toDouble();
        _g = int.parse(clean.substring(2, 4), radix: 16).toDouble();
        _b = int.parse(clean.substring(4, 6), radix: 16).toDouble();
        _updateColor();
      }
    } catch (_) {}
  }

  Widget _buildPalettesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Text('Color Palettes', style: TextStyle(
                color: ESDizyneTheme.textSecondary, fontSize: 12,
              )),
              const Spacer(),
              GestureDetector(
                onTap: _createPalette,
                child: const Icon(Icons.add, size: 18, color: ESDizyneTheme.primary),
              ),
            ],
          ),
        ),

        Expanded(
          child: widget.project.colorPalettes.isEmpty
              ? const Center(
                  child: Text('No palettes yet.\nTap + to create one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ESDizyneTheme.textMuted, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  itemCount: widget.project.colorPalettes.length,
                  itemBuilder: (_, i) {
                    final palette = widget.project.colorPalettes[i];
                    return _PaletteItem(
                      palette: palette,
                      onColorTap: (color) {
                        widget.engine.setActiveColor(color);
                        setState(() {
                          _r = color.r * 255;
                          _g = color.g * 255;
                          _b = color.b * 255;
                          _a = color.a;
                        });
                      },
                      onAddColor: () {
                        palette.colors.add(ESDColor.fromFlutterColor(
                          widget.engine.activeColor.toFlutterColor(),
                        ));
                        setState(() {});
                      },
                      onDelete: () {
                        setState(() => widget.project.colorPalettes.removeAt(i));
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _createPalette() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ESDizyneTheme.darkCard,
        title: const Text('New Palette', style: TextStyle(color: ESDizyneTheme.textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: ESDizyneTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Palette name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  widget.project.colorPalettes.add(ESDColorPalette(
                    name: controller.text,
                  ));
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _colorSlider(String label, double value, double min, double max,
      Color trackColor, Function(double) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(label, style: const TextStyle(
            color: ESDizyneTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold,
          )),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: trackColor,
              thumbColor: trackColor,
              inactiveTrackColor: ESDizyneTheme.darkBorder,
              overlayColor: trackColor.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(color: ESDizyneTheme.textSecondary, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // Needed for tab label to reference project mode
  bool get _isCMYK => widget.project.colorMode == ColorMode.cmyk;
}

// ─────────────────────────────────────────────
// PALETTE ITEM
// ─────────────────────────────────────────────
class _PaletteItem extends StatelessWidget {
  final ESDColorPalette palette;
  final Function(ESDColor) onColorTap;
  final VoidCallback onAddColor;
  final VoidCallback onDelete;

  const _PaletteItem({
    required this.palette,
    required this.onColorTap,
    required this.onAddColor,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ESDizyneTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ESDizyneTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(palette.name, style: const TextStyle(
                color: ESDizyneTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600,
              )),
              const Spacer(),
              GestureDetector(
                onTap: onAddColor,
                child: const Icon(Icons.add_circle_outline, size: 16, color: ESDizyneTheme.primary),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline, size: 16, color: ESDizyneTheme.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ...palette.colors.map((c) => GestureDetector(
                onTap: () => onColorTap(c),
                child: Tooltip(
                  message: c.toHex(),
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: c.toFlutterColor(),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: ESDizyneTheme.darkBorder),
                    ),
                  ),
                ),
              )),
              if (palette.colors.isEmpty)
                const Text('No colors yet', style: TextStyle(
                  color: ESDizyneTheme.textMuted, fontSize: 11,
                )),
            ],
          ),
        ],
      ),
    );
  }
}
