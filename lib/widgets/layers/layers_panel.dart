// ═══════════════════════════════════════════════════════════
// LAYERS PANEL
// ═══════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../core/engine/canvas_engine.dart';
import '../../theme/app_theme.dart';

class LayersPanel extends StatefulWidget {
  final ESDProject project;
  final ESDCanvasEngine engine;
  const LayersPanel({super.key, required this.project, required this.engine});

  @override
  State<LayersPanel> createState() => _LayersPanelState();
}

class _LayersPanelState extends State<LayersPanel> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Layers header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Text('LAYERS', style: TextStyle(
                color: ESDizyneTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w600,
                letterSpacing: 1,
              )),
              const Spacer(),
              _layerBtn(Icons.add, () => _addLayer()),
              _layerBtn(Icons.folder, () => _addGroup()),
              _layerBtn(Icons.delete_outline, () => _deleteLayer()),
            ],
          ),
        ),

        // Blend mode & opacity
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: _BlendModeDropdown(
                  value: widget.engine.activeLayer?.blendMode ?? BlendMode.normal,
                  onChanged: (m) {
                    widget.engine.activeLayer?.blendMode = m;
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Opacity',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  style: const TextStyle(color: ESDizyneTheme.textPrimary, fontSize: 12),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(
                    text: '${((widget.engine.activeLayer?.opacity ?? 1.0) * 100).round()}',
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: ESDizyneTheme.darkBorder),

        // Layer list
        Expanded(
          child: ReorderableListView.builder(
            itemCount: widget.project.layers.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final layer = widget.project.layers.removeAt(oldIndex);
                widget.project.layers.insert(newIndex, layer);
              });
            },
            itemBuilder: (_, i) {
              final layer = widget.project.layers.reversed.toList()[i];
              return _LayerItem(
                key: ValueKey(layer.id),
                layer: layer,
                isSelected: widget.engine.activeLayer?.id == layer.id,
                onTap: () => setState(() => widget.engine.activeLayer = layer),
                onToggleVisibility: () => setState(() => layer.isVisible = !layer.isVisible),
                onToggleLock: () => setState(() => layer.isLocked = !layer.isLocked),
                onDuplicate: () => _duplicateLayer(layer),
                onDelete: () => _deleteSpecificLayer(layer),
                onRename: () => _renameLayer(layer),
                onEffects: () => _showLayerEffects(layer),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _layerBtn(IconData icon, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, size: 16),
      onPressed: onTap,
      color: ESDizyneTheme.textMuted,
      iconSize: 16,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }

  void _addLayer() {
    setState(() {
      widget.project.layers.add(ESDLayer(
        name: 'Layer ${widget.project.layers.length + 1}',
        type: LayerType.pixel,
      ));
    });
  }

  void _addGroup() {
    setState(() {
      widget.project.layers.add(ESDLayer(
        name: 'Group ${widget.project.layers.length + 1}',
        type: LayerType.group,
      ));
    });
  }

  void _deleteLayer() {
    if (widget.engine.activeLayer != null) {
      setState(() {
        widget.project.layers.removeWhere((l) => l.id == widget.engine.activeLayer!.id);
        widget.engine.activeLayer = widget.project.layers.isNotEmpty ? widget.project.layers.last : null;
      });
    }
  }

  void _deleteSpecificLayer(ESDLayer layer) {
    setState(() => widget.project.layers.remove(layer));
  }

  void _duplicateLayer(ESDLayer layer) {
    final newLayer = ESDLayer(
      name: '${layer.name} copy',
      type: layer.type,
      opacity: layer.opacity,
      blendMode: layer.blendMode,
      data: Map.from(layer.data),
    );
    setState(() {
      final index = widget.project.layers.indexOf(layer);
      widget.project.layers.insert(index + 1, newLayer);
    });
  }

  void _renameLayer(ESDLayer layer) {
    final controller = TextEditingController(text: layer.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ESDizyneTheme.darkCard,
        title: const Text('Rename Layer', style: TextStyle(color: ESDizyneTheme.textPrimary)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: ESDizyneTheme.textPrimary),
          decoration: const InputDecoration(hintText: 'Layer name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() => layer.name = controller.text);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLayerEffects(ESDLayer layer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ESDizyneTheme.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => LayerEffectsSheet(layer: layer),
    );
  }
}

class _LayerItem extends StatelessWidget {
  final ESDLayer layer;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onToggleVisibility;
  final VoidCallback onToggleLock;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onEffects;

  const _LayerItem({
    super.key,
    required this.layer,
    required this.isSelected,
    required this.onTap,
    required this.onToggleVisibility,
    required this.onToggleLock,
    required this.onDuplicate,
    required this.onDelete,
    required this.onRename,
    required this.onEffects,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showContextMenu(context),
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: isSelected ? ESDizyneTheme.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? ESDizyneTheme.primary.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Visibility toggle
            GestureDetector(
              onTap: onToggleVisibility,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  layer.isVisible ? Icons.visibility : Icons.visibility_off,
                  size: 14,
                  color: layer.isVisible ? ESDizyneTheme.textMuted : ESDizyneTheme.darkBorder,
                ),
              ),
            ),

            // Layer thumbnail
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: ESDizyneTheme.darkBorder,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(_layerIcon(layer.type), size: 14, color: ESDizyneTheme.textMuted),
            ),

            const SizedBox(width: 8),

            // Layer name
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    layer.name,
                    style: TextStyle(
                      color: isSelected ? ESDizyneTheme.primary : ESDizyneTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (layer.effects.isNotEmpty)
                    Text('fx', style: const TextStyle(
                      color: ESDizyneTheme.primary, fontSize: 10, fontStyle: FontStyle.italic,
                    )),
                ],
              ),
            ),

            // Lock toggle
            GestureDetector(
              onTap: onToggleLock,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  layer.isLocked ? Icons.lock : Icons.lock_open,
                  size: 12,
                  color: layer.isLocked ? ESDizyneTheme.warning : ESDizyneTheme.darkBorder,
                ),
              ),
            ),

            // Clipping mask indicator
            if (layer.isClippingMask)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.cut, size: 12, color: ESDizyneTheme.accent),
              ),

            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

  IconData _layerIcon(LayerType type) {
    switch (type) {
      case LayerType.pixel: return Icons.image;
      case LayerType.vector: return Icons.category;
      case LayerType.text: return Icons.text_fields;
      case LayerType.adjustment: return Icons.tune;
      case LayerType.group: return Icons.folder;
      case LayerType.smartObject: return Icons.smart_toy;
      case LayerType.fill: return Icons.format_color_fill;
    }
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ESDizyneTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Wrap(
        children: [
          ListTile(leading: const Icon(Icons.edit, color: ESDizyneTheme.textMuted), title: const Text('Rename', style: TextStyle(color: ESDizyneTheme.textPrimary)), onTap: () { Navigator.pop(context); onRename(); }),
          ListTile(leading: const Icon(Icons.copy, color: ESDizyneTheme.textMuted), title: const Text('Duplicate', style: TextStyle(color: ESDizyneTheme.textPrimary)), onTap: () { Navigator.pop(context); onDuplicate(); }),
          ListTile(leading: const Icon(Icons.auto_awesome, color: ESDizyneTheme.textMuted), title: const Text('Layer Effects', style: TextStyle(color: ESDizyneTheme.textPrimary)), onTap: () { Navigator.pop(context); onEffects(); }),
          ListTile(leading: const Icon(Icons.delete, color: ESDizyneTheme.error), title: const Text('Delete', style: TextStyle(color: ESDizyneTheme.error)), onTap: () { Navigator.pop(context); onDelete(); }),
        ],
      ),
    );
  }
}

class _BlendModeDropdown extends StatelessWidget {
  final BlendMode value;
  final Function(BlendMode) onChanged;
  const _BlendModeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: ESDizyneTheme.darkCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: ESDizyneTheme.darkBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<BlendMode>(
          value: value,
          isExpanded: true,
          dropdownColor: ESDizyneTheme.darkCard,
          style: const TextStyle(color: ESDizyneTheme.textPrimary, fontSize: 11),
          items: BlendMode.values.map((m) => DropdownMenuItem(
            value: m,
            child: Text(_blendModeLabel(m), style: const TextStyle(
              color: ESDizyneTheme.textPrimary, fontSize: 11,
            )),
          )).toList(),
          onChanged: (m) => m != null ? onChanged(m) : null,
        ),
      ),
    );
  }

  String _blendModeLabel(BlendMode m) {
    const labels = {
      BlendMode.normal: 'Normal',
      BlendMode.dissolve: 'Dissolve',
      BlendMode.darken: 'Darken',
      BlendMode.multiply: 'Multiply',
      BlendMode.colorBurn: 'Color Burn',
      BlendMode.linearBurn: 'Linear Burn',
      BlendMode.darkerColor: 'Darker Color',
      BlendMode.lighten: 'Lighten',
      BlendMode.screen: 'Screen',
      BlendMode.colorDodge: 'Color Dodge',
      BlendMode.linearDodge: 'Linear Dodge',
      BlendMode.lighterColor: 'Lighter Color',
      BlendMode.overlay: 'Overlay',
      BlendMode.softLight: 'Soft Light',
      BlendMode.hardLight: 'Hard Light',
      BlendMode.vividLight: 'Vivid Light',
      BlendMode.linearLight: 'Linear Light',
      BlendMode.pinLight: 'Pin Light',
      BlendMode.hardMix: 'Hard Mix',
      BlendMode.difference: 'Difference',
      BlendMode.exclusion: 'Exclusion',
      BlendMode.subtract: 'Subtract',
      BlendMode.divide: 'Divide',
      BlendMode.hue: 'Hue',
      BlendMode.saturation: 'Saturation',
      BlendMode.color: 'Color',
      BlendMode.luminosity: 'Luminosity',
    };
    return labels[m] ?? m.name;
  }
}

// ─────────────────────────────────────────────
// LAYER EFFECTS SHEET
// ─────────────────────────────────────────────
class LayerEffectsSheet extends StatefulWidget {
  final ESDLayer layer;
  const LayerEffectsSheet({super.key, required this.layer});

  @override
  State<LayerEffectsSheet> createState() => _LayerEffectsSheetState();
}

class _LayerEffectsSheetState extends State<LayerEffectsSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Layer Effects — ${widget.layer.name}', style: const TextStyle(
            color: ESDizyneTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: LayerEffectType.values.map((type) {
                final existing = widget.layer.effects.where((e) => e.type == type).firstOrNull;
                return _EffectToggle(
                  type: type,
                  isEnabled: existing?.isEnabled ?? false,
                  onToggle: (enabled) {
                    setState(() {
                      if (enabled) {
                        if (existing == null) {
                          widget.layer.effects.add(LayerEffect(type: type));
                        } else {
                          existing.isEnabled = true;
                        }
                      } else {
                        existing?.isEnabled = false;
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EffectToggle extends StatelessWidget {
  final LayerEffectType type;
  final bool isEnabled;
  final Function(bool) onToggle;
  const _EffectToggle({required this.type, required this.isEnabled, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: isEnabled,
      onChanged: onToggle,
      title: Text(_effectLabel(type), style: const TextStyle(
        color: ESDizyneTheme.textPrimary, fontSize: 13,
      )),
      activeColor: ESDizyneTheme.primary,
    );
  }

  String _effectLabel(LayerEffectType t) {
    switch (t) {
      case LayerEffectType.dropShadow: return 'Drop Shadow';
      case LayerEffectType.innerShadow: return 'Inner Shadow';
      case LayerEffectType.outerGlow: return 'Outer Glow';
      case LayerEffectType.innerGlow: return 'Inner Glow';
      case LayerEffectType.bevelEmboss: return 'Bevel & Emboss';
      case LayerEffectType.stroke: return 'Stroke';
      case LayerEffectType.colorOverlay: return 'Color Overlay';
      case LayerEffectType.gradientOverlay: return 'Gradient Overlay';
      case LayerEffectType.patternOverlay: return 'Pattern Overlay';
    }
  }
}
