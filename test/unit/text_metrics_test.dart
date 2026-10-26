import 'package:flutter_test/flutter_test.dart';
import 'package:doxivo/poc/text_metrics.dart';

void main() {
  group('TextMetrics and CER Evaluation', () {
    test('Levenshtein distance handles identical strings', () {
      expect(TextMetrics.levenshteinDistance('Doxivo Scanner', 'Doxivo Scanner'), equals(0));
      expect(TextMetrics.calculateCer('Doxivo Scanner', 'Doxivo Scanner'), equals(0.0));
    });

    test('Levenshtein distance handles single substitution', () {
      // 1 substitution ('a' -> 'o') in 5 characters -> CER = 1/5 = 0.2
      expect(TextMetrics.levenshteinDistance('hello', 'hallo'), equals(1));
      expect(TextMetrics.calculateCer('hello', 'hallo'), equals(0.2));
    });

    test('Levenshtein distance handles insertions and deletions', () {
      // insertion
      expect(TextMetrics.levenshteinDistance('doc', 'docs'), equals(1));
      // deletion
      expect(TextMetrics.levenshteinDistance('toolkit', 'tool'), equals(3));
    });

    test('CER calculation with Hindi (Devanagari) runes', () {
      const reference = 'दस्तावेज़ स्कैनर'; // Document scanner in Hindi
      const hypothesisExact = 'दस्तावेज़ स्कैनर';
      const hypothesisTypo = 'दस्तावेज स्कैनर'; // ज़ replaced with ज

      expect(TextMetrics.calculateCer(reference, hypothesisExact), equals(0.0));

      final cer = TextMetrics.calculateCer(reference, hypothesisTypo);
      expect(cer, greaterThan(0.0));
      expect(cer, lessThan(0.2)); // 1 character substitution out of ~15 runes
    });

    test('Whitespace normalization option in CER', () {
      const ref = 'Invoice # 1042';
      const hyp = 'Invoice #1042'; // missing space

      final cerWithSpace = TextMetrics.calculateCer(ref, hyp);
      final cerWithoutSpace = TextMetrics.calculateCer(ref, hyp, ignoreWhitespace: true);

      expect(cerWithSpace, greaterThan(0.0));
      expect(cerWithoutSpace, equals(0.0));
    });
  });
}
