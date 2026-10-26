import 'package:flutter_test/flutter_test.dart';
import 'package:doxivo/main.dart';

void main() {
  testWidgets('Doxivo PoC Home Screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const DoxivoApp());

    // Verify app title and key PoC sections are displayed
    expect(find.text('Doxivo — Phase 00 PoC'), findsOneWidget);
    expect(find.text('Privacy Boundary: Local-First'), findsOneWidget);
    expect(find.text('1. PDF Engine PoC (Creation & Watermark)'), findsOneWidget);
    expect(find.text('2. Document Image Pipeline'), findsOneWidget);
    expect(find.text('3. Native Document Scanner'), findsOneWidget);
    expect(find.text('4. Offline OCR & CER Evaluation'), findsOneWidget);

    // Verify interactive action buttons exist
    expect(find.text('Create PDF'), findsOneWidget);
    expect(find.text('Watermark PDF'), findsOneWidget);
    expect(find.text('Grayscale'), findsOneWidget);
    expect(find.text('Black & White'), findsOneWidget);
    expect(find.text('Run Levenshtein CER Metric Test'), findsOneWidget);
  });
}
