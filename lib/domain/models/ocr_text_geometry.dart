class OcrRect {
  final double left;
  final double top;
  final double width;
  final double height;

  const OcrRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  double get right => left + width;
  double get bottom => top + height;

  Map<String, dynamic> toMap() => {
    'left': left,
    'top': top,
    'width': width,
    'height': height,
  };

  factory OcrRect.fromMap(Map<String, dynamic> map) {
    return OcrRect(
      left: (map['left'] as num).toDouble(),
      top: (map['top'] as num).toDouble(),
      width: (map['width'] as num).toDouble(),
      height: (map['height'] as num).toDouble(),
    );
  }
}

class OcrElement {
  final String text;
  final OcrRect? boundingBox;
  final double? confidence;

  const OcrElement({
    required this.text,
    this.boundingBox,
    this.confidence,
  });
}

class OcrLine {
  final String text;
  final List<OcrElement> elements;
  final OcrRect? boundingBox;
  final double? confidence;

  const OcrLine({
    required this.text,
    this.elements = const [],
    this.boundingBox,
    this.confidence,
  });
}

class OcrBlock {
  final String text;
  final List<OcrLine> lines;
  final OcrRect? boundingBox;
  final String? language;

  const OcrBlock({
    required this.text,
    this.lines = const [],
    this.boundingBox,
    this.language,
  });
}
