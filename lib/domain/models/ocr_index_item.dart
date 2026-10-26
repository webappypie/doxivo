class OcrIndexItem {
  final String id;
  final String documentId;
  final int pageIndex;
  final String textContent;
  final String language;
  final DateTime createdAt;

  const OcrIndexItem({
    required this.id,
    required this.documentId,
    required this.pageIndex,
    required this.textContent,
    required this.language,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'document_id': documentId,
      'page_index': pageIndex,
      'text_content': textContent,
      'language': language,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory OcrIndexItem.fromMap(Map<String, dynamic> map) {
    return OcrIndexItem(
      id: map['id'] as String,
      documentId: map['document_id'] as String,
      pageIndex: map['page_index'] as int,
      textContent: map['text_content'] as String,
      language: map['language'] as String? ?? 'en',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }
}
