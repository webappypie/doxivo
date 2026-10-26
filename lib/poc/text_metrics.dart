import 'dart:math' as math;

/// Character Error Rate (CER) calculation using Levenshtein distance.
class TextMetrics {
  /// Computes the Levenshtein edit distance between [reference] and [hypothesis].
  static int levenshteinDistance(String reference, String hypothesis) {
    if (reference.isEmpty) return hypothesis.length;
    if (hypothesis.isEmpty) return reference.length;

    final refChars = reference.runes.toList();
    final hypChars = hypothesis.runes.toList();

    final m = refChars.length;
    final n = hypChars.length;

    List<int> prev = List<int>.generate(n + 1, (i) => i);
    List<int> curr = List<int>.filled(n + 1, 0);

    for (int i = 1; i <= m; i++) {
      curr[0] = i;
      for (int j = 1; j <= n; j++) {
        final cost = (refChars[i - 1] == hypChars[j - 1]) ? 0 : 1;
        curr[j] = math.min(
          prev[j] + 1, // deletion
          math.min(
            curr[j - 1] + 1, // insertion
            prev[j - 1] + cost, // substitution
          ),
        );
      }
      final temp = prev;
      prev = curr;
      curr = temp;
    }

    return prev[n];
  }

  /// Calculates Character Error Rate (CER) as: (S + D + I) / N
  ///
  /// Normalized to [0.0, 1.0+] where 0.0 is perfect accuracy.
  static double calculateCer(String reference, String hypothesis, {bool ignoreWhitespace = false}) {
    String ref = reference;
    String hyp = hypothesis;

    if (ignoreWhitespace) {
      ref = ref.replaceAll(RegExp(r'\s+'), '');
      hyp = hyp.replaceAll(RegExp(r'\s+'), '');
    }

    if (ref.isEmpty) {
      return hyp.isEmpty ? 0.0 : 1.0;
    }

    final distance = levenshteinDistance(ref, hyp);
    return distance / ref.runes.length;
  }
}
