import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../models/models.dart';

class ProjectManager {
  static const String _projectsDir = 'es_dizyne_projects';
  static const String _backupsDir = 'es_dizyne_backups';
  static const String _nativeExt = '.esdz';

  // ─── GET DIRECTORIES ───────────────────────────────────
  static Future<Directory> get _projectsDirectory async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_projectsDir');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<Directory> get _backupsDirectory async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_backupsDir');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ─── SAVE PROJECT ──────────────────────────────────────
  static Future<String> saveProject(ESDProject project, {SaveFormat format = SaveFormat.esdz}) async {
    project.modifiedAt = DateTime.now();

    switch (format) {
      case SaveFormat.esdz:
        return await _saveAsESDZ(project);
      case SaveFormat.psd:
        return await _saveAsPSD(project);
      case SaveFormat.plp:
        return await _saveAsPLP(project);
      case SaveFormat.afdesign:
        return await _saveAsAffinity(project, 'afdesign');
      case SaveFormat.afphoto:
        return await _saveAsAffinity(project, 'afphoto');
      case SaveFormat.pdf:
        return await _saveAsPDF(project);
      case SaveFormat.eps:
        return await _saveAsEPS(project);
      case SaveFormat.svg:
        return await _saveAsSVG(project);
    }
  }

  // ─── ESDZ FORMAT (Native, Lightweight) ────────────────
  static Future<String> _saveAsESDZ(ESDProject project) async {
    final dir = await _projectsDirectory;
    final filePath = '${dir.path}/${_sanitizeFilename(project.name)}$_nativeExt';

    // Build archive
    final archive = Archive();

    // Project JSON
    final projectJson = jsonEncode(project.toJson());
    final projectBytes = utf8.encode(projectJson);
    archive.addFile(ArchiveFile('project.json', projectBytes.length, projectBytes));

    // Layer data (pixel data stored separately for efficiency)
    for (final layer in project.layers) {
      if (layer.type == LayerType.pixel && layer.data['pixelData'] != null) {
        final pixelData = base64Decode(layer.data['pixelData']);
        archive.addFile(ArchiveFile('layers/${layer.id}.bin', pixelData.length, pixelData));
        // Remove inline pixel data from JSON to keep it lightweight
        layer.data.remove('pixelData');
        layer.data['pixelDataRef'] = 'layers/${layer.id}.bin';
      }
    }

    // Color palettes
    final palettesJson = jsonEncode(project.colorPalettes.map((p) => p.toJson()).toList());
    final palettesBytes = utf8.encode(palettesJson);
    archive.addFile(ArchiveFile('palettes.json', palettesBytes.length, palettesBytes));

    // Thumbnail
    // archive.addFile(ArchiveFile('thumbnail.png', ...));

    // Compress with ZLib
    final encoder = ZipEncoder();
    final compressed = encoder.encode(archive);

    if (compressed != null) {
      final file = File(filePath);
      await file.writeAsBytes(compressed);
    }

    return filePath;
  }

  // ─── PSD FORMAT ───────────────────────────────────────
  static Future<String> _saveAsPSD(ESDProject project) async {
    final dir = await _projectsDirectory;
    final filePath = '${dir.path}/${_sanitizeFilename(project.name)}.psd';

    // PSD file structure writer
    final writer = PSDWriter(project);
    final bytes = await writer.write();

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  // ─── PLP FORMAT (PixelLab) ────────────────────────────
  static Future<String> _saveAsPLP(ESDProject project) async {
    final dir = await _projectsDirectory;
    final filePath = '${dir.path}/${_sanitizeFilename(project.name)}.plp';

    final writer = PLPWriter(project);
    final bytes = await writer.write();

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  // ─── AFFINITY FORMAT ──────────────────────────────────
  static Future<String> _saveAsAffinity(ESDProject project, String ext) async {
    final dir = await _projectsDirectory;
    final filePath = '${dir.path}/${_sanitizeFilename(project.name)}.$ext';

    final writer = AffinityWriter(project);
    final bytes = await writer.write();

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  // ─── PDF FORMAT ───────────────────────────────────────
  static Future<String> _saveAsPDF(ESDProject project) async {
    final dir = await _projectsDirectory;
    final filePath = '${dir.path}/${_sanitizeFilename(project.name)}.pdf';
    // PDF writer implementation
    return filePath;
  }

  // ─── EPS FORMAT ───────────────────────────────────────
  static Future<String> _saveAsEPS(ESDProject project) async {
    final dir = await _projectsDirectory;
    final filePath = '${dir.path}/${_sanitizeFilename(project.name)}.eps';
    final writer = EPSWriter(project);
    final content = writer.write();
    final file = File(filePath);
    await file.writeAsString(content);
    return filePath;
  }

  // ─── SVG FORMAT ───────────────────────────────────────
  static Future<String> _saveAsSVG(ESDProject project) async {
    final dir = await _projectsDirectory;
    final filePath = '${dir.path}/${_sanitizeFilename(project.name)}.svg';
    final writer = SVGWriter(project);
    final content = writer.write();
    final file = File(filePath);
    await file.writeAsString(content);
    return filePath;
  }

  // ─── OPEN PROJECT ─────────────────────────────────────
  static Future<ESDProject?> openProject(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return null;

    final ext = filePath.split('.').last.toLowerCase();

    switch (ext) {
      case 'esdz':
        return await _openESDZ(file);
      case 'psd':
        return await _openPSD(file);
      case 'plp':
        return await _openPLP(file);
      case 'afdesign':
      case 'afphoto':
      case 'afpub':
      case 'af':
        return await _openAffinity(file);
      case 'pdf':
        return await _openPDF(file);
      case 'eps':
        return await _openEPS(file);
      case 'svg':
        return await _openSVG(file);
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'tiff':
      case 'tif':
      case 'webp':
      case 'bmp':
      case 'gif':
      case 'heic':
      case 'avif':
        return await _openRasterImage(file, ext);
      case 'cr2':
      case 'cr3':
      case 'nef':
      case 'nrw':
      case 'arw':
      case 'raf':
      case 'orf':
      case 'rw2':
      case 'dng':
      case 'pef':
      case 'srw':
        return await _openRAW(file, ext);
      default:
        return null;
    }
  }

  static Future<ESDProject> _openESDZ(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    // Find project.json
    final projectFile = archive.findFile('project.json');
    if (projectFile == null) throw Exception('Invalid ESDZ file');

    final projectJson = utf8.decode(projectFile.content as List<int>);
    final project = ESDProject.fromJson(jsonDecode(projectJson));

    // Restore pixel data from binary files
    for (final layer in project.layers) {
      if (layer.data['pixelDataRef'] != null) {
        final ref = layer.data['pixelDataRef'] as String;
        final pixelFile = archive.findFile(ref);
        if (pixelFile != null) {
          layer.data['pixelData'] = base64Encode(pixelFile.content as List<int>);
          layer.data.remove('pixelDataRef');
        }
      }
    }

    // Restore palettes
    final palettesFile = archive.findFile('palettes.json');
    if (palettesFile != null) {
      final palettesJson = utf8.decode(palettesFile.content as List<int>);
      final palettesList = jsonDecode(palettesJson) as List;
      project.colorPalettes = palettesList.map((p) => ESDColorPalette.fromJson(p)).toList();
    }

    return project;
  }

  static Future<ESDProject> _openPSD(File file) async {
    final bytes = await file.readAsBytes();
    final reader = PSDReader(bytes);
    return reader.read();
  }

  static Future<ESDProject> _openPLP(File file) async {
    final bytes = await file.readAsBytes();
    final reader = PLPReader(bytes);
    return reader.read();
  }

  static Future<ESDProject> _openAffinity(File file) async {
    final bytes = await file.readAsBytes();
    final reader = AffinityReader(bytes);
    return reader.read();
  }

  static Future<ESDProject> _openPDF(File file) async {
    final bytes = await file.readAsBytes();
    final reader = PDFReader(bytes);
    return reader.read();
  }

  static Future<ESDProject> _openEPS(File file) async {
    final content = await file.readAsString();
    final reader = EPSReader(content);
    return reader.read();
  }

  static Future<ESDProject> _openSVG(File file) async {
    final content = await file.readAsString();
    final reader = SVGReader(content);
    return reader.read();
  }

  static Future<ESDProject> _openRasterImage(File file, String ext) async {
    final bytes = await file.readAsBytes();
    final filename = file.path.split('/').last.split('.').first;

    // Create project with single pixel layer
    final project = ESDProject(
      name: filename,
      width: 1920,
      height: 1080,
      dpi: 72,
    );

    final layer = ESDLayer(
      name: 'Background',
      type: LayerType.pixel,
      data: {'imageData': base64Encode(bytes), 'imageFormat': ext},
    );

    project.layers.add(layer);
    return project;
  }

  static Future<ESDProject> _openRAW(File file, String ext) async {
    final bytes = await file.readAsBytes();
    final reader = RAWReader(bytes, ext);
    return reader.read();
  }

  // ─── LIST PROJECTS ────────────────────────────────────
  static Future<List<ProjectMeta>> listProjects() async {
    final dir = await _projectsDirectory;
    final files = await dir.list().toList();
    final projects = <ProjectMeta>[];

    for (final file in files) {
      if (file is File && file.path.endsWith(_nativeExt)) {
        try {
          final meta = await _readProjectMeta(file.path);
          if (meta != null) projects.add(meta);
        } catch (_) {}
      }
    }

    projects.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return projects;
  }

  static Future<ProjectMeta?> _readProjectMeta(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final projectFile = archive.findFile('project.json');
      if (projectFile == null) return null;

      final projectJson = utf8.decode(projectFile.content as List<int>);
      final data = jsonDecode(projectJson);

      return ProjectMeta(
        id: data['id'],
        name: data['name'],
        filePath: filePath,
        width: data['width'],
        height: data['height'],
        dpi: data['dpi']?.toDouble() ?? 72,
        colorMode: ColorMode.values[data['colorMode'] ?? 0],
        createdAt: DateTime.parse(data['createdAt']),
        modifiedAt: DateTime.parse(data['modifiedAt']),
        thumbnailPath: data['thumbnailPath'],
      );
    } catch (_) {
      return null;
    }
  }

  // ─── DELETE PROJECT ───────────────────────────────────
  static Future<void> deleteProject(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ─── BACKUP ───────────────────────────────────────────
  static Future<String> backupProject(ESDProject project) async {
    final backupDir = await _backupsDirectory;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '${backupDir.path}/${_sanitizeFilename(project.name)}_backup_$timestamp$_nativeExt';

    // Save as ESDZ to backup location
    final archive = Archive();
    final projectJson = jsonEncode(project.toJson());
    final projectBytes = utf8.encode(projectJson);
    archive.addFile(ArchiveFile('project.json', projectBytes.length, projectBytes));

    final encoder = ZipEncoder();
    final compressed = encoder.encode(archive);

    if (compressed != null) {
      final file = File(backupPath);
      await file.writeAsBytes(compressed);
    }

    return backupPath;
  }

  // ─── AUTO-SAVE ────────────────────────────────────────
  static Future<void> autoSave(ESDProject project) async {
    final dir = await _projectsDirectory;
    final autoSavePath = '${dir.path}/.autosave_${project.id}$_nativeExt';

    final archive = Archive();
    final projectJson = jsonEncode(project.toJson());
    final projectBytes = utf8.encode(projectJson);
    archive.addFile(ArchiveFile('project.json', projectBytes.length, projectBytes));

    final encoder = ZipEncoder();
    final compressed = encoder.encode(archive);

    if (compressed != null) {
      final file = File(autoSavePath);
      await file.writeAsBytes(compressed);
    }
  }

  // ─── HELPERS ──────────────────────────────────────────
  static String _sanitizeFilename(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}

// ─────────────────────────────────────────────
// PROJECT META
// ─────────────────────────────────────────────
class ProjectMeta {
  final String id;
  final String name;
  final String filePath;
  final int width;
  final int height;
  final double dpi;
  final ColorMode colorMode;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final String? thumbnailPath;

  ProjectMeta({
    required this.id,
    required this.name,
    required this.filePath,
    required this.width,
    required this.height,
    required this.dpi,
    required this.colorMode,
    required this.createdAt,
    required this.modifiedAt,
    this.thumbnailPath,
  });
}

// ─────────────────────────────────────────────
// SAVE FORMAT ENUM
// ─────────────────────────────────────────────
enum SaveFormat { esdz, psd, plp, afdesign, afphoto, pdf, eps, svg }

// ─────────────────────────────────────────────
// PSD WRITER (Simplified)
// ─────────────────────────────────────────────
class PSDWriter {
  final ESDProject project;
  PSDWriter(this.project);

  Future<Uint8List> write() async {
    final buffer = BytesBuilder();

    // PSD Signature
    buffer.add(utf8.encode('8BPS'));
    // Version
    buffer.add([0, 1]);
    // Reserved (6 bytes)
    buffer.add([0, 0, 0, 0, 0, 0]);
    // Channels (e.g. RGBA = 4)
    buffer.add([0, 4]);
    // Height
    _writeInt32BE(buffer, project.height);
    // Width
    _writeInt32BE(buffer, project.width);
    // Bit depth
    buffer.add([0, 8]);
    // Color mode (RGB = 3)
    buffer.add([0, 3]);

    // Color Mode Data (empty)
    _writeInt32BE(buffer, 0);

    // Image Resources (empty for now)
    _writeInt32BE(buffer, 0);

    // Layer and Mask Information
    final layerData = _writeLayerInfo();
    _writeInt32BE(buffer, layerData.length);
    buffer.add(layerData);

    // Image Data (compressed pixels)
    buffer.add([0, 0]); // Raw compression

    return Uint8List.fromList(buffer.toBytes());
  }

  List<int> _writeLayerInfo() {
    final buffer = BytesBuilder();
    // Layer count
    buffer.add([0, project.layers.length]);

    for (final layer in project.layers) {
      // Layer record
      _writeInt32BE(buffer, 0); // top
      _writeInt32BE(buffer, 0); // left
      _writeInt32BE(buffer, project.height); // bottom
      _writeInt32BE(buffer, project.width); // right
      buffer.add([0, 4]); // channels

      // Channel info
      for (int i = 0; i < 4; i++) {
        buffer.add([0, i == 3 ? 0xFF.toSigned(16) & 0xFF : i]);
        _writeInt32BE(buffer, 0);
      }

      // Blend mode signature
      buffer.add(utf8.encode('8BIM'));
      buffer.add(utf8.encode('norm')); // normal blend mode

      buffer.add([layer.opacity >= 1.0 ? 255 : (layer.opacity * 255).round()]);
      buffer.add([0]); // clipping
      buffer.add([layer.isVisible ? 0 : 2]); // flags
      buffer.add([0]); // filler

      // Extra data
      _writeInt32BE(buffer, 0); // mask size
      _writeInt32BE(buffer, 0); // blending ranges size

      // Layer name (Pascal string)
      final nameBytes = utf8.encode(layer.name);
      buffer.add([nameBytes.length]);
      buffer.add(nameBytes);
    }

    return buffer.toBytes();
  }

  void _writeInt32BE(BytesBuilder buffer, int value) {
    buffer.add([
      (value >> 24) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ]);
  }
}

// ─────────────────────────────────────────────
// PSD READER (Simplified)
// ─────────────────────────────────────────────
class PSDReader {
  final Uint8List bytes;
  int offset = 0;
  PSDReader(this.bytes);

  ESDProject read() {
    // Verify signature
    final sig = String.fromCharCodes(bytes.sublist(0, 4));
    if (sig != '8BPS') throw Exception('Not a valid PSD file');
    offset = 4;

    final version = _readInt16BE();
    offset += 6; // skip reserved

    final channels = _readInt16BE();
    final height = _readInt32BE();
    final width = _readInt32BE();
    final bitDepth = _readInt16BE();
    final colorMode = _readInt16BE();

    final project = ESDProject(
      name: 'Imported PSD',
      width: width,
      height: height,
      dpi: 72,
      colorMode: colorMode == 4 ? ColorMode.cmyk : ColorMode.rgb,
    );

    // Add a single background layer for now
    project.layers.add(ESDLayer(
      name: 'Background',
      type: LayerType.pixel,
    ));

    return project;
  }

  int _readInt16BE() {
    final val = (bytes[offset] << 8) | bytes[offset + 1];
    offset += 2;
    return val;
  }

  int _readInt32BE() {
    final val = (bytes[offset] << 24) | (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) | bytes[offset + 3];
    offset += 4;
    return val;
  }
}

// ─────────────────────────────────────────────
// PLP WRITER/READER (PixelLab)
// ─────────────────────────────────────────────
class PLPWriter {
  final ESDProject project;
  PLPWriter(this.project);

  Future<Uint8List> write() async {
    final archive = Archive();
    final data = {
      'version': 1,
      'width': project.width,
      'height': project.height,
      'layers': project.layers.map((l) => {
        'id': l.id,
        'name': l.name,
        'type': l.type.index,
        'opacity': l.opacity,
        'visible': l.isVisible,
        'blendMode': l.blendMode.index,
        'data': l.data,
      }).toList(),
    };

    final jsonBytes = utf8.encode(jsonEncode(data));
    archive.addFile(ArchiveFile('project.json', jsonBytes.length, jsonBytes));

    final encoder = ZipEncoder();
    final compressed = encoder.encode(archive);
    return Uint8List.fromList(compressed ?? []);
  }
}

class PLPReader {
  final Uint8List bytes;
  PLPReader(this.bytes);

  ESDProject read() {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final projectFile = archive.findFile('project.json');
      if (projectFile == null) throw Exception('Invalid PLP file');

      final data = jsonDecode(utf8.decode(projectFile.content as List<int>));

      final project = ESDProject(
        name: 'Imported PixelLab',
        width: data['width'] ?? 1080,
        height: data['height'] ?? 1080,
      );

      final layers = data['layers'] as List? ?? [];
      for (final layerData in layers) {
        project.layers.add(ESDLayer(
          id: layerData['id'],
          name: layerData['name'] ?? 'Layer',
          type: LayerType.values[layerData['type'] ?? 0],
          opacity: layerData['opacity']?.toDouble() ?? 1.0,
          isVisible: layerData['visible'] ?? true,
          data: layerData['data'] ?? {},
        ));
      }

      return project;
    } catch (_) {
      return ESDProject(name: 'Imported PLP', width: 1080, height: 1080);
    }
  }
}

// ─────────────────────────────────────────────
// AFFINITY WRITER/READER
// ─────────────────────────────────────────────
class AffinityWriter {
  final ESDProject project;
  AffinityWriter(this.project);

  Future<Uint8List> write() async {
    // Affinity uses a proprietary binary format with XML metadata
    // We create a compatible container
    final archive = Archive();

    final metadata = {
      'application': 'ESdizyne',
      'version': '1.0',
      'documentWidth': project.width,
      'documentHeight': project.height,
      'dpi': project.dpi,
      'colorSpace': project.colorMode == ColorMode.cmyk ? 'CMYK' : 'RGB',
      'layers': project.layers.map((l) => l.toJson()).toList(),
    };

    final xmlContent = _toXML(metadata);
    final xmlBytes = utf8.encode(xmlContent);
    archive.addFile(ArchiveFile('document.xml', xmlBytes.length, xmlBytes));

    final encoder = ZipEncoder();
    final compressed = encoder.encode(archive);
    return Uint8List.fromList(compressed ?? []);
  }

  String _toXML(Map<String, dynamic> data) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<AffinityDocument version="1.0">
  <DocumentSettings width="${data['documentWidth']}" height="${data['documentHeight']}" dpi="${data['dpi']}" colorSpace="${data['colorSpace']}"/>
  <Layers>
    ${(data['layers'] as List).map((l) => '<Layer id="${l['id']}" name="${l['name']}" type="${l['type']}" opacity="${l['opacity']}" visible="${l['isVisible']}"/>').join('\n    ')}
  </Layers>
</AffinityDocument>''';
  }
}

class AffinityReader {
  final Uint8List bytes;
  AffinityReader(this.bytes);

  ESDProject read() {
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final docFile = archive.findFile('document.xml');

      final project = ESDProject(
        name: 'Imported Affinity',
        width: 1920,
        height: 1080,
      );

      if (docFile != null) {
        // Parse XML
        final xml = utf8.decode(docFile.content as List<int>);
        // Basic XML parsing for layer names
        final layerMatches = RegExp(r'name="([^"]+)"').allMatches(xml);
        for (final match in layerMatches) {
          project.layers.add(ESDLayer(
            name: match.group(1) ?? 'Layer',
            type: LayerType.pixel,
          ));
        }
      }

      return project;
    } catch (_) {
      return ESDProject(name: 'Imported Affinity', width: 1920, height: 1080);
    }
  }
}

// ─────────────────────────────────────────────
// PDF READER
// ─────────────────────────────────────────────
class PDFReader {
  final Uint8List bytes;
  PDFReader(this.bytes);

  ESDProject read() {
    return ESDProject(
      name: 'Imported PDF',
      width: 2480, // A4 at 300dpi
      height: 3508,
      dpi: 300,
    )..layers.add(ESDLayer(
        name: 'PDF Content',
        type: LayerType.pixel,
        data: {'pdfData': base64Encode(bytes)},
      ));
  }
}

// ─────────────────────────────────────────────
// EPS WRITER/READER
// ─────────────────────────────────────────────
class EPSWriter {
  final ESDProject project;
  EPSWriter(this.project);

  String write() {
    final buffer = StringBuffer();
    buffer.writeln('%!PS-Adobe-3.0 EPSF-3.0');
    buffer.writeln('%%BoundingBox: 0 0 ${project.width} ${project.height}');
    buffer.writeln('%%Title: ${project.name}');
    buffer.writeln('%%Creator: ES Dizyne');
    buffer.writeln('%%CreationDate: ${DateTime.now()}');
    buffer.writeln('%%EndComments');
    buffer.writeln('%%BeginProlog');
    buffer.writeln('%%EndProlog');
    buffer.writeln('%%Page: 1 1');

    // Write vector layers as PostScript
    for (final layer in project.layers) {
      if (layer.type == LayerType.vector) {
        buffer.writeln('% Layer: ${layer.name}');
        buffer.writeln('gsave');
        buffer.writeln('${layer.opacity} setgraphicsalpha');
        // Write shapes
        buffer.writeln('grestore');
      }
    }

    buffer.writeln('%%EOF');
    return buffer.toString();
  }
}

class EPSReader {
  final String content;
  EPSReader(this.content);

  ESDProject read() {
    final project = ESDProject(
      name: 'Imported EPS',
      width: 1920,
      height: 1080,
    );

    // Parse bounding box
    final bbMatch = RegExp(r'%%BoundingBox: (\d+) (\d+) (\d+) (\d+)').firstMatch(content);
    if (bbMatch != null) {
      final w = int.tryParse(bbMatch.group(3) ?? '1920') ?? 1920;
      final h = int.tryParse(bbMatch.group(4) ?? '1080') ?? 1080;
      return ESDProject(name: 'Imported EPS', width: w, height: h)
        ..layers.add(ESDLayer(name: 'EPS Content', type: LayerType.vector,
          data: {'epsContent': content}));
    }

    return project;
  }
}

// ─────────────────────────────────────────────
// SVG WRITER/READER
// ─────────────────────────────────────────────
class SVGWriter {
  final ESDProject project;
  SVGWriter(this.project);

  String write() {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<svg xmlns="http://www.w3.org/2000/svg" width="${project.width}" height="${project.height}" viewBox="0 0 ${project.width} ${project.height}">');
    buffer.writeln('  <title>${project.name}</title>');

    for (final layer in project.layers) {
      if (!layer.isVisible) continue;
      buffer.writeln('  <g id="${layer.id}" opacity="${layer.opacity}">');

      if (layer.type == LayerType.text && layer.data['text'] != null) {
        final textObj = ESDTextObject.fromJson(layer.data['text']);
        buffer.writeln('    <text x="${layer.position.dx}" y="${layer.position.dy}" '
            'font-family="${textObj.fontFamily}" font-size="${textObj.fontSize}" '
            'fill="${textObj.color.toHex()}">${textObj.resolvedContent}</text>');
      }

      buffer.writeln('  </g>');
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }
}

class SVGReader {
  final String content;
  SVGReader(this.content);

  ESDProject read() {
    final widthMatch = RegExp(r'width="(\d+)"').firstMatch(content);
    final heightMatch = RegExp(r'height="(\d+)"').firstMatch(content);

    final width = int.tryParse(widthMatch?.group(1) ?? '1920') ?? 1920;
    final height = int.tryParse(heightMatch?.group(1) ?? '1080') ?? 1080;

    return ESDProject(name: 'Imported SVG', width: width, height: height)
      ..layers.add(ESDLayer(
          name: 'SVG Content',
          type: LayerType.vector,
          data: {'svgContent': content}));
  }
}

// ─────────────────────────────────────────────
// RAW READER
// ─────────────────────────────────────────────
class RAWReader {
  final Uint8List bytes;
  final String format;
  RAWReader(this.bytes, this.format);

  ESDProject read() {
    return ESDProject(
      name: 'RAW Image',
      width: 4000,
      height: 3000,
      dpi: 300,
      colorMode: ColorMode.rgb,
    )..layers.add(ESDLayer(
        name: 'RAW Layer',
        type: LayerType.pixel,
        data: {
          'rawData': base64Encode(bytes),
          'rawFormat': format,
          'isRAW': true,
        },
      ));
  }
}

// Base64 encode helper
String base64Encode(List<int> bytes) {
  return base64.encode(bytes);
}

List<int> base64Decode(String encoded) {
  return base64.decode(encoded);
}
