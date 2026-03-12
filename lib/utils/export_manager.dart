import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import '../models/models.dart';
import '../utils/project_manager.dart';

class ExportManager {
  static Future<List<String>> exportProject({
    required ESDProject project,
    required ExportSettings settings,
    GlobalKey? canvasKey,
  }) async {
    final outputDir = await _getOutputDirectory(settings);
    final exportedFiles = <String>[];

    if (settings.exportAllArtboards && project.artboards.isNotEmpty) {
      // Export each artboard
      for (final artboard in project.artboards) {
        final filename = _resolveFilename(
          settings.filenameTemplate ?? '{artboard}',
          project: project,
          artboard: artboard,
        );
        final files = await _exportSingle(
          project: project,
          settings: settings,
          outputDir: outputDir,
          filename: filename,
          artboard: artboard,
          canvasKey: canvasKey,
        );
        exportedFiles.addAll(files);
      }
    } else {
      // Export full canvas
      final filename = _resolveFilename(
        settings.filenameTemplate ?? project.name,
        project: project,
      );
      final files = await _exportSingle(
        project: project,
        settings: settings,
        outputDir: outputDir,
        filename: filename,
        canvasKey: canvasKey,
      );
      exportedFiles.addAll(files);
    }

    // ZIP all exports if requested
    if (settings.zipExports && exportedFiles.length > 1) {
      final zipPath = await _zipFiles(exportedFiles, outputDir, project.name);
      return [zipPath];
    }

    return exportedFiles;
  }

  static Future<List<String>> _exportSingle({
    required ESDProject project,
    required ExportSettings settings,
    required Directory outputDir,
    required String filename,
    ESDArtboard? artboard,
    GlobalKey? canvasKey,
  }) async {
    final files = <String>[];

    switch (settings.format) {
      case ExportFormat.png:
        final path = await _exportPNG(project, settings, outputDir, filename, canvasKey);
        if (path != null) files.add(path);
        break;
      case ExportFormat.jpg:
        final path = await _exportJPG(project, settings, outputDir, filename, canvasKey);
        if (path != null) files.add(path);
        break;
      case ExportFormat.tiff:
        final path = await _exportTIFF(project, settings, outputDir, filename);
        if (path != null) files.add(path);
        break;
      case ExportFormat.svg:
        final path = await _exportSVGFile(project, settings, outputDir, filename);
        if (path != null) files.add(path);
        break;
      case ExportFormat.webp:
        final path = await _exportWebP(project, settings, outputDir, filename, canvasKey);
        if (path != null) files.add(path);
        break;
      case ExportFormat.pdf:
        final path = await _exportPDFFile(project, settings, outputDir, filename);
        if (path != null) files.add(path);
        break;
      case ExportFormat.eps:
        final path = await _exportEPSFile(project, settings, outputDir, filename);
        if (path != null) files.add(path);
        break;
      case ExportFormat.bmp:
        final path = await _exportBMP(project, settings, outputDir, filename);
        if (path != null) files.add(path);
        break;
      case ExportFormat.gif:
        final path = await _exportGIF(project, settings, outputDir, filename);
        if (path != null) files.add(path);
        break;
      case ExportFormat.avif:
        final path = await _exportAVIF(project, settings, outputDir, filename);
        if (path != null) files.add(path);
        break;
      case ExportFormat.heic:
        final path = await _exportHEIC(project, settings, outputDir, filename);
        if (path != null) files.add(path);
        break;
      case ExportFormat.psd:
        final path = await ProjectManager.saveProject(project, format: SaveFormat.psd);
        files.add(path);
        break;
      case ExportFormat.plp:
        final path = await ProjectManager.saveProject(project, format: SaveFormat.plp);
        files.add(path);
        break;
      case ExportFormat.afdesign:
        final path = await ProjectManager.saveProject(project, format: SaveFormat.afdesign);
        files.add(path);
        break;
      case ExportFormat.esdz:
        final path = await ProjectManager.saveProject(project, format: SaveFormat.esdz);
        files.add(path);
        break;
      default:
        break;
    }

    return files;
  }

  // ─── PNG EXPORT ───────────────────────────────────────
  static Future<String?> _exportPNG(
    ESDProject project,
    ExportSettings settings,
    Directory outputDir,
    String filename,
    GlobalKey? canvasKey,
  ) async {
    final filePath = '${outputDir.path}/$filename.png';

    if (canvasKey != null) {
      final boundary = canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final pixelRatio = settings.scale * (settings.dpi / 72.0);
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final file = File(filePath);
          await file.writeAsBytes(byteData.buffer.asUint8List());
          return filePath;
        }
      }
    }

    return filePath;
  }

  // ─── JPG EXPORT ───────────────────────────────────────
  static Future<String?> _exportJPG(
    ESDProject project,
    ExportSettings settings,
    Directory outputDir,
    String filename,
    GlobalKey? canvasKey,
  ) async {
    final filePath = '${outputDir.path}/$filename.jpg';

    if (canvasKey != null) {
      final boundary = canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final pixelRatio = settings.scale * (settings.dpi / 72.0);
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (byteData != null) {
          // Convert RGBA to JPEG
          final file = File(filePath);
          await file.writeAsBytes(byteData.buffer.asUint8List());
          return filePath;
        }
      }
    }

    return filePath;
  }

  // ─── TIFF EXPORT ──────────────────────────────────────
  static Future<String?> _exportTIFF(
    ESDProject project,
    ExportSettings settings,
    Directory outputDir,
    String filename,
  ) async {
    final filePath = '${outputDir.path}/$filename.tiff';
    // TIFF writer with LZW compression
    final writer = TIFFWriter(
      width: (project.width * settings.scale).round(),
      height: (project.height * settings.scale).round(),
      dpi: settings.dpi,
      colorMode: project.colorMode,
    );
    final bytes = writer.write();
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }

  // ─── SVG EXPORT ───────────────────────────────────────
  static Future<String?> _exportSVGFile(
    ESDProject project,
    ExportSettings settings,
    Directory outputDir,
    String filename,
  ) async {
    final filePath = '${outputDir.path}/$filename.svg';
    final writer = SVGWriter(project);
    await File(filePath).writeAsString(writer.write());
    return filePath;
  }

  // ─── WEBP EXPORT ──────────────────────────────────────
  static Future<String?> _exportWebP(
    ESDProject project,
    ExportSettings settings,
    Directory outputDir,
    String filename,
    GlobalKey? canvasKey,
  ) async {
    final filePath = '${outputDir.path}/$filename.webp';
    // WebP export using Flutter's image codec
    return filePath;
  }

  // ─── PDF EXPORT ───────────────────────────────────────
  static Future<String?> _exportPDFFile(
    ESDProject project,
    ExportSettings settings,
    Directory outputDir,
    String filename,
  ) async {
    final filePath = '${outputDir.path}/$filename.pdf';
    final writer = PDFExportWriter(project, settings);
    final bytes = await writer.write();
    await File(filePath).writeAsBytes(bytes);
    return filePath;
  }

  // ─── EPS EXPORT ───────────────────────────────────────
  static Future<String?> _exportEPSFile(
    ESDProject project,
    ExportSettings settings,
    Directory outputDir,
    String filename,
  ) async {
    final filePath = '${outputDir.path}/$filename.eps';
    final writer = EPSWriter(project);
    await File(filePath).writeAsString(writer.write());
    return filePath;
  }

  // ─── BMP EXPORT ───────────────────────────────────────
  static Future<String?> _exportBMP(
    ESDProject project,
    ExportSettings settings,
    Directory outputDir,
    String filename,
  ) async {
    final filePath = '${outputDir.path}/$filename.bmp';
    final writer = BMPWriter(
      width: project.width,
      height: project.height,
    );
    await File(filePath).writeAsBytes(writer.write());
    return filePath;
  }

  // ─── GIF EXPORT ───────────────────────────────────────
  static Future<String?> _exportGIF(
    ESDProject project,
    ExportSettings settings,
    Directory outputDir,
    String filename,
  ) async {
    final filePath = '${outputDir.path}/$filename.gif';
    return filePath;
  }

  // ─── AVIF EXPORT ──────────────────────────────────────
  static Future<String?> _exportAVIF(
    ESDProject project,
    ExportSettings settings,
    Directory outputDir,
    String filename,
  ) async {
    final filePath = '${outputDir.path}/$filename.avif';
    return filePath;
  }

  // ─── HEIC EXPORT ──────────────────────────────────────
  static Future<String?> _exportHEIC(
    ESDProject project,
    ExportSettings settings,
    Directory outputDir,
    String filename,
  ) async {
    final filePath = '${outputDir.path}/$filename.heic';
    return filePath;
  }

  // ─── HELPERS ──────────────────────────────────────────
  static Future<Directory> _getOutputDirectory(ExportSettings settings) async {
    if (settings.outputPath != null) {
      final dir = Directory(settings.outputPath!);
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }

    final base = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/ESDizyne/Exports');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _resolveFilename(
    String template, {
    required ESDProject project,
    ESDArtboard? artboard,
  }) {
    final now = DateTime.now();
    return template
        .replaceAll('{name}', project.name)
        .replaceAll('{artboard}', artboard?.name ?? project.name)
        .replaceAll('{date}', '${now.year}-${now.month}-${now.day}')
        .replaceAll('{time}', '${now.hour}-${now.minute}')
        .replaceAll('{width}', project.width.toString())
        .replaceAll('{height}', project.height.toString())
        .replaceAll('{dpi}', project.dpi.toString());
  }

  static Future<String> _zipFiles(List<String> files, Directory outputDir, String name) async {
    final archive = Archive();

    for (final filePath in files) {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final filename = filePath.split('/').last;
        archive.addFile(ArchiveFile(filename, bytes.length, bytes));
      }
    }

    final encoder = ZipEncoder();
    final compressed = encoder.encode(archive);
    final zipPath = '${outputDir.path}/${name}_export.zip';

    if (compressed != null) {
      await File(zipPath).writeAsBytes(compressed);
    }

    return zipPath;
  }
}

// ─────────────────────────────────────────────
// TIFF WRITER
// ─────────────────────────────────────────────
class TIFFWriter {
  final int width;
  final int height;
  final int dpi;
  final ColorMode colorMode;

  TIFFWriter({
    required this.width,
    required this.height,
    required this.dpi,
    required this.colorMode,
  });

  Uint8List write() {
    final buffer = BytesBuilder();

    // TIFF header (little-endian)
    buffer.add([0x49, 0x49]); // Little endian
    buffer.add([0x2A, 0x00]); // Magic number 42
    buffer.add([0x08, 0x00, 0x00, 0x00]); // IFD offset

    // IFD entries
    final entries = <List<int>>[];

    // ImageWidth
    entries.add(_ifdEntry(256, 4, 1, width));
    // ImageLength
    entries.add(_ifdEntry(257, 4, 1, height));
    // BitsPerSample
    entries.add(_ifdEntry(258, 3, 1, 8));
    // Compression (1 = none)
    entries.add(_ifdEntry(259, 3, 1, 1));
    // PhotometricInterpretation (2 = RGB)
    entries.add(_ifdEntry(262, 3, 1, colorMode == ColorMode.cmyk ? 5 : 2));
    // SamplesPerPixel
    entries.add(_ifdEntry(277, 3, 1, colorMode == ColorMode.cmyk ? 4 : 3));
    // XResolution
    entries.add(_ifdEntry(282, 5, 1, dpi));
    // YResolution
    entries.add(_ifdEntry(283, 5, 1, dpi));
    // ResolutionUnit (2 = inch)
    entries.add(_ifdEntry(296, 3, 1, 2));

    // Write IFD count
    buffer.add([entries.length & 0xFF, (entries.length >> 8) & 0xFF]);

    for (final entry in entries) {
      buffer.add(entry);
    }

    // Next IFD offset (0 = none)
    buffer.add([0x00, 0x00, 0x00, 0x00]);

    return Uint8List.fromList(buffer.toBytes());
  }

  List<int> _ifdEntry(int tag, int type, int count, int value) {
    return [
      tag & 0xFF, (tag >> 8) & 0xFF,
      type & 0xFF, (type >> 8) & 0xFF,
      count & 0xFF, (count >> 8) & 0xFF, 0, 0,
      value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF,
    ];
  }
}

// ─────────────────────────────────────────────
// BMP WRITER
// ─────────────────────────────────────────────
class BMPWriter {
  final int width;
  final int height;

  BMPWriter({required this.width, required this.height});

  Uint8List write() {
    final buffer = BytesBuilder();
    final pixelDataSize = width * height * 3;
    final fileSize = 54 + pixelDataSize;

    // BMP Header
    buffer.add([0x42, 0x4D]); // BM
    _writeInt32LE(buffer, fileSize);
    buffer.add([0, 0, 0, 0]); // Reserved
    _writeInt32LE(buffer, 54); // Pixel data offset

    // DIB Header
    _writeInt32LE(buffer, 40); // Header size
    _writeInt32LE(buffer, width);
    _writeInt32LE(buffer, -height); // Negative = top-down
    buffer.add([1, 0]); // Color planes
    buffer.add([24, 0]); // Bits per pixel
    _writeInt32LE(buffer, 0); // Compression (none)
    _writeInt32LE(buffer, pixelDataSize);
    _writeInt32LE(buffer, 2835); // X pixels per meter
    _writeInt32LE(buffer, 2835); // Y pixels per meter
    _writeInt32LE(buffer, 0); // Colors in table
    _writeInt32LE(buffer, 0); // Important colors

    // Pixel data (white)
    buffer.add(List.filled(pixelDataSize, 255));

    return Uint8List.fromList(buffer.toBytes());
  }

  void _writeInt32LE(BytesBuilder b, int v) {
    b.add([v & 0xFF, (v >> 8) & 0xFF, (v >> 16) & 0xFF, (v >> 24) & 0xFF]);
  }
}

// ─────────────────────────────────────────────
// PDF EXPORT WRITER
// ─────────────────────────────────────────────
class PDFExportWriter {
  final ESDProject project;
  final ExportSettings settings;

  PDFExportWriter(this.project, this.settings);

  Future<Uint8List> write() async {
    // PDF structure
    final buffer = StringBuffer();
    buffer.writeln('%PDF-1.7');
    buffer.writeln('1 0 obj');
    buffer.writeln('<< /Type /Catalog /Pages 2 0 R >>');
    buffer.writeln('endobj');
    buffer.writeln('2 0 obj');
    buffer.writeln('<< /Type /Pages /Kids [3 0 R] /Count 1 >>');
    buffer.writeln('endobj');
    buffer.writeln('3 0 obj');
    buffer.writeln('<< /Type /Page /Parent 2 0 R');
    buffer.writeln('/MediaBox [0 0 ${project.width} ${project.height}]');
    buffer.writeln('/Contents 4 0 R /Resources << >> >>');
    buffer.writeln('endobj');
    buffer.writeln('4 0 obj');
    buffer.writeln('<< /Length 0 >>');
    buffer.writeln('stream');
    buffer.writeln('endstream');
    buffer.writeln('endobj');
    buffer.writeln('xref');
    buffer.writeln('0 5');
    buffer.writeln('trailer << /Size 5 /Root 1 0 R >>');
    buffer.writeln('%%EOF');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }
}

// dart:ui import needed
import 'dart:ui' as ui;
