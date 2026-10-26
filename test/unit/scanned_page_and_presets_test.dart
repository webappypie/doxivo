import 'package:flutter_test/flutter_test.dart';
import 'package:doxivo/domain/models/enhancement_preset.dart';
import 'package:doxivo/domain/models/scanned_page.dart';

void main() {
  group('ScannedPage and Presets Tests', () {
    test('EnhancementPreset display names', () {
      expect(EnhancementPreset.original.displayName, equals('Original'));
      expect(EnhancementPreset.grayscale.displayName, equals('Grayscale'));
      expect(EnhancementPreset.blackAndWhite.displayName, equals('B&W Doc'));
      expect(EnhancementPreset.enhancedColor.displayName, equals('Vibrant'));
    });

    test('PointCoord serialization and parsing', () {
      const pt = PointCoord(0.25, 0.75);
      final json = pt.toJson();
      expect(json['x'], equals(0.25));
      expect(json['y'], equals(0.75));

      final restored = PointCoord.fromJson(json);
      expect(restored.x, equals(0.25));
      expect(restored.y, equals(0.75));
    });

    test('ScannedPage copyWith non-destructive updates', () {
      final page = ScannedPage(
        id: 'p1',
        originalPath: '/path/orig.jpg',
        currentPath: '/path/orig.jpg',
        rotation: 0,
        preset: EnhancementPreset.original,
      );

      final edited = page.copyWith(
        currentPath: '/path/edited.jpg',
        rotation: 90,
        preset: EnhancementPreset.blackAndWhite,
      );

      expect(edited.id, equals('p1'));
      expect(edited.originalPath, equals('/path/orig.jpg')); // Preserved!
      expect(edited.currentPath, equals('/path/edited.jpg'));
      expect(edited.rotation, equals(90));
      expect(edited.preset, equals(EnhancementPreset.blackAndWhite));
    });
  });
}
