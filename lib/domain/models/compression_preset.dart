enum CompressionLevel {
  low,
  medium,
  high,
}

class CompressionPreset {
  final CompressionLevel level;
  final String title;
  final String description;
  final int targetDpi;
  final int jpegQuality;

  const CompressionPreset({
    required this.level,
    required this.title,
    required this.description,
    required this.targetDpi,
    required this.jpegQuality,
  });

  static const CompressionPreset low = CompressionPreset(
    level: CompressionLevel.low,
    title: 'Low Compression',
    description: 'Minimal reduction, maximum visual sharpness (300 DPI)',
    targetDpi: 300,
    jpegQuality: 85,
  );

  static const CompressionPreset medium = CompressionPreset(
    level: CompressionLevel.medium,
    title: 'Balanced (Recommended)',
    description: 'Good balance of quality and file size (~50% smaller, 150 DPI)',
    targetDpi: 150,
    jpegQuality: 65,
  );

  static const CompressionPreset high = CompressionPreset(
    level: CompressionLevel.high,
    title: 'Maximum Compression',
    description: 'Smallest file size for email & web sharing (~70% smaller, 96 DPI)',
    targetDpi: 96,
    jpegQuality: 45,
  );

  static const List<CompressionPreset> all = [low, medium, high];
}
