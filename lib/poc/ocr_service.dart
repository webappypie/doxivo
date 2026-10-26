import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum OcrScriptLanguage {
  latin,
  devanagari,
}

class OcrResult {
  final String fullText;
  final List<String> lines;
  final OcrScriptLanguage script;

  const OcrResult({
    required this.fullText,
    required this.lines,
    required this.script,
  });
}

class OcrService {
  /// Recognizes text from an image file using the specified on-device script model.
  static Future<OcrResult> recognizeText(
    String imagePath, {
    OcrScriptLanguage script = OcrScriptLanguage.latin,
  }) async {
    final scriptModel = script == OcrScriptLanguage.devanagari
        ? TextRecognitionScript.devanagiri
        : TextRecognitionScript.latin;

    final recognizer = TextRecognizer(script: scriptModel);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await recognizer.processImage(inputImage);

      final lines = <String>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          lines.add(line.text);
        }
      }

      return OcrResult(
        fullText: recognizedText.text,
        lines: lines,
        script: script,
      );
    } finally {
      await recognizer.close();
    }
  }
}
