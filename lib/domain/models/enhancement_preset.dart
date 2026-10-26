enum EnhancementPreset {
  original,
  grayscale,
  blackAndWhite,
  enhancedColor;

  String get displayName {
    switch (this) {
      case EnhancementPreset.original:
        return 'Original';
      case EnhancementPreset.grayscale:
        return 'Grayscale';
      case EnhancementPreset.blackAndWhite:
        return 'B&W Doc';
      case EnhancementPreset.enhancedColor:
        return 'Vibrant';
    }
  }
}
