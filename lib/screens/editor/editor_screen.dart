import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../core/engine/canvas_engine.dart';
import '../../theme/app_theme.dart';
import '../../widgets/canvas/canvas_widget.dart';
import '../../widgets/layers/layers_panel.dart';
import '../../widgets/tools/tools_panel.dart';
import '../../widgets/color/color_panel.dart';
import '../../widgets/brushes/brush_panel.dart';
import '../../widgets/artboards/artboards_panel.dart';
import '../../widgets/tools/top_toolbar.dart';
import '../../utils/project_manager.dart';
import '../../utils/export_manager.dart';

class EditorScreen extends StatefulWidget {
  final ESDProject project;
  const EditorScreen({super.key, required this.project});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> with TickerProviderStateMixin {
  late ESDCanvasEngine _engine;
  late TabController _rightPanelController;
  late TabController _leftPanelController;

  bool _showLeftPanel = true;
  bool _showRightPanel = true;
  bool _showBottomBar = true;
  bool _isFullscreen = false;

  final GlobalKey _canvasKey = GlobalKey();
  String _activeRightTab = 'layers';
  String _activeLeftTab = 'tools';

  // Auto-save timer
  late final Stream<int> _autoSaveStream;

  @override
  void initState() {
    super.initState();
    _engine = ESDCanvasEngine();
    _engine.canvasSize = Size(
      widget.project.width.toDouble(),
      widget.project.height.toDouble(),
    );

    _rightPanelController = TabController(length: 5, vsync: this);
    _leftPanelController = TabController(length: 3, vsync: this);

    // Set system UI
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Start auto-save every 3 minutes
    _autoSaveStream = Stream.periodic(const Duration(minutes: 3), (i) => i);
    _autoSaveStream.listen((_) => _autoSave());
  }

  @override
  void dispose() {
    _rightPanelController.dispose();
    _leftPanelController.dispose();
    super.dispose();
  }

  Future<void> _autoSave() async {
    await ProjectManager.autoSave(widget.project);
  }

  Future<void> _saveProject() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: ESDizyneTheme.primary),
      ),
    );

    try {
      await ProjectManager.saveProject(widget.project, format: SaveFormat.esdz);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Project saved!'),
            backgroundColor: ESDizyneTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: ESDizyneTheme.error,
          ),
        );
      }
    }
  }

  void _showExportDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ESDizyneTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => ExportBottomSheet(
        project: widget.project,
        canvasKey: _canvasKey,
      ),
    );
  }

  void _showSaveAsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ESDizyneTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SaveAsBottomSheet(project: widget.project),
    );
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      _showLeftPanel = !_isFullscreen;
      _showRightPanel = !_isFullscreen;
      _showBottomBar = !_isFullscreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _engine,
      child: Scaffold(
        backgroundColor: ESDizyneTheme.darkBg,
        body: SafeArea(
          child: Column(
            children: [
              // Top toolbar
              if (!_isFullscreen)
                TopToolbar(
                  project: widget.project,
                  engine: _engine,
                  onSave: _saveProject,
                  onExport: _showExportDialog,
                  onSaveAs: _showSaveAsDialog,
                  onToggleFullscreen: _toggleFullscreen,
                  onUndo: _engine.canUndo ? _engine.undo : null,
                  onRedo: _engine.canRedo ? _engine.redo : null,
                ),

              // Main editor area
              Expanded(
                child: Row(
                  children: [
                    // Left panel (Tools + Brushes)
                    if (_showLeftPanel) _buildLeftPanel(),

                    // Canvas area
                    Expanded(
                      child: Column(
                        children: [
                          // Canvas ruler horizontal
                          _buildRulerHorizontal(),

                          Expanded(
                            child: Row(
                              children: [
                                // Canvas ruler vertical
                                _buildRulerVertical(),

                                // Main canvas
                                Expanded(
                                  child: CanvasWidget(
                                    key: _canvasKey,
                                    project: widget.project,
                                    engine: _engine,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Canvas bottom status bar
                          if (_showBottomBar) _buildStatusBar(),
                        ],
                      ),
                    ),

                    // Right panel (Layers, Color, etc.)
                    if (_showRightPanel) _buildRightPanel(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 56,
      color: ESDizyneTheme.darkSurface,
      child: Column(
        children: [
          // Tool selector
          Expanded(
            child: ToolsPanel(engine: _engine),
          ),

          // Foreground/Background colors
          _buildColorSwatches(),
        ],
      ),
    );
  }

  Widget _buildColorSwatches() {
    return Consumer<ESDCanvasEngine>(
      builder: (_, engine, __) => Padding(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => _showColorPicker(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              children: [
                // Background color
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: ESDizyneTheme.darkBorder),
                    ),
                  ),
                ),
                // Foreground color
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: engine.activeColor.toFlutterColor(),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(1, 1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ESDizyneTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) => ColorPanel(
        engine: _engine,
        project: widget.project,
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      width: 280,
      color: ESDizyneTheme.darkSurface,
      child: Column(
        children: [
          // Panel tabs
          Container(
            color: ESDizyneTheme.darkCard,
            child: Row(
              children: [
                _rightPanelTab('layers', Icons.layers, 'Layers'),
                _rightPanelTab('color', Icons.palette, 'Color'),
                _rightPanelTab('brushes', Icons.brush, 'Brush'),
                _rightPanelTab('artboards', Icons.dashboard, 'Boards'),
                _rightPanelTab('history', Icons.history, 'History'),
              ],
            ),
          ),

          // Panel content
          Expanded(
            child: _buildRightPanelContent(),
          ),
        ],
      ),
    );
  }

  Widget _rightPanelTab(String id, IconData icon, String label) {
    final isActive = _activeRightTab == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeRightTab = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? ESDizyneTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? ESDizyneTheme.primary : ESDizyneTheme.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildRightPanelContent() {
    switch (_activeRightTab) {
      case 'layers':
        return LayersPanel(project: widget.project, engine: _engine);
      case 'color':
        return ColorPanel(engine: _engine, project: widget.project);
      case 'brushes':
        return BrushPanel(engine: _engine);
      case 'artboards':
        return ArtboardsPanel(project: widget.project, engine: _engine);
      case 'history':
        return _buildHistoryPanel();
      default:
        return const SizedBox();
    }
  }

  Widget _buildHistoryPanel() {
    return Consumer<ESDCanvasEngine>(
      builder: (_, engine, __) {
        final history = engine.history;
        return ListView.builder(
          itemCount: history.length,
          reverse: true,
          itemBuilder: (_, i) {
            final action = history[i];
            return ListTile(
              dense: true,
              leading: Icon(_historyIcon(action.type), size: 16, color: ESDizyneTheme.textMuted),
              title: Text(action.description,
                  style: const TextStyle(fontSize: 12, color: ESDizyneTheme.textSecondary)),
              subtitle: Text(
                _formatTime(action.timestamp),
                style: const TextStyle(fontSize: 10, color: ESDizyneTheme.textMuted),
              ),
              onTap: () {},
            );
          },
        );
      },
    );
  }

  IconData _historyIcon(HistoryActionType type) {
    switch (type) {
      case HistoryActionType.paintStroke: return Icons.brush;
      case HistoryActionType.addLayer: return Icons.add;
      case HistoryActionType.deleteLayer: return Icons.delete;
      case HistoryActionType.addText: return Icons.text_fields;
      case HistoryActionType.addShape: return Icons.crop_square;
      default: return Icons.history;
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  Widget _buildRulerHorizontal() {
    return Container(
      height: 20,
      color: ESDizyneTheme.darkCard,
      child: Consumer<ESDCanvasEngine>(
        builder: (_, engine, __) => CustomPaint(
          painter: RulerPainter(
            isHorizontal: true,
            zoom: engine.zoom,
            offset: engine.panOffset,
            canvasSize: engine.canvasSize,
          ),
        ),
      ),
    );
  }

  Widget _buildRulerVertical() {
    return Container(
      width: 20,
      color: ESDizyneTheme.darkCard,
      child: Consumer<ESDCanvasEngine>(
        builder: (_, engine, __) => CustomPaint(
          painter: RulerPainter(
            isHorizontal: false,
            zoom: engine.zoom,
            offset: engine.panOffset,
            canvasSize: engine.canvasSize,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Consumer<ESDCanvasEngine>(
      builder: (_, engine, __) => Container(
        height: 28,
        color: ESDizyneTheme.darkCard,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Zoom level
            GestureDetector(
              onTap: () => engine.zoomFit(MediaQuery.of(context).size),
              child: Text(
                '${(engine.zoom * 100).round()}%',
                style: const TextStyle(fontSize: 11, color: ESDizyneTheme.textMuted),
              ),
            ),
            const SizedBox(width: 16),

            // Canvas size
            Text(
              '${widget.project.width} × ${widget.project.height} px',
              style: const TextStyle(fontSize: 11, color: ESDizyneTheme.textMuted),
            ),
            const SizedBox(width: 16),

            // DPI
            Text(
              '${widget.project.dpi.round()} DPI',
              style: const TextStyle(fontSize: 11, color: ESDizyneTheme.textMuted),
            ),
            const SizedBox(width: 16),

            // Color mode
            Text(
              widget.project.colorMode.name.toUpperCase(),
              style: const TextStyle(fontSize: 11, color: ESDizyneTheme.textMuted),
            ),

            const Spacer(),

            // Grid toggle
            _statusBarIcon(
              Icons.grid_on,
              engine.showGrid,
              () => engine.toggleGrid(),
            ),

            // Guide toggle
            _statusBarIcon(
              Icons.straighten,
              engine.showGuides,
              () => engine.toggleGuides(),
            ),

            // Snap toggle
            _statusBarIcon(
              Icons.snooze,
              engine.snapToGrid,
              () => setState(() => engine.snapToGrid = !engine.snapToGrid),
            ),

            // Symmetry toggle
            _statusBarIcon(
              Icons.compare,
              engine.symmetryEnabled,
              () => setState(() => engine.symmetryEnabled = !engine.symmetryEnabled),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBarIcon(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Icon(
          icon,
          size: 14,
          color: isActive ? ESDizyneTheme.primary : ESDizyneTheme.textMuted,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// RULER PAINTER
// ─────────────────────────────────────────────
class RulerPainter extends CustomPainter {
  final bool isHorizontal;
  final double zoom;
  final Offset offset;
  final Size canvasSize;

  RulerPainter({
    required this.isHorizontal,
    required this.zoom,
    required this.offset,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ESDizyneTheme.textMuted
      ..strokeWidth = 0.5;

    final textStyle = const TextStyle(
      color: ESDizyneTheme.textMuted,
      fontSize: 8,
    );

    // Determine tick spacing based on zoom
    double step = 100;
    if (zoom > 2) step = 50;
    if (zoom > 4) step = 25;
    if (zoom < 0.5) step = 200;
    if (zoom < 0.25) step = 500;

    if (isHorizontal) {
      final startX = -offset.dx / zoom;
      final endX = startX + size.width / zoom;

      for (double x = (startX / step).floor() * step; x <= endX; x += step) {
        final screenX = x * zoom + offset.dx;
        if (screenX < 0 || screenX > size.width) continue;

        canvas.drawLine(
          Offset(screenX, size.height - 8),
          Offset(screenX, size.height),
          paint,
        );

        final tp = TextPainter(
          text: TextSpan(text: x.round().toString(), style: textStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(screenX + 2, 0));
      }
    } else {
      final startY = -offset.dy / zoom;
      final endY = startY + size.height / zoom;

      for (double y = (startY / step).floor() * step; y <= endY; y += step) {
        final screenY = y * zoom + offset.dy;
        if (screenY < 0 || screenY > size.height) continue;

        canvas.drawLine(
          Offset(size.width - 8, screenY),
          Offset(size.width, screenY),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(RulerPainter old) =>
      zoom != old.zoom || offset != old.offset;
}

// ─────────────────────────────────────────────
// EXPORT BOTTOM SHEET
// ─────────────────────────────────────────────
class ExportBottomSheet extends StatefulWidget {
  final ESDProject project;
  final GlobalKey canvasKey;
  const ExportBottomSheet({super.key, required this.project, required this.canvasKey});

  @override
  State<ExportBottomSheet> createState() => _ExportBottomSheetState();
}

class _ExportBottomSheetState extends State<ExportBottomSheet> {
  ExportFormat _format = ExportFormat.png;
  double _scale = 1.0;
  int _quality = 95;
  int _dpi = 72;
  bool _transparent = true;
  bool _exportAll = false;
  bool _zipExports = false;
  bool _isExporting = false;
  String _filenameTemplate = '{name}';

  final _formats = [
    ExportFormat.png, ExportFormat.jpg, ExportFormat.tiff,
    ExportFormat.svg, ExportFormat.webp, ExportFormat.pdf,
    ExportFormat.eps, ExportFormat.bmp, ExportFormat.gif,
    ExportFormat.avif, ExportFormat.heic, ExportFormat.psd,
    ExportFormat.plp, ExportFormat.afdesign, ExportFormat.esdz,
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.all(20),
        child: ListView(
          controller: controller,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: ESDizyneTheme.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const Text('Export', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: ESDizyneTheme.textPrimary,
            )),
            const SizedBox(height: 20),

            // Format selector
            const Text('Format', style: TextStyle(color: ESDizyneTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _formats.map((f) {
                final isSelected = _format == f;
                return GestureDetector(
                  onTap: () => setState(() => _format = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? ESDizyneTheme.primary : ESDizyneTheme.darkCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? ESDizyneTheme.primary : ESDizyneTheme.darkBorder,
                      ),
                    ),
                    child: Text(
                      f.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : ESDizyneTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Scale
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Scale', style: TextStyle(color: ESDizyneTheme.textSecondary, fontSize: 13)),
                Text('${_scale}x', style: const TextStyle(color: ESDizyneTheme.primary, fontSize: 13)),
              ],
            ),
            Slider(
              value: _scale,
              min: 0.25,
              max: 4.0,
              divisions: 15,
              onChanged: (v) => setState(() => _scale = v),
            ),

            // DPI
            const Text('DPI', style: TextStyle(color: ESDizyneTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [72, 96, 150, 300, 600].map((d) {
                return GestureDetector(
                  onTap: () => setState(() => _dpi = d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _dpi == d ? ESDizyneTheme.primary : ESDizyneTheme.darkCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _dpi == d ? ESDizyneTheme.primary : ESDizyneTheme.darkBorder,
                      ),
                    ),
                    child: Text('$d', style: TextStyle(
                      fontSize: 12,
                      color: _dpi == d ? Colors.white : ESDizyneTheme.textSecondary,
                    )),
                  ),
                );
              }).toList(),
            ),

            if (_format == ExportFormat.jpg) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quality', style: TextStyle(color: ESDizyneTheme.textSecondary, fontSize: 13)),
                  Text('$_quality%', style: const TextStyle(color: ESDizyneTheme.primary, fontSize: 13)),
                ],
              ),
              Slider(
                value: _quality.toDouble(),
                min: 1,
                max: 100,
                divisions: 99,
                onChanged: (v) => setState(() => _quality = v.round()),
              ),
            ],

            const SizedBox(height: 16),

            // Options
            _buildSwitch('Transparent background', _transparent, (v) => setState(() => _transparent = v)),
            _buildSwitch('Export all artboards', _exportAll, (v) => setState(() => _exportAll = v)),
            _buildSwitch('ZIP all exports', _zipExports, (v) => setState(() => _zipExports = v)),

            const SizedBox(height: 20),

            // Filename template
            TextField(
              decoration: const InputDecoration(
                labelText: 'Filename template',
                hintText: '{name}, {artboard}, {date}, {dpi}',
              ),
              onChanged: (v) => _filenameTemplate = v,
              controller: TextEditingController(text: _filenameTemplate),
            ),

            const SizedBox(height: 24),

            // Export button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isExporting ? null : _startExport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ESDizyneTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isExporting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Export', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: ESDizyneTheme.textSecondary, fontSize: 13)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Future<void> _startExport() async {
    setState(() => _isExporting = true);

    try {
      final settings = ExportSettings(
        format: _format,
        scale: _scale,
        dpi: _dpi,
        quality: _quality,
        transparent: _transparent,
        exportAllArtboards: _exportAll,
        zipExports: _zipExports,
        filenameTemplate: _filenameTemplate,
      );

      final files = await ExportManager.exportProject(
        project: widget.project,
        settings: settings,
        canvasKey: widget.canvasKey,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${files.length} file(s)'),
            backgroundColor: ESDizyneTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: ESDizyneTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

// ─────────────────────────────────────────────
// SAVE AS BOTTOM SHEET
// ─────────────────────────────────────────────
class SaveAsBottomSheet extends StatefulWidget {
  final ESDProject project;
  const SaveAsBottomSheet({super.key, required this.project});

  @override
  State<SaveAsBottomSheet> createState() => _SaveAsBottomSheetState();
}

class _SaveAsBottomSheetState extends State<SaveAsBottomSheet> {
  SaveFormat _format = SaveFormat.esdz;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Save As', style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: ESDizyneTheme.textPrimary,
          )),
          const SizedBox(height: 20),

          // Format options
          ...SaveFormat.values.map((f) => RadioListTile<SaveFormat>(
            value: f,
            groupValue: _format,
            onChanged: (v) => setState(() => _format = v!),
            title: Text(_formatLabel(f), style: const TextStyle(color: ESDizyneTheme.textPrimary)),
            subtitle: Text(_formatDesc(f), style: const TextStyle(color: ESDizyneTheme.textMuted, fontSize: 11)),
            activeColor: ESDizyneTheme.primary,
          )),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Save as ${_format.name.toUpperCase()}'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(SaveFormat f) {
    switch (f) {
      case SaveFormat.esdz: return 'ES Dizyne (.esdz)';
      case SaveFormat.psd: return 'Photoshop (.psd)';
      case SaveFormat.plp: return 'PixelLab (.plp)';
      case SaveFormat.afdesign: return 'Affinity Designer (.afdesign)';
      case SaveFormat.afphoto: return 'Affinity Photo (.afphoto)';
      case SaveFormat.pdf: return 'PDF (.pdf)';
      case SaveFormat.eps: return 'EPS (.eps)';
      case SaveFormat.svg: return 'SVG (.svg)';
    }
  }

  String _formatDesc(SaveFormat f) {
    switch (f) {
      case SaveFormat.esdz: return 'Native format — lightweight & fully editable';
      case SaveFormat.psd: return 'Open in Adobe Photoshop with full layers';
      case SaveFormat.plp: return 'Open in PixelLab with full layers';
      case SaveFormat.afdesign: return 'Open in Affinity Designer';
      case SaveFormat.afphoto: return 'Open in Affinity Photo';
      case SaveFormat.pdf: return 'PDF with editable layers';
      case SaveFormat.eps: return 'EPS vector format';
      case SaveFormat.svg: return 'SVG scalable vector format';
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await ProjectManager.saveProject(widget.project, format: _format);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
