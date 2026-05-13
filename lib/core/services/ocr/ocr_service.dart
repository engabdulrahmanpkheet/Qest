import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of OCRing a receipt image. Any field may be null when the
/// extractor isn't confident.
class OcrResult {
  const OcrResult({
    required this.rawText,
    this.amount,
    this.date,
    this.merchant,
  });

  final String rawText;
  final double? amount;
  final DateTime? date;
  final String? merchant;
}

/// Receipt OCR. Combines ML Kit text recognition with light heuristics
/// to pull out the most-likely amount, date and merchant string.
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  // Latin + Arabic scripts cover Egyptian receipts well.
  final TextRecognizer _latin =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> extract(File imageFile) async {
    final input = InputImage.fromFile(imageFile);
    final recognised = await _latin.processImage(input);
    final text = recognised.text;

    return OcrResult(
      rawText: text,
      amount: _extractAmount(text),
      date: _extractDate(text),
      merchant: _extractMerchant(text),
    );
  }

  Future<void> dispose() async {
    await _latin.close();
  }

  // ---- heuristics ---------------------------------------------------

  /// Highest-confidence amount: prefer numbers near keywords like
  /// "total", "إجمالي", "amount". Otherwise the largest plausible decimal.
  double? _extractAmount(String text) {
    if (text.isEmpty) return null;
    final lines = text.split('\n');
    final keywordRe = RegExp(
      r'(total|amount|paid|إجمالي|المجموع|قيمة|دفع)',
      caseSensitive: false,
    );
    final numberRe = RegExp(r'(\d{1,3}(?:[,٬]\d{3})*(?:[.٫]\d{1,2})?|\d+(?:[.٫]\d{1,2})?)');

    double? bestKeyword;
    double bestAny = 0;
    for (final line in lines) {
      final matches = numberRe.allMatches(line).toList();
      if (matches.isEmpty) continue;
      final hasKeyword = keywordRe.hasMatch(line);
      for (final m in matches) {
        final raw = m
            .group(0)!
            .replaceAll(',', '')
            .replaceAll('٬', '')
            .replaceAll('٫', '.');
        final v = double.tryParse(raw);
        if (v == null || v <= 0 || v > 9999999) continue;
        if (hasKeyword) {
          bestKeyword = (bestKeyword == null || v > bestKeyword) ? v : bestKeyword;
        }
        if (v > bestAny) bestAny = v;
      }
    }
    return bestKeyword ?? (bestAny > 0 ? bestAny : null);
  }

  DateTime? _extractDate(String text) {
    if (text.isEmpty) return null;
    final patterns = <RegExp>[
      RegExp(r'(\d{4})[-/](\d{1,2})[-/](\d{1,2})'), // 2026-05-13
      RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{4})'), // 13/05/2026
      RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{2})'), // 13/05/26
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m == null) continue;
      try {
        if (p == patterns[0]) {
          return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
        }
        if (p == patterns[1]) {
          return DateTime(int.parse(m[3]!), int.parse(m[2]!), int.parse(m[1]!));
        }
        final yy = int.parse(m[3]!);
        return DateTime(2000 + yy, int.parse(m[2]!), int.parse(m[1]!));
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Merchant: first non-empty line that's mostly letters & not currency.
  String? _extractMerchant(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
    for (final l in lines) {
      if (l.length < 3 || l.length > 40) continue;
      final letters = RegExp(r'\p{L}', unicode: true).allMatches(l).length;
      if (letters >= l.length * 0.5) return l;
    }
    return null;
  }
}
