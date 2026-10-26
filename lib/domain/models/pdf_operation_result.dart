class PdfOperationResult {
  final bool isSuccess;
  final String? outputPath;
  final int beforeBytes;
  final int afterBytes;
  final int pageCount;
  final String? errorMessage;

  const PdfOperationResult({
    required this.isSuccess,
    this.outputPath,
    this.beforeBytes = 0,
    this.afterBytes = 0,
    this.pageCount = 0,
    this.errorMessage,
  });

  double get reductionPercentage {
    if (beforeBytes <= 0 || afterBytes <= 0) return 0.0;
    final diff = beforeBytes - afterBytes;
    if (diff <= 0) return 0.0;
    return (diff / beforeBytes) * 100.0;
  }
}
