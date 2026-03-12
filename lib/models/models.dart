import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ─────────────────────────────────────────────
// COLOR MODE
// ─────────────────────────────────────────────
enum ColorMode { rgb, cmyk, lab, greyscale, duotone }

enum DpiPreset { screen72, web96, lowPrint150, print300, highPrint600, professional1200, custom }

enum ColorProfile { sRGB, adobeRGB, proPhotoRGB, cmykCoated, cmykUncoated, custom }

// ─────────────────────────────────────────────
// PROJECT MODEL
// ─────────────────────────────────────────────
class ESDProject {
  final String id;
  String name;
  int width;
  int height;
  double dpi;
  ColorMode colorMode;
  ColorProfile colorProfile;
  List<ESDLayer> layers;
  List<ESDArtboard> artboards;
  List<ESDColorPalette> colorPalettes;
  DateTime createdAt;
  DateTime modifiedAt;
  String? thumbnailPath;
  Map<String, dynamic> metadata;

  ESDProject({
    String? id,
    required this.name,
    required this.width,
    required this.height,
    this.dpi = 72,
    this.colorMode = ColorMode.rgb,
    this.colorProfile = ColorProfile.sRGB,
    List<ESDLayer>? layers,
    List<ESDArtboard>? artboards,
    List<ESDColorPalette>? colorPalettes,
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.thumbnailPath,
    Map<String, dynamic>? metadata,
  })  : id = id ?? _uuid.v4(),
        layers = layers ?? [],
        artboards = artboards ?? [],
        colorPalettes = colorPalettes ?? [],
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now(),
        metadata = metadata ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'width': width,
        'height': height,
        'dpi': dpi,
        'colorMode': colorMode.index,
        'colorProfile': colorProfile.index,
        'layers': layers.map((l) => l.toJson()).toList(),
        'artboards': artboards.map((a) => a.toJson()).toList(),
        'colorPalettes': colorPalettes.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'modifiedAt': modifiedAt.toIso8601String(),
        'thumbnailPath': thumbnailPath,
        'metadata': metadata,
      };

  factory ESDProject.fromJson(Map<String, dynamic> json) => ESDProject(
        id: json['id'],
        name: json['name'],
        width: json['width'],
        height: json['height'],
        dpi: json['dpi']?.toDouble() ?? 72,
        colorMode: ColorMode.values[json['colorMode'] ?? 0],
        colorProfile: ColorProfile.values[json['colorProfile'] ?? 0],
        layers: (json['layers'] as List?)?.map((l) => ESDLayer.fromJson(l)).toList() ?? [],
        artboards: (json['artboards'] as List?)?.map((a) => ESDArtboard.fromJson(a)).toList() ?? [],
        colorPalettes: (json['colorPalettes'] as List?)?.map((p) => ESDColorPalette.fromJson(p)).toList() ?? [],
        createdAt: DateTime.parse(json['createdAt']),
        modifiedAt: DateTime.parse(json['modifiedAt']),
        thumbnailPath: json['thumbnailPath'],
        metadata: json['metadata'] ?? {},
      );
}

// ─────────────────────────────────────────────
// LAYER MODEL
// ─────────────────────────────────────────────
enum LayerType { pixel, vector, text, adjustment, group, smartObject, fill }

enum BlendMode {
  normal, dissolve,
  darken, multiply, colorBurn, linearBurn, darkerColor,
  lighten, screen, colorDodge, linearDodge, lighterColor,
  overlay, softLight, hardLight, vividLight, linearLight, pinLight, hardMix,
  difference, exclusion, subtract, divide,
  hue, saturation, color, luminosity,
}

class ESDLayer {
  final String id;
  String name;
  LayerType type;
  bool isVisible;
  bool isLocked;
  double opacity;
  double fillOpacity;
  BlendMode blendMode;
  List<ESDLayer> children;
  String? parentId;
  Map<String, dynamic> data;
  List<LayerEffect> effects;
  ESDMask? mask;
  Offset position;
  Size size;
  double rotation;
  bool isClippingMask;

  ESDLayer({
    String? id,
    required this.name,
    required this.type,
    this.isVisible = true,
    this.isLocked = false,
    this.opacity = 1.0,
    this.fillOpacity = 1.0,
    this.blendMode = BlendMode.normal,
    List<ESDLayer>? children,
    this.parentId,
    Map<String, dynamic>? data,
    List<LayerEffect>? effects,
    this.mask,
    Offset? position,
    Size? size,
    this.rotation = 0,
    this.isClippingMask = false,
  })  : id = id ?? _uuid.v4(),
        children = children ?? [],
        data = data ?? {},
        effects = effects ?? [],
        position = position ?? Offset.zero,
        size = size ?? Size.zero;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'isVisible': isVisible,
        'isLocked': isLocked,
        'opacity': opacity,
        'fillOpacity': fillOpacity,
        'blendMode': blendMode.index,
        'children': children.map((c) => c.toJson()).toList(),
        'parentId': parentId,
        'data': data,
        'effects': effects.map((e) => e.toJson()).toList(),
        'mask': mask?.toJson(),
        'position': {'dx': position.dx, 'dy': position.dy},
        'size': {'width': size.width, 'height': size.height},
        'rotation': rotation,
        'isClippingMask': isClippingMask,
      };

  factory ESDLayer.fromJson(Map<String, dynamic> json) => ESDLayer(
        id: json['id'],
        name: json['name'],
        type: LayerType.values[json['type'] ?? 0],
        isVisible: json['isVisible'] ?? true,
        isLocked: json['isLocked'] ?? false,
        opacity: json['opacity']?.toDouble() ?? 1.0,
        fillOpacity: json['fillOpacity']?.toDouble() ?? 1.0,
        blendMode: BlendMode.values[json['blendMode'] ?? 0],
        children: (json['children'] as List?)?.map((c) => ESDLayer.fromJson(c)).toList() ?? [],
        parentId: json['parentId'],
        data: json['data'] ?? {},
        effects: (json['effects'] as List?)?.map((e) => LayerEffect.fromJson(e)).toList() ?? [],
        mask: json['mask'] != null ? ESDMask.fromJson(json['mask']) : null,
        position: json['position'] != null
            ? Offset(json['position']['dx'], json['position']['dy'])
            : Offset.zero,
        size: json['size'] != null
            ? Size(json['size']['width'], json['size']['height'])
            : Size.zero,
        rotation: json['rotation']?.toDouble() ?? 0,
        isClippingMask: json['isClippingMask'] ?? false,
      );
}

// ─────────────────────────────────────────────
// LAYER EFFECTS
// ─────────────────────────────────────────────
enum LayerEffectType {
  dropShadow, innerShadow, outerGlow, innerGlow,
  bevelEmboss, stroke, colorOverlay, gradientOverlay, patternOverlay,
}

class LayerEffect {
  final String id;
  LayerEffectType type;
  bool isEnabled;
  Map<String, dynamic> settings;

  LayerEffect({
    String? id,
    required this.type,
    this.isEnabled = true,
    Map<String, dynamic>? settings,
  })  : id = id ?? _uuid.v4(),
        settings = settings ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'isEnabled': isEnabled,
        'settings': settings,
      };

  factory LayerEffect.fromJson(Map<String, dynamic> json) => LayerEffect(
        id: json['id'],
        type: LayerEffectType.values[json['type']],
        isEnabled: json['isEnabled'] ?? true,
        settings: json['settings'] ?? {},
      );
}

// ─────────────────────────────────────────────
// MASK MODEL
// ─────────────────────────────────────────────
enum MaskType { pixel, vector, luminosity, gradient }

class ESDMask {
  MaskType type;
  bool isEnabled;
  bool isInverted;
  Map<String, dynamic> data;

  ESDMask({
    required this.type,
    this.isEnabled = true,
    this.isInverted = false,
    Map<String, dynamic>? data,
  }) : data = data ?? {};

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'isEnabled': isEnabled,
        'isInverted': isInverted,
        'data': data,
      };

  factory ESDMask.fromJson(Map<String, dynamic> json) => ESDMask(
        type: MaskType.values[json['type']],
        isEnabled: json['isEnabled'] ?? true,
        isInverted: json['isInverted'] ?? false,
        data: json['data'] ?? {},
      );
}

// ─────────────────────────────────────────────
// ARTBOARD MODEL
// ─────────────────────────────────────────────
class ESDArtboard {
  final String id;
  String name;
  double x;
  double y;
  double width;
  double height;
  Color backgroundColor;
  bool showBackground;
  List<String> layerIds;

  ESDArtboard({
    String? id,
    required this.name,
    this.x = 0,
    this.y = 0,
    required this.width,
    required this.height,
    this.backgroundColor = Colors.white,
    this.showBackground = true,
    List<String>? layerIds,
  })  : id = id ?? _uuid.v4(),
        layerIds = layerIds ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'backgroundColor': backgroundColor.value,
        'showBackground': showBackground,
        'layerIds': layerIds,
      };

  factory ESDArtboard.fromJson(Map<String, dynamic> json) => ESDArtboard(
        id: json['id'],
        name: json['name'],
        x: json['x']?.toDouble() ?? 0,
        y: json['y']?.toDouble() ?? 0,
        width: json['width']?.toDouble() ?? 800,
        height: json['height']?.toDouble() ?? 600,
        backgroundColor: Color(json['backgroundColor'] ?? 0xFFFFFFFF),
        showBackground: json['showBackground'] ?? true,
        layerIds: List<String>.from(json['layerIds'] ?? []),
      );
}

// ─────────────────────────────────────────────
// COLOR PALETTE MODEL
// ─────────────────────────────────────────────
class ESDColorPalette {
  final String id;
  String name;
  List<ESDColor> colors;
  bool isGlobal;
  DateTime createdAt;

  ESDColorPalette({
    String? id,
    required this.name,
    List<ESDColor>? colors,
    this.isGlobal = false,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        colors = colors ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colors': colors.map((c) => c.toJson()).toList(),
        'isGlobal': isGlobal,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ESDColorPalette.fromJson(Map<String, dynamic> json) => ESDColorPalette(
        id: json['id'],
        name: json['name'],
        colors: (json['colors'] as List?)?.map((c) => ESDColor.fromJson(c)).toList() ?? [],
        isGlobal: json['isGlobal'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class ESDColor {
  final String id;
  String name;
  double r, g, b, a;
  double? c, m, y, k;
  ColorMode mode;

  ESDColor({
    String? id,
    this.name = '',
    required this.r,
    required this.g,
    required this.b,
    this.a = 1.0,
    this.c,
    this.m,
    this.y,
    this.k,
    this.mode = ColorMode.rgb,
  }) : id = id ?? _uuid.v4();

  Color toFlutterColor() => Color.fromARGB(
        (a * 255).round(),
        (r * 255).round(),
        (g * 255).round(),
        (b * 255).round(),
      );

  String toHex() =>
      '#${(r * 255).round().toRadixString(16).padLeft(2, '0')}${(g * 255).round().toRadixString(16).padLeft(2, '0')}${(b * 255).round().toRadixString(16).padLeft(2, '0')}'.toUpperCase();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'r': r, 'g': g, 'b': b, 'a': a,
        'c': c, 'm': m, 'y': y, 'k': k,
        'mode': mode.index,
      };

  factory ESDColor.fromJson(Map<String, dynamic> json) => ESDColor(
        id: json['id'],
        name: json['name'] ?? '',
        r: json['r']?.toDouble() ?? 0,
        g: json['g']?.toDouble() ?? 0,
        b: json['b']?.toDouble() ?? 0,
        a: json['a']?.toDouble() ?? 1,
        c: json['c']?.toDouble(),
        m: json['m']?.toDouble(),
        y: json['y']?.toDouble(),
        k: json['k']?.toDouble(),
        mode: ColorMode.values[json['mode'] ?? 0],
      );

  factory ESDColor.fromFlutterColor(Color color) => ESDColor(
        r: color.red / 255,
        g: color.green / 255,
        b: color.blue / 255,
        a: color.alpha / 255,
      );
}

// ─────────────────────────────────────────────
// GRADIENT MODEL
// ─────────────────────────────────────────────
enum GradientType { linear, radial, conical, elliptical, mesh, diamond }

class ESDGradient {
  final String id;
  String name;
  GradientType type;
  List<GradientStop> stops;
  double angle;
  Offset center;
  double radius;

  ESDGradient({
    String? id,
    this.name = 'Gradient',
    this.type = GradientType.linear,
    List<GradientStop>? stops,
    this.angle = 0,
    Offset? center,
    this.radius = 0.5,
  })  : id = id ?? _uuid.v4(),
        stops = stops ?? [
          GradientStop(color: ESDColor(r: 0, g: 0, b: 0), position: 0),
          GradientStop(color: ESDColor(r: 1, g: 1, b: 1), position: 1),
        ],
        center = center ?? const Offset(0.5, 0.5);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'stops': stops.map((s) => s.toJson()).toList(),
        'angle': angle,
        'center': {'dx': center.dx, 'dy': center.dy},
        'radius': radius,
      };

  factory ESDGradient.fromJson(Map<String, dynamic> json) => ESDGradient(
        id: json['id'],
        name: json['name'] ?? 'Gradient',
        type: GradientType.values[json['type'] ?? 0],
        stops: (json['stops'] as List?)?.map((s) => GradientStop.fromJson(s)).toList(),
        angle: json['angle']?.toDouble() ?? 0,
        center: json['center'] != null
            ? Offset(json['center']['dx'], json['center']['dy'])
            : const Offset(0.5, 0.5),
        radius: json['radius']?.toDouble() ?? 0.5,
      );
}

class GradientStop {
  ESDColor color;
  double position;
  double opacity;

  GradientStop({
    required this.color,
    required this.position,
    this.opacity = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'color': color.toJson(),
        'position': position,
        'opacity': opacity,
      };

  factory GradientStop.fromJson(Map<String, dynamic> json) => GradientStop(
        color: ESDColor.fromJson(json['color']),
        position: json['position']?.toDouble() ?? 0,
        opacity: json['opacity']?.toDouble() ?? 1,
      );
}

// ─────────────────────────────────────────────
// BRUSH MODEL
// ─────────────────────────────────────────────
enum BrushCategory {
  basic, inking, painting, texture, spray,
  watercolour, oil, charcoal, airbrush, eraser, custom
}

class ESDBrush {
  final String id;
  String name;
  BrushCategory category;
  double size;
  double minSize;
  double maxSize;
  double opacity;
  double flow;
  double hardness;
  double spacing;
  double angle;
  double angleJitter;
  double scatter;
  double sizeJitter;
  double opacityJitter;
  bool pressureSize;
  bool pressureOpacity;
  bool tiltAngle;
  bool velocitySize;
  double smoothing;
  String? texturePath;
  bool isCustom;

  ESDBrush({
    String? id,
    required this.name,
    this.category = BrushCategory.basic,
    this.size = 20,
    this.minSize = 1,
    this.maxSize = 500,
    this.opacity = 1.0,
    this.flow = 1.0,
    this.hardness = 0.8,
    this.spacing = 0.1,
    this.angle = 0,
    this.angleJitter = 0,
    this.scatter = 0,
    this.sizeJitter = 0,
    this.opacityJitter = 0,
    this.pressureSize = true,
    this.pressureOpacity = false,
    this.tiltAngle = false,
    this.velocitySize = false,
    this.smoothing = 0.5,
    this.texturePath,
    this.isCustom = false,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.index,
        'size': size,
        'minSize': minSize,
        'maxSize': maxSize,
        'opacity': opacity,
        'flow': flow,
        'hardness': hardness,
        'spacing': spacing,
        'angle': angle,
        'angleJitter': angleJitter,
        'scatter': scatter,
        'sizeJitter': sizeJitter,
        'opacityJitter': opacityJitter,
        'pressureSize': pressureSize,
        'pressureOpacity': pressureOpacity,
        'tiltAngle': tiltAngle,
        'velocitySize': velocitySize,
        'smoothing': smoothing,
        'texturePath': texturePath,
        'isCustom': isCustom,
      };

  factory ESDBrush.fromJson(Map<String, dynamic> json) => ESDBrush(
        id: json['id'],
        name: json['name'],
        category: BrushCategory.values[json['category'] ?? 0],
        size: json['size']?.toDouble() ?? 20,
        minSize: json['minSize']?.toDouble() ?? 1,
        maxSize: json['maxSize']?.toDouble() ?? 500,
        opacity: json['opacity']?.toDouble() ?? 1,
        flow: json['flow']?.toDouble() ?? 1,
        hardness: json['hardness']?.toDouble() ?? 0.8,
        spacing: json['spacing']?.toDouble() ?? 0.1,
        angle: json['angle']?.toDouble() ?? 0,
        smoothing: json['smoothing']?.toDouble() ?? 0.5,
        isCustom: json['isCustom'] ?? false,
      );
}

// ─────────────────────────────────────────────
// SHAPE MODEL
// ─────────────────────────────────────────────
enum ShapeType {
  rectangle, roundedRectangle, ellipse, circle,
  triangle, polygon, star, spiral, arrow,
  line, arc, donut, cross, heart, cloud,
  speech, callout, banner, custom
}

class ESDShape {
  final String id;
  String name;
  ShapeType type;
  Map<String, dynamic> properties;
  ESDColor? fillColor;
  ESDGradient? fillGradient;
  ESDColor? strokeColor;
  double strokeWidth;
  List<double> dashPattern;
  double cornerRadius;
  bool hasRoundedCorners;

  ESDShape({
    String? id,
    required this.name,
    required this.type,
    Map<String, dynamic>? properties,
    this.fillColor,
    this.fillGradient,
    this.strokeColor,
    this.strokeWidth = 1,
    List<double>? dashPattern,
    this.cornerRadius = 0,
    this.hasRoundedCorners = false,
  })  : id = id ?? _uuid.v4(),
        properties = properties ?? {},
        dashPattern = dashPattern ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.index,
        'properties': properties,
        'fillColor': fillColor?.toJson(),
        'fillGradient': fillGradient?.toJson(),
        'strokeColor': strokeColor?.toJson(),
        'strokeWidth': strokeWidth,
        'dashPattern': dashPattern,
        'cornerRadius': cornerRadius,
        'hasRoundedCorners': hasRoundedCorners,
      };

  factory ESDShape.fromJson(Map<String, dynamic> json) => ESDShape(
        id: json['id'],
        name: json['name'],
        type: ShapeType.values[json['type']],
        properties: json['properties'] ?? {},
        fillColor: json['fillColor'] != null ? ESDColor.fromJson(json['fillColor']) : null,
        strokeColor: json['strokeColor'] != null ? ESDColor.fromJson(json['strokeColor']) : null,
        strokeWidth: json['strokeWidth']?.toDouble() ?? 1,
        cornerRadius: json['cornerRadius']?.toDouble() ?? 0,
        hasRoundedCorners: json['hasRoundedCorners'] ?? false,
      );
}

// ─────────────────────────────────────────────
// TEXT MODEL
// ─────────────────────────────────────────────
enum TextType { artistic, frame, path }
enum DynamicTextType { none, date, time, filename, artboardName, pageNumber, custom }
enum TextAlignment { left, center, right, justify }

class ESDTextObject {
  final String id;
  String content;
  TextType textType;
  DynamicTextType dynamicType;
  String? dynamicFormat;
  String fontFamily;
  double fontSize;
  FontWeight fontWeight;
  bool isItalic;
  bool isUnderline;
  bool isStrikethrough;
  ESDColor color;
  ESDGradient? gradientColor;
  TextAlignment alignment;
  double lineHeight;
  double letterSpacing;
  double wordSpacing;
  double baselineShift;
  bool hasDropCap;
  List<ESDTextSpan> spans;

  ESDTextObject({
    String? id,
    this.content = '',
    this.textType = TextType.artistic,
    this.dynamicType = DynamicTextType.none,
    this.dynamicFormat,
    this.fontFamily = 'Outfit',
    this.fontSize = 24,
    this.fontWeight = FontWeight.normal,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    ESDColor? color,
    this.gradientColor,
    this.alignment = TextAlignment.left,
    this.lineHeight = 1.2,
    this.letterSpacing = 0,
    this.wordSpacing = 0,
    this.baselineShift = 0,
    this.hasDropCap = false,
    List<ESDTextSpan>? spans,
  })  : id = id ?? _uuid.v4(),
        color = color ?? ESDColor(r: 0, g: 0, b: 0),
        spans = spans ?? [];

  String get resolvedContent {
    switch (dynamicType) {
      case DynamicTextType.date:
        return _formatDate(dynamicFormat ?? 'MMM dd, yyyy');
      case DynamicTextType.time:
        return _formatTime(dynamicFormat ?? 'HH:mm');
      case DynamicTextType.filename:
        return dynamicFormat ?? 'Untitled';
      case DynamicTextType.pageNumber:
        return dynamicFormat ?? '1';
      default:
        return content;
    }
  }

  String _formatDate(String format) {
    final now = DateTime.now();
    return '${now.month}/${now.day}/${now.year}';
  }

  String _formatTime(String format) {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'textType': textType.index,
        'dynamicType': dynamicType.index,
        'dynamicFormat': dynamicFormat,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'fontWeight': fontWeight.index,
        'isItalic': isItalic,
        'isUnderline': isUnderline,
        'isStrikethrough': isStrikethrough,
        'color': color.toJson(),
        'gradientColor': gradientColor?.toJson(),
        'alignment': alignment.index,
        'lineHeight': lineHeight,
        'letterSpacing': letterSpacing,
        'wordSpacing': wordSpacing,
        'baselineShift': baselineShift,
        'hasDropCap': hasDropCap,
        'spans': spans.map((s) => s.toJson()).toList(),
      };

  factory ESDTextObject.fromJson(Map<String, dynamic> json) => ESDTextObject(
        id: json['id'],
        content: json['content'] ?? '',
        textType: TextType.values[json['textType'] ?? 0],
        dynamicType: DynamicTextType.values[json['dynamicType'] ?? 0],
        dynamicFormat: json['dynamicFormat'],
        fontFamily: json['fontFamily'] ?? 'Outfit',
        fontSize: json['fontSize']?.toDouble() ?? 24,
        isItalic: json['isItalic'] ?? false,
        isUnderline: json['isUnderline'] ?? false,
        isStrikethrough: json['isStrikethrough'] ?? false,
        color: ESDColor.fromJson(json['color']),
        alignment: TextAlignment.values[json['alignment'] ?? 0],
        lineHeight: json['lineHeight']?.toDouble() ?? 1.2,
        letterSpacing: json['letterSpacing']?.toDouble() ?? 0,
        wordSpacing: json['wordSpacing']?.toDouble() ?? 0,
      );
}

class ESDTextSpan {
  String text;
  String? fontFamily;
  double? fontSize;
  FontWeight? fontWeight;
  bool? isItalic;
  ESDColor? color;
  ESDGradient? gradientColor;
  double? letterSpacing;
  double? baselineShift;
  bool? isUnderline;
  bool? isStrikethrough;

  ESDTextSpan({
    required this.text,
    this.fontFamily,
    this.fontSize,
    this.fontWeight,
    this.isItalic,
    this.color,
    this.gradientColor,
    this.letterSpacing,
    this.baselineShift,
    this.isUnderline,
    this.isStrikethrough,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'isItalic': isItalic,
        'color': color?.toJson(),
        'letterSpacing': letterSpacing,
        'baselineShift': baselineShift,
        'isUnderline': isUnderline,
        'isStrikethrough': isStrikethrough,
      };

  factory ESDTextSpan.fromJson(Map<String, dynamic> json) => ESDTextSpan(
        text: json['text'] ?? '',
        fontFamily: json['fontFamily'],
        fontSize: json['fontSize']?.toDouble(),
        isItalic: json['isItalic'],
        color: json['color'] != null ? ESDColor.fromJson(json['color']) : null,
        letterSpacing: json['letterSpacing']?.toDouble(),
        baselineShift: json['baselineShift']?.toDouble(),
        isUnderline: json['isUnderline'],
        isStrikethrough: json['isStrikethrough'],
      );
}

// ─────────────────────────────────────────────
// HISTORY / UNDO MODEL
// ─────────────────────────────────────────────
enum HistoryActionType {
  addLayer, deleteLayer, moveLayer, transformLayer,
  paintStroke, eraseStroke, fillLayer,
  addText, editText, addShape,
  applyFilter, applyAdjustment,
  addMask, editMask,
  mergeLayer, duplicateLayer,
  changeBlendMode, changeOpacity,
  addArtboard, deleteArtboard,
  resizeCanvas, cropCanvas,
}

class HistoryAction {
  final String id;
  final HistoryActionType type;
  final String description;
  final Map<String, dynamic> before;
  final Map<String, dynamic> after;
  final DateTime timestamp;

  HistoryAction({
    String? id,
    required this.type,
    required this.description,
    required this.before,
    required this.after,
    DateTime? timestamp,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();
}

// ─────────────────────────────────────────────
// EXPORT SETTINGS MODEL
// ─────────────────────────────────────────────
enum ExportFormat {
  png, jpg, tiff, svg, webp, pdf, eps, bmp, gif, avif, heic,
  raw, psd, plp, afdesign, afphoto, esdz
}

class ExportSettings {
  ExportFormat format;
  double scale;
  int dpi;
  int quality;
  bool transparent;
  bool embedColorProfile;
  bool stripMetadata;
  bool exportAllArtboards;
  String? outputPath;
  String? filenameTemplate;
  bool zipExports;
  Map<String, dynamic> formatOptions;

  ExportSettings({
    this.format = ExportFormat.png,
    this.scale = 1.0,
    this.dpi = 72,
    this.quality = 95,
    this.transparent = true,
    this.embedColorProfile = true,
    this.stripMetadata = false,
    this.exportAllArtboards = false,
    this.outputPath,
    this.filenameTemplate,
    this.zipExports = false,
    Map<String, dynamic>? formatOptions,
  }) : formatOptions = formatOptions ?? {};
}
