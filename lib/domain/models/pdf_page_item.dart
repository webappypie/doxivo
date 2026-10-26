class PdfPageItem {
  final int pageIndex;
  final int rotationDegrees; // 0, 90, 180, 270
  final String? thumbnailPath;
  final bool isSelected;

  const PdfPageItem({
    required this.pageIndex,
    this.rotationDegrees = 0,
    this.thumbnailPath,
    this.isSelected = true,
  });

  PdfPageItem copyWith({
    int? pageIndex,
    int? rotationDegrees,
    String? thumbnailPath,
    bool? isSelected,
  }) {
    return PdfPageItem(
      pageIndex: pageIndex ?? this.pageIndex,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
