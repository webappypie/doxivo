class DocumentModel {
  final String id;
  final String title;
  final String filePath;
  final String? thumbnailPath;
  final int pageCount;
  final int byteSize;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final List<String> tags;

  const DocumentModel({
    required this.id,
    required this.title,
    required this.filePath,
    this.thumbnailPath,
    required this.pageCount,
    required this.byteSize,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.tags = const [],
  });

  DocumentModel copyWith({
    String? id,
    String? title,
    String? filePath,
    String? thumbnailPath,
    int? pageCount,
    int? byteSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    List<String>? tags,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      pageCount: pageCount ?? this.pageCount,
      byteSize: byteSize ?? this.byteSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'page_count': pageCount,
      'byte_size': byteSize,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_favorite': isFavorite ? 1 : 0,
      'tags': tags.join(','),
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      title: map['title'] as String,
      filePath: map['file_path'] as String,
      thumbnailPath: map['thumbnail_path'] as String?,
      pageCount: map['page_count'] as int,
      byteSize: map['byte_size'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      tags: (map['tags'] as String?)?.split(',').where((t) => t.isNotEmpty).toList() ?? [],
    );
  }

  String get formattedSize {
    if (byteSize < 1024) return '$byteSize B';
    if (byteSize < 1024 * 1024) return '${(byteSize / 1024).toStringAsFixed(1)} KB';
    return '${(byteSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
