enum OcrLanguage {
  english(
    code: 'en',
    displayName: 'English (Latin)',
    scriptName: 'Latin',
  ),
  hindi(
    code: 'hi',
    displayName: 'Hindi (Devanagari)',
    scriptName: 'Devanagari',
  );

  final String code;
  final String displayName;
  final String scriptName;

  const OcrLanguage({
    required this.code,
    required this.displayName,
    required this.scriptName,
  });

  static OcrLanguage fromCode(String code) {
    if (code.toLowerCase() == 'hi') return OcrLanguage.hindi;
    return OcrLanguage.english;
  }
}
