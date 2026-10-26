import 'enhancement_preset.dart';

class PointCoord {
  final double x;
  final double y;
  const PointCoord(this.x, this.y);

  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory PointCoord.fromJson(Map<String, dynamic> json) => PointCoord(
        (json['x'] as num).toDouble(),
        (json['y'] as num).toDouble(),
      );
}

class ScannedPage {
  final String id;
  final String originalPath;
  String currentPath; // Current enhanced/rotated/cropped preview path
  int rotation; // 0, 90, 180, 270
  EnhancementPreset preset;
  List<PointCoord>? cropCorners; // 4 corners: TL, TR, BR, BL

  ScannedPage({
    required this.id,
    required this.originalPath,
    required this.currentPath,
    this.rotation = 0,
    this.preset = EnhancementPreset.original,
    this.cropCorners,
  });

  ScannedPage copyWith({
    String? id,
    String? originalPath,
    String? currentPath,
    int? rotation,
    EnhancementPreset? preset,
    List<PointCoord>? cropCorners,
  }) {
    return ScannedPage(
      id: id ?? this.id,
      originalPath: originalPath ?? this.originalPath,
      currentPath: currentPath ?? this.currentPath,
      rotation: rotation ?? this.rotation,
      preset: preset ?? this.preset,
      cropCorners: cropCorners ?? this.cropCorners,
    );
  }
}
