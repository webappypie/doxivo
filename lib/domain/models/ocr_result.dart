import 'ocr_language.dart';
import 'ocr_text_geometry.dart';

class OcrResult {
  final String fullText;
  final List<OcrLine> lines;
  final List<OcrBlock> blocks;
  final OcrLanguage language;
  final int pageIndex;
  final double? confidence;
  final bool isSuccess;
  final String? errorMessage;
  final double imageWidth;
  final double imageHeight;

  const OcrResult({
    required this.fullText,
    this.lines = const [],
    this.blocks = const [],
    this.language = OcrLanguage.english,
    this.pageIndex = 0,
    this.confidence,
    this.isSuccess = true,
    this.errorMessage,
    this.imageWidth = 0.0,
    this.imageHeight = 0.0,
  });

  factory OcrResult.failure({
    required String errorMessage,
    OcrLanguage language = OcrLanguage.english,
    int pageIndex = 0,
  }) {
    return OcrResult(
      fullText: '',
      lines: const [],
      blocks: const [],
      language: language,
      pageIndex: pageIndex,
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }

  bool get hasText => fullText.trim().isNotEmpty;
  int get wordCount => fullText.trim().isEmpty ? 0 : fullText.trim().split(RegExp(r'\s+')).length;
  int get lineCount => lines.isNotEmpty ? lines.length : (fullText.trim().isEmpty ? 0 : fullText.split('\n').length);
}
