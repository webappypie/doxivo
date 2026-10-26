import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:doxivo/presentation/toolkit/signature/signature_pad_widget.dart';

void main() {
  testWidgets('SignaturePadWidget renders and manages strokes', (WidgetTester tester) async {
    final key = GlobalKey<SignaturePadWidgetState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SignaturePadWidget(key: key),
        ),
      ),
    );

    expect(find.text('Sign on the line above'), findsOneWidget);
    expect(key.currentState?.isEmpty, isTrue);

    // Initial export with no strokes returns null
    final initialPng = await key.currentState?.exportPngBytes();
    expect(initialPng, isNull);

    // Simulate drawing gesture
    final gesture = await tester.startGesture(tester.getCenter(find.byType(CustomPaint).last));
    await gesture.moveBy(const Offset(50, 20));
    await gesture.moveBy(const Offset(80, -10));
    await gesture.up();

    await tester.pump();
    expect(key.currentState?.isEmpty, isFalse);

    // Color and width adjustments
    key.currentState?.setStrokeColor(Colors.blue);
    key.currentState?.setStrokeWidth(5.0);

    // Test clear
    key.currentState?.clear();
    await tester.pump();
    expect(key.currentState?.isEmpty, isTrue);
  });
}
