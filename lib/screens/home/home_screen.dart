import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../utils/project_manager.dart';
import '../../theme/app_theme.dart';
import '../editor/editor_screen.dart';
import '../../widgets/tools/top_toolbar.dart';
import 'package:file_picker/file_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ProjectMeta> _projects = [];
  bool _isLoading = true;
  bool _isGrid = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await ProjectManager.listProjects();
    setState(() { _projects = projects; _isLoading = false; });
  }

  List<ProjectMeta> get _filteredProjects {
    if (_searchQuery.isEmpty) return _projects;
    return _projects.where((p) =>
      p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ESDizyneTheme.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: ESDizyneTheme.primary))
                  : _filteredProjects.isEmpty
                      ? _buildEmptyState()
                      : _isGrid ? _buildGrid() : _buildList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewProjectDialog,
        backgroundColor: ESDizyneTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              gradient: ESDizyneGradients.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('ES', style: TextStyle(
                color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.bold, letterSpacing: 1,
              )),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => ESDizyneGradients.primaryGradient.createShader(bounds),
                child: const Text('ES Dizyne', style: TextStyle(
                  color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.bold, letterSpacing: 0.5,
                )),
              ),
              const Text('Professional Design Suite', style: TextStyle(
                color: ESDizyneTheme.textMuted, fontSize: 11,
              )),
            ],
          ),
          const Spacer(),
          // View toggle
          IconButton(
            icon: Icon(_isGrid ? Icons.list : Icons.grid_view, color: ESDizyneTheme.textMuted),
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
          // Open file
          IconButton(
            icon: const Icon(Icons.folder_open, color: ESDizyneTheme.textMuted),
            onPressed: _openFile,
            tooltip: 'Open File',
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: ESDizyneTheme.textMuted),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(color: ESDizyneTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search projects...',
          prefixIcon: const Icon(Icons.search, size: 18, color: ESDizyneTheme.textMuted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  color: ESDizyneTheme.textMuted,
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              gradient: ESDizyneGradients.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.dashboard_customize, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text('No projects yet', style: TextStyle(
            color: ESDizyneTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 8),
          const Text('Create your first design or open an existing file',
            textAlign: TextAlign.center,
            style: TextStyle(color: ESDizyneTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _showNewProjectDialog,
                icon: const Icon(Icons.add),
                label: const Text('New Project'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _openFile,
                icon: const Icon(Icons.folder_open, color: ESDizyneTheme.textSecondary),
                label: const Text('Open File', style: TextStyle(color: ESDizyneTheme.textSecondary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: ESDizyneTheme.darkBorder),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return RefreshIndicator(
      onRefresh: _loadProjects,
      color: ESDizyneTheme.primary,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredProjects.length,
        itemBuilder: (_, i) => _ProjectCard(
          meta: _filteredProjects[i],
          onTap: () => _openProject(_filteredProjects[i]),
          onDelete: () => _deleteProject(_filteredProjects[i]),
          onDuplicate: () => {},
          onBackup: () => _backupProject(_filteredProjects[i]),
        ),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadProjects,
      color: ESDizyneTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredProjects.length,
        itemBuilder: (_, i) {
          final meta = _filteredProjects[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: ESDizyneTheme.darkCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ESDizyneTheme.darkBorder),
              ),
              child: const Icon(Icons.image, color: ESDizyneTheme.textMuted, size: 20),
            ),
            title: Text(meta.name, style: const TextStyle(
              color: ESDizyneTheme.textPrimary, fontWeight: FontWeight.w500,
            )),
            subtitle: Text(
              '${meta.width}×${meta.height} · ${meta.dpi.round()} DPI · ${_formatDate(meta.modifiedAt)}',
              style: const TextStyle(color: ESDizyneTheme.textMuted, fontSize: 11),
            ),
            onTap: () => _openProject(meta),
            trailing: PopupMenuButton(
              color: ESDizyneTheme.darkCard,
              itemBuilder: (_) => [
                _popupItem(Icons.open_in_new, 'Open', () => _openProject(meta)),
                _popupItem(Icons.backup, 'Backup', () => _backupProject(meta)),
                _popupItem(Icons.delete, 'Delete', () => _deleteProject(meta)),
              ],
            ),
          );
        },
      ),
    );
  }

  PopupMenuItem _popupItem(IconData icon, String label, VoidCallback onTap) {
    return PopupMenuItem(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: ESDizyneTheme.textMuted),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: ESDizyneTheme.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _showNewProjectDialog() async {
    final project = await showDialog<ESDProject>(
      context: context,
      builder: (_) => const NewProjectDialog(),
    );
    if (project != null && mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => EditorScreen(project: project),
      )).then((_) => _loadProjects());
    }
  }

  Future<void> _openFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'esdz', 'psd', 'plp', 'afdesign', 'afphoto', 'afpub', 'af',
        'pdf', 'eps', 'svg', 'png', 'jpg', 'jpeg', 'tiff', 'tif',
        'webp', 'bmp', 'gif', 'heic', 'avif', 'cr2', 'cr3', 'nef',
        'arw', 'raf', 'orf', 'rw2', 'dng',
      ],
    );

    if (result != null && result.files.single.path != null) {
      final project = await ProjectManager.openProject(result.files.single.path!);
      if (project != null && mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => EditorScreen(project: project),
        )).then((_) => _loadProjects());
      }
    }
  }

  Future<void> _openProject(ProjectMeta meta) async {
    final project = await ProjectManager.openProject(meta.filePath);
    if (project != null && mounted) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => EditorScreen(project: project),
      )).then((_) => _loadProjects());
    }
  }

  Future<void> _deleteProject(ProjectMeta meta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ESDizyneTheme.darkCard,
        title: const Text('Delete Project', style: TextStyle(color: ESDizyneTheme.textPrimary)),
        content: Text('Delete "${meta.name}"? This cannot be undone.',
          style: const TextStyle(color: ESDizyneTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: ESDizyneTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ProjectManager.deleteProject(meta.filePath);
      _loadProjects();
    }
  }

  Future<void> _backupProject(ProjectMeta meta) async {
    final project = await ProjectManager.openProject(meta.filePath);
    if (project != null) {
      await ProjectManager.backupProject(project);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Backup created!'),
          backgroundColor: ESDizyneTheme.success,
        ));
      }
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─────────────────────────────────────────────
// PROJECT CARD
// ─────────────────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final ProjectMeta meta;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onBackup;

  const _ProjectCard({
    required this.meta,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
    required this.onBackup,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ESDizyneTheme.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ESDizyneTheme.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ESDizyneTheme.darkSurface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: meta.thumbnailPath != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.asset(meta.thumbnailPath!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                gradient: ESDizyneGradients.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.image, color: Colors.white, size: 24),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(meta.name, style: const TextStyle(
                          color: ESDizyneTheme.textPrimary,
                          fontSize: 12, fontWeight: FontWeight.w600,
                        ), overflow: TextOverflow.ellipsis),
                      ),
                      PopupMenuButton(
                        color: ESDizyneTheme.darkCard,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.more_horiz, size: 14, color: ESDizyneTheme.textMuted),
                        itemBuilder: (_) => [
                          PopupMenuItem(onTap: onBackup, child: const Row(children: [
                            Icon(Icons.backup, size: 14, color: ESDizyneTheme.textMuted),
                            SizedBox(width: 8),
                            Text('Backup', style: TextStyle(color: ESDizyneTheme.textPrimary, fontSize: 12)),
                          ])),
                          PopupMenuItem(onTap: onDelete, child: const Row(children: [
                            Icon(Icons.delete, size: 14, color: ESDizyneTheme.error),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: ESDizyneTheme.error, fontSize: 12)),
                          ])),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${meta.width}×${meta.height}',
                    style: const TextStyle(color: ESDizyneTheme.textMuted, fontSize: 10),
                  ),
                  Text(
                    _formatDate(meta.modifiedAt),
                    style: const TextStyle(color: ESDizyneTheme.textMuted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
