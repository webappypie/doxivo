class SignatureConfig {
  final String signatureImagePath;
  final int pageIndex;
  final double x;
  final double y;
  final double width;
  final double height;

  const SignatureConfig({
    required this.signatureImagePath,
    this.pageIndex = 0,
    this.x = 50.0,
    this.y = 50.0,
    this.width = 150.0,
    this.height = 75.0,
  });

  SignatureConfig copyWith({
    String? signatureImagePath,
    int? pageIndex,
    double? x,
    double? y,
    double? width,
    double? height,
  }) {
    return SignatureConfig(
      signatureImagePath: signatureImagePath ?? this.signatureImagePath,
      pageIndex: pageIndex ?? this.pageIndex,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
