import 'document_model.dart';

class OcrSearchSnippet {
  final int pageIndex;
  final String matchedText;
  final String snippetContext;

  const OcrSearchSnippet({
    required this.pageIndex,
    required this.matchedText,
    required this.snippetContext,
  });
}

class DocumentSearchResult {
  final DocumentModel document;
  final bool matchedTitle;
  final List<OcrSearchSnippet> ocrMatches;

  const DocumentSearchResult({
    required this.document,
    this.matchedTitle = false,
    this.ocrMatches = const [],
  });

  bool get hasOcrMatches => ocrMatches.isNotEmpty;
  int get totalMatches => (matchedTitle ? 1 : 0) + ocrMatches.length;
}
