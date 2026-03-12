    _ArtboardPreset('Poster A2', 4961, 7016),
    _ArtboardPreset('Banner Web', 2560, 640),
    _ArtboardPreset('Email Header', 600, 200),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Text('ARTBOARDS', style: TextStyle(
                color: ESDizyneTheme.textMuted, fontSize: 11,
                fontWeight: FontWeight.w600, letterSpacing: 1,
              )),
              const Spacer(),
              GestureDetector(
                onTap: _addArtboard,
                child: const Icon(Icons.add, size: 18, color: ESDizyneTheme.primary),
              ),
            ],
          ),
        ),

        // Artboard list
        Expanded(
          child: widget.project.artboards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.dashboard_outlined, size: 40, color: ESDizyneTheme.textMuted),
                      const SizedBox(height: 8),
                      const Text('No artboards', style: TextStyle(color: ESDizyneTheme.textMuted)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _addArtboard,
                        child: const Text('Add Artboard'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: widget.project.artboards.length,
                  itemBuilder: (_, i) {
                    final ab = widget.project.artboards[i];
                    final isSelected = _selectedArtboardId == ab.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedArtboardId = ab.id),
                      onLongPress: () => _showArtboardMenu(ab),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ESDizyneTheme.primary.withOpacity(0.15)
                              : ESDizyneTheme.darkCard,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? ESDizyneTheme.primary : ESDizyneTheme.darkBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 24,
                              decoration: BoxDecoration(
                                color: ab.backgroundColor,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: ESDizyneTheme.darkBorder),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ab.name, style: TextStyle(
                                    color: isSelected ? ESDizyneTheme.primary : ESDizyneTheme.textPrimary,
                                    fontSize: 12, fontWeight: FontWeight.w500,
                                  )),
                                  Text('${ab.width.round()} × ${ab.height.round()}',
                                    style: const TextStyle(
                                      color: ESDizyneTheme.textMuted, fontSize: 10,
                                    )),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert, size: 14),
                              color: ESDizyneTheme.textMuted,
                              onPressed: () => _showArtboardMenu(ab),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _addArtboard() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ESDizyneTheme.darkCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddArtboardSheet(
        presets: _artboardPresets,
        onAdd: (ab) {
          setState(() => widget.project.artboards.add(ab));
        },
      ),
    );
  }

  void _showArtboardMenu(ESDArtboard ab) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ESDizyneTheme.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: ESDizyneTheme.textMuted),
            title: const Text('Rename', style: TextStyle(color: ESDizyneTheme.textPrimary)),
            onTap: () { Navigator.pop(context); _renameArtboard(ab); },
          ),
          ListTile(
            leading: const Icon(Icons.copy, color: ESDizyneTheme.textMuted),
            title: const Text('Duplicate', style: TextStyle(color: ESDizyneTheme.textPrimary)),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                widget.project.artboards.add(ESDArtboard(
                  name: '${ab.name} copy',
                  x: ab.x + 20, y: ab.y + 20,
                  width: ab.width, height: ab.height,
                  backgroundColor: ab.backgroundColor,
                ));
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload, color: ESDizyneTheme.textMuted),
            title: const Text('Export', style: TextStyle(color: ESDizyneTheme.textPrimary)),
            onTap: () { Navigator.pop(context); },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: ESDizyneTheme.error),
            title: const Text('Delete', style: TextStyle(color: ESDizyneTheme.error)),
            onTap: () {
              Navigator.pop(context);
              setState(() => widget.project.artboards.remove(ab));
            },
          ),
        ],
      ),
    );
  }

  void _renameArtboard(ESDArtboard ab) {
    final ctrl = TextEditingController(text: ab.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ESDizyneTheme.darkCard,
        title: const Text('Rename Artboard', style: TextStyle(color: ESDizyneTheme.textPrimary)),
        content: TextField(controller: ctrl, autofocus: true,
          style: const TextStyle(color: ESDizyneTheme.textPrimary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            setState(() => ab.name = ctrl.text);
            Navigator.pop(context);
          }, child: const Text('OK')),
        ],
      ),
    );
  }
}

class _ArtboardPreset {
  final String name;
  final double width, height;
  const _ArtboardPreset(this.name, this.width, this.height);
}

class _AddArtboardSheet extends StatefulWidget {
  final List<_ArtboardPreset> presets;
  final Function(ESDArtboard) onAdd;
  const _AddArtboardSheet({required this.presets, required this.onAdd});

  @override
  State<_AddArtboardSheet> createState() => _AddArtboardSheetState();
}

class _AddArtboardSheetState extends State<_AddArtboardSheet> {
  double _w = 1080, _h = 1080;
  String _name = 'Artboard 1';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Artboard', style: TextStyle(
            color: ESDizyneTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 16),

          TextField(
            controller: TextEditingController(text: _name),
            onChanged: (v) => _name = v,
            decoration: const InputDecoration(labelText: 'Name'),
            style: const TextStyle(color: ESDizyneTheme.textPrimary),
          ),
          const SizedBox(height: 12),

          const Text('Presets', style: TextStyle(color: ESDizyneTheme.textMuted, fontSize: 12)),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.presets.length,
              itemBuilder: (_, i) {
                final p = widget.presets[i];
                return GestureDetector(
                  onTap: () => setState(() { _w = p.width; _h = p.height; _name = p.name; }),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ESDizyneTheme.darkSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: ESDizyneTheme.darkBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.dashboard, size: 20, color: ESDizyneTheme.textMuted),
                        const SizedBox(height: 4),
                        Text(p.name, textAlign: TextAlign.center, style: const TextStyle(
                          fontSize: 9, color: ESDizyneTheme.textSecondary,
                        )),
                        Text('${p.width.round()}×${p.height.round()}', style: const TextStyle(
                          fontSize: 8, color: ESDizyneTheme.textMuted,
                        )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onAdd(ESDArtboard(name: _name, width: _w, height: _h));
                Navigator.pop(context);
              },
              child: const Text('Add Artboard'),
            ),
          ),
        ],
      ),
    );
  }
}
