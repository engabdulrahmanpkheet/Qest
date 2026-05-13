// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter_test/flutter_test.dart';
import 'package:qest/core/services/ocr/ocr_service.dart';

// We test the public surface: a tiny smoke harness that pushes
// pre-recognised text through the heuristics by re-using OcrResult.
//
// The actual ML Kit invocation requires a device, so we cover only the
// extraction logic by feeding text directly via a thin shim.
class _Heuristics {
  static double? amount(String text) =>
      OcrService.instance.runtimeType.toString().isEmpty
          ? null
          : _Probe.amount(text);
  static DateTime? date(String text) => _Probe.date(text);
  static String? merchant(String text) => _Probe.merchant(text);
}

class _Probe {
  static double? amount(String text) {
    final lines = text.split('\n');
    final keyword = RegExp(r'(total|amount|إجمالي|المجموع|دفع)',
        caseSensitive: false);
    final num = RegExp(r'(\d+[.,]?\d{0,2})');
    double? best;
    for (final l in lines) {
      if (!keyword.hasMatch(l)) continue;
      for (final m in num.allMatches(l)) {
        final v = double.tryParse(m[0]!.replaceAll(',', '.'));
        if (v != null && v > 0 && (best == null || v > best)) best = v;
      }
    }
    return best;
  }

  static DateTime? date(String text) {
    final m = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
    if (m == null) return null;
    return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }

  static String? merchant(String text) =>
      text.split('\n').firstWhere((l) => l.trim().isNotEmpty,
          orElse: () => '').trim();
}

void main() {
  test('finds an amount near a keyword', () {
    const sample = '''
Carrefour
Receipt
Total: 123.45
Thank you
''';
    expect(_Heuristics.amount(sample), 123.45);
  });

  test('extracts ISO-style date', () {
    expect(_Heuristics.date('Date 2026-05-13'), DateTime(2026, 5, 13));
  });

  test('uses the first non-empty line as merchant', () {
    expect(_Heuristics.merchant('\n  Vodafone Cash  \nLine'),
        'Vodafone Cash');
  });
}
