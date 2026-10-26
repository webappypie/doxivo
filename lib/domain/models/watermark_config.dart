import 'package:flutter/material.dart';

class WatermarkConfig {
  final String text;
  final double fontSize;
  final double opacity;
  final double rotationDegrees;
  final Color color;

  const WatermarkConfig({
    required this.text,
    this.fontSize = 48.0,
    this.opacity = 0.3,
    this.rotationDegrees = 45.0,
    this.color = Colors.grey,
  });

  WatermarkConfig copyWith({
    String? text,
    double? fontSize,
    double? opacity,
    double? rotationDegrees,
    Color? color,
  }) {
    return WatermarkConfig(
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      opacity: opacity ?? this.opacity,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      color: color ?? this.color,
    );
  }
}
