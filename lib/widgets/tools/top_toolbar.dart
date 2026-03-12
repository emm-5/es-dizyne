import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/engine/canvas_engine.dart';
import '../../theme/app_theme.dart';

class TopToolbar extends StatelessWidget {
  final ESDProject project;
  final ESDCanvasEngine engine;
  final VoidCallback onSave;
  final VoidCallback onExport;
  final VoidCallback onSaveAs;
  final VoidCallback onToggleFullscreen;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  const TopToolbar({
    super.key,
    required this.project,
    required this.engine,
    required this.onSave,
    required this.onExport,
    required this.onSaveAs,
    required this.onToggleFullscreen,
    this.onUndo,
    this.onRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: ESDizyneTheme.darkSurface,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // App logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: ESDizyneGradients.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('ES', style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              )),
            ),
          ),

          const SizedBox(width: 12),

          // Menu items
          _MenuButton(label: 'File', items: [
            _MenuItem('New Project', Icons.add, () => _showNewProject(context)),
            _MenuItem('Open', Icons.folder_open, () {}),
            _MenuItem('Save', Icons.save, onSave),
            _MenuItem('Save As', Icons.save_as, onSaveAs),
            _MenuItem('Export', Icons.upload, onExport),
            _MenuItem('Backup', Icons.backup, () {}),
            _MenuItem('Close', Icons.close, () => Navigator.pop(context)),
          ]),

          _MenuButton(label: 'Edit', items: [
            _MenuItem('Undo', Icons.undo, onUndo ?? () {}),
            _MenuItem('Redo', Icons.redo, onRedo ?? () {}),
            _MenuItem('Cut', Icons.content_cut, () {}),
            _MenuItem('Copy', Icons.content_copy, () {}),
            _MenuItem('Paste', Icons.content_paste, () {}),
            _MenuItem('Select All', Icons.select_all, () {}),
            _MenuItem('Deselect', Icons.deselect, () {}),
            _MenuItem('Transform', Icons.transform, () {}),
            _MenuItem('Free Transform', Icons.crop_free, () {}),
          ]),

          _MenuButton(label: 'Layer', items: [
            _MenuItem('New Layer', Icons.add, () {}),
            _MenuItem('New Group', Icons.folder, () {}),
            _MenuItem('Duplicate Layer', Icons.copy_all, () {}),
            _MenuItem('Delete Layer', Icons.delete, () {}),
            _MenuItem('Merge Down', Icons.merge, () {}),
            _MenuItem('Merge Visible', Icons.layers, () {}),
            _MenuItem('Flatten Image', Icons.layers_clear, () {}),
            _MenuItem('Add Mask', Icons.masks, () {}),
            _MenuItem('Clipping Mask', Icons.cut, () {}),
            _MenuItem('Layer Effects', Icons.auto_awesome, () {}),
          ]),

          _MenuButton(label: 'Image', items: [
            _MenuItem('Canvas Size', Icons.aspect_ratio, () => _showCanvasResize(context)),
            _MenuItem('Image Size / Upscale', Icons.photo_size_select_large, () {}),
            _MenuItem('Rotate Canvas', Icons.rotate_right, () {}),
            _MenuItem('Flip Horizontal', Icons.flip, () {}),
            _MenuItem('Flip Vertical', Icons.flip, () {}),
            _MenuItem('Crop', Icons.crop, () {}),
            _MenuItem('Adjustments', Icons.tune, () {}),
            _MenuItem('Color Mode', Icons.color_lens, () => _showColorModeDialog(context)),
            _MenuItem('DPI Settings', Icons.print, () => _showDPIDialog(context)),
          ]),

          _MenuButton(label: 'Filter', items: [
            _MenuItem('Blur', Icons.blur_on, () {}),
            _MenuItem('Sharpen', Icons.add_photo_alternate, () {}),
            _MenuItem('Noise', Icons.grain, () {}),
            _MenuItem('Distort', Icons.waves, () {}),
            _MenuItem('Stylize', Icons.style, () {}),
            _MenuItem('Render', Icons.wb_sunny, () {}),
            _MenuItem('Other', Icons.more_horiz, () {}),
          ]),

          _MenuButton(label: 'Select', items: [
            _MenuItem('All', Icons.select_all, () {}),
            _MenuItem('Deselect', Icons.deselect, () {}),
            _MenuItem('Invert', Icons.invert_colors, () {}),
            _MenuItem('Color Range', Icons.colorize, () {}),
            _MenuItem('Grow', Icons.zoom_out_map, () {}),
            _MenuItem('Expand', Icons.expand, () {}),
            _MenuItem('Contract', Icons.compress, () {}),
            _MenuItem('Feather', Icons.blur_linear, () {}),
            _MenuItem('Save Selection', Icons.save, () {}),
          ]),

          _MenuButton(label: 'View', items: [
            _MenuItem('Zoom In', Icons.zoom_in, () => engine.zoomIn()),
            _MenuItem('Zoom Out', Icons.zoom_out, () => engine.zoomOut()),
            _MenuItem('Fit to Screen', Icons.fit_screen, () {}),
            _MenuItem('100%', Icons.crop_original, () => engine.setZoom(1.0)),
            _MenuItem('Grid', Icons.grid_on, () => engine.toggleGrid()),
            _MenuItem('Guides', Icons.straighten, () => engine.toggleGuides()),
            _MenuItem('Rulers', Icons.rule, () {}),
            _MenuItem('Snapping', Icons.snooze, () {}),
            _MenuItem('Fullscreen', Icons.fullscreen, onToggleFullscreen),
          ]),

          const Spacer(),

          // Project name
          Text(
            project.name,
            style: const TextStyle(
              color: ESDizyneTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(width: 12),

          // Quick action buttons
          _toolbarIconBtn(Icons.undo, onUndo != null, onUndo ?? () {}, 'Undo'),
          _toolbarIconBtn(Icons.redo, onRedo != null, onRedo ?? () {}, 'Redo'),
          const SizedBox(width: 8),
          _toolbarIconBtn(Icons.save, true, onSave, 'Save'),
          _toolbarIconBtn(Icons.upload, true, onExport, 'Export'),
          _toolbarIconBtn(Icons.fullscreen, true, onToggleFullscreen, 'Fullscreen'),
        ],
      ),
    );
  }

  Widget _toolbarIconBtn(IconData icon, bool enabled, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? ESDizyneTheme.textSecondary : ESDizyneTheme.textMuted.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  void _showNewProject(BuildContext context) {
    showDialog(context: context, builder: (_) => const NewProjectDialog());
  }

  void _showCanvasResize(BuildContext context) {
    showDialog(context: context, builder: (_) => CanvasResizeDialog(project: project));
  }

  void _showColorModeDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => ColorModeDialog(project: project));
  }

  void _showDPIDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => DPIDialog(project: project));
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final List<_MenuItem> items;
  const _MenuButton({required this.label, required this.items});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_MenuItem>(
      offset: const Offset(0, 40),
      color: ESDizyneTheme.darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: ESDizyneTheme.darkBorder),
      ),
      itemBuilder: (_) => items.map((item) => PopupMenuItem<_MenuItem>(
        value: item,
        child: Row(
          children: [
            Icon(item.icon, size: 16, color: ESDizyneTheme.textMuted),
            const SizedBox(width: 10),
            Text(item.label, style: const TextStyle(
              color: ESDizyneTheme.textPrimary, fontSize: 13,
            )),
          ],
        ),
      )).toList(),
      onSelected: (item) => item.onTap(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(label, style: const TextStyle(
          color: ESDizyneTheme.textSecondary, fontSize: 13,
        )),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _MenuItem(this.label, this.icon, this.onTap);
}

// ─────────────────────────────────────────────
// NEW PROJECT DIALOG
// ─────────────────────────────────────────────
class NewProjectDialog extends StatefulWidget {
  const NewProjectDialog({super.key});

  @override
  State<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends State<NewProjectDialog> {
  final _nameController = TextEditingController(text: 'Untitled');
  int _width = 1920;
  int _height = 1080;
  double _dpi = 72;
  ColorMode _colorMode = ColorMode.rgb;

  final _presets = [
    _Preset('Custom', 0, 0),
    _Preset('HD Screen', 1920, 1080),
    _Preset('4K Screen', 3840, 2160),
    _Preset('Instagram', 1080, 1080),
    _Preset('Instagram Story', 1080, 1920),
    _Preset('Twitter', 1500, 500),
    _Preset('Facebook', 1200, 630),
    _Preset('YouTube', 1280, 720),
    _Preset('A4 Print', 2480, 3508),
    _Preset('A3 Print', 3508, 4961),
    _Preset('A5 Print', 1748, 2480),
    _Preset('Business Card', 1050, 600),
    _Preset('Logo', 500, 500),
    _Preset('Banner', 2560, 640),
    _Preset('Wallpaper', 3840, 2160),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ESDizyneTheme.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('New Project', style: TextStyle(
                color: ESDizyneTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )),
              const SizedBox(height: 20),

              // Name
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
                style: const TextStyle(color: ESDizyneTheme.textPrimary),
              ),
              const SizedBox(height: 16),

              // Presets
              const Text('Presets', style: TextStyle(color: ESDizyneTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _presets.map((p) => GestureDetector(
                  onTap: () {
                    if (p.width > 0) setState(() { _width = p.width; _height = p.height; });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: ESDizyneTheme.darkSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: ESDizyneTheme.darkBorder),
                    ),
                    child: Text(p.name, style: const TextStyle(
                      fontSize: 11, color: ESDizyneTheme.textSecondary,
                    )),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),

              // Width & Height
              Row(
                children: [
                  Expanded(child: _numberField('Width', _width, (v) => setState(() => _width = v))),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField('Height', _height, (v) => setState(() => _height = v))),
                ],
              ),
              const SizedBox(height: 12),

              // DPI
              const Text('DPI', style: TextStyle(color: ESDizyneTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: [72, 96, 150, 300, 600].map((d) => GestureDetector(
                  onTap: () => setState(() => _dpi = d.toDouble()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _dpi == d ? ESDizyneTheme.primary : ESDizyneTheme.darkSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _dpi == d ? ESDizyneTheme.primary : ESDizyneTheme.darkBorder,
                      ),
                    ),
                    child: Text('$d', style: TextStyle(
                      fontSize: 12,
                      color: _dpi == d ? Colors.white : ESDizyneTheme.textSecondary,
                    )),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 12),

              // Color mode
              const Text('Color Mode', style: TextStyle(color: ESDizyneTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: ColorMode.values.map((m) => Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _colorMode = m),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _colorMode == m ? ESDizyneTheme.primary : ESDizyneTheme.darkSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _colorMode == m ? ESDizyneTheme.primary : ESDizyneTheme.darkBorder,
                        ),
                      ),
                      child: Text(
                        m.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: _colorMode == m ? Colors.white : ESDizyneTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )).toList(),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: ESDizyneTheme.textMuted)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _create,
                    child: const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(String label, int value, Function(int) onChanged) {
    return TextField(
      decoration: InputDecoration(labelText: label),
      style: const TextStyle(color: ESDizyneTheme.textPrimary),
      keyboardType: TextInputType.number,
      controller: TextEditingController(text: value.toString()),
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
    );
  }

  void _create() {
    final project = ESDProject(
      name: _nameController.text.isEmpty ? 'Untitled' : _nameController.text,
      width: _width,
      height: _height,
      dpi: _dpi,
      colorMode: _colorMode,
    );

    // Add default background layer
    project.layers.add(ESDLayer(
      name: 'Background',
      type: LayerType.pixel,
    ));

    Navigator.pop(context, project);
  }
}

class _Preset {
  final String name;
  final int width;
  final int height;
  const _Preset(this.name, this.width, this.height);
}

// ─────────────────────────────────────────────
// CANVAS RESIZE DIALOG
// ─────────────────────────────────────────────
class CanvasResizeDialog extends StatefulWidget {
  final ESDProject project;
  const CanvasResizeDialog({super.key, required this.project});

  @override
  State<CanvasResizeDialog> createState() => _CanvasResizeDialogState();
}

class _CanvasResizeDialogState extends State<CanvasResizeDialog> {
  late int _width;
  late int _height;
  bool _keepAspect = true;
  late double _ratio;

  @override
  void initState() {
    super.initState();
    _width = widget.project.width;
    _height = widget.project.height;
    _ratio = _width / _height;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ESDizyneTheme.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Canvas Size', style: TextStyle(
              color: ESDizyneTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: TextField(
                  decoration: const InputDecoration(labelText: 'Width (px)'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _width.toString()),
                  onChanged: (v) {
                    final w = int.tryParse(v);
                    if (w != null) {
                      setState(() {
                        _width = w;
                        if (_keepAspect) _height = (_width / _ratio).round();
                      });
                    }
                  },
                  style: const TextStyle(color: ESDizyneTheme.textPrimary),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextField(
                  decoration: const InputDecoration(labelText: 'Height (px)'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: _height.toString()),
                  onChanged: (v) {
                    final h = int.tryParse(v);
                    if (h != null) {
                      setState(() {
                        _height = h;
                        if (_keepAspect) _width = (_height * _ratio).round();
                      });
                    }
                  },
                  style: const TextStyle(color: ESDizyneTheme.textPrimary),
                )),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Switch(value: _keepAspect, onChanged: (v) => setState(() => _keepAspect = v)),
                const SizedBox(width: 8),
                const Text('Keep Aspect Ratio', style: TextStyle(color: ESDizyneTheme.textSecondary)),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: ESDizyneTheme.textMuted)),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.project.width = _width;
                    widget.project.height = _height;
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// COLOR MODE DIALOG
// ─────────────────────────────────────────────
class ColorModeDialog extends StatelessWidget {
  final ESDProject project;
  const ColorModeDialog({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ESDizyneTheme.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Color Mode', style: TextStyle(
              color: ESDizyneTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 16),
            ...ColorMode.values.map((m) => ListTile(
              leading: Radio<ColorMode>(
                value: m,
                groupValue: project.colorMode,
                activeColor: ESDizyneTheme.primary,
                onChanged: (v) {
                  project.colorMode = v!;
                  Navigator.pop(context);
                },
              ),
              title: Text(
                _colorModeLabel(m),
                style: const TextStyle(color: ESDizyneTheme.textPrimary),
              ),
              subtitle: Text(
                _colorModeDesc(m),
                style: const TextStyle(color: ESDizyneTheme.textMuted, fontSize: 11),
              ),
            )),
          ],
        ),
      ),
    );
  }

  String _colorModeLabel(ColorMode m) {
    switch (m) {
      case ColorMode.rgb: return 'RGB';
      case ColorMode.cmyk: return 'CMYK';
      case ColorMode.lab: return 'LAB';
      case ColorMode.greyscale: return 'Greyscale';
      case ColorMode.duotone: return 'Duotone';
    }
  }

  String _colorModeDesc(ColorMode m) {
    switch (m) {
      case ColorMode.rgb: return 'Screen, mobile, web';
      case ColorMode.cmyk: return 'Print, offset, digital print';
      case ColorMode.lab: return 'Color correction';
      case ColorMode.greyscale: return 'Black & white';
      case ColorMode.duotone: return 'Two-color printing';
    }
  }
}

// ─────────────────────────────────────────────
// DPI DIALOG
// ─────────────────────────────────────────────
class DPIDialog extends StatelessWidget {
  final ESDProject project;
  const DPIDialog({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final presets = [72, 96, 150, 300, 600, 1200];
    return Dialog(
      backgroundColor: ESDizyneTheme.darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DPI Settings', style: TextStyle(
              color: ESDizyneTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold,
            )),
            const SizedBox(height: 16),
            ...presets.map((d) => ListTile(
              leading: Radio<double>(
                value: d.toDouble(),
                groupValue: project.dpi,
                activeColor: ESDizyneTheme.primary,
                onChanged: (v) {
                  project.dpi = v!;
                  Navigator.pop(context);
                },
              ),
              title: Text('$d DPI', style: const TextStyle(color: ESDizyneTheme.textPrimary)),
              subtitle: Text(_dpiDesc(d), style: const TextStyle(color: ESDizyneTheme.textMuted, fontSize: 11)),
            )),
          ],
        ),
      ),
    );
  }

  String _dpiDesc(int dpi) {
    switch (dpi) {
      case 72: return 'Screen / Mobile';
      case 96: return 'Web / Windows';
      case 150: return 'Low print';
      case 300: return 'Standard print';
      case 600: return 'High quality print';
      case 1200: return 'Professional print';
      default: return '';
    }
  }
}
