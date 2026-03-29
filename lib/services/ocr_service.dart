import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final double? liters;
  final double? pricePerLiter;
  final double? totalCost;
  final DateTime? date;
  final bool isAccurate;
  final String? errorMessage;

  OcrResult({
    this.liters,
    this.pricePerLiter,
    this.totalCost,
    this.date,
    this.isAccurate = false,
    this.errorMessage,
  });
}

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> processImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return _parseReceiptData(recognizedText.text);
    } catch (e) {
      return OcrResult(
        isAccurate: false,
        errorMessage: 'Fiş okunamadı: ${e.toString()}',
      );
    }
  }

  OcrResult _parseReceiptData(String text) {
    double? liters;
    double? pricePerLiter;
    double? totalCost;
    DateTime? date;

    final lines = text.split('\n');

    // Date: 28.07.2023 / 28/07/2023 / 28-07-2023
    final dateRegex = RegExp(r'(\d{2})[-/.](\d{2})[-/.](\d{4})');

    // Primary liters pattern — Turkish POS format: "50,630 LT X 36,550"
    // group(1) = liters, group(2) = unit price per liter
    final ltXPriceRegex = RegExp(
      r'([\d.,]+)\s*LT\s*[Xx\u00d7]\s*([\d.,]+)',
      caseSensitive: false,
    );

    // Standalone liters fallback: "50,630 LT" or "MİKTAR: 50,630"
    final ltOnlyRegex = RegExp(
      r'([\d.,]+)\s*LT\b',
      caseSensitive: false,
    );
    final miktarRegex = RegExp(
      r'(?:M[İI]KTAR|L[İI]TRE|HACM[İI])[:\s]*([\d.,]+)',
      caseSensitive: false,
    );

    // TOPLAM / TUTAR — asterisk (*) is common on Turkish POS receipts:
    // "TOPLAM *1.850,53"  |  "TUTAR: 1850,53"  |  "KDV DAHİL *1.850,53"
    final totalRegex = RegExp(
      r'(?:TOPLAM|TUTAR|GENEL\s*TOPLAM|KDV\s*DAH[İI]L)\s*[:\*\s]*([\d.,]+)',
      caseSensitive: false,
    );

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // 1. Date
      if (date == null) {
        final m = dateRegex.firstMatch(line);
        if (m != null) {
          try {
            final day = int.parse(m.group(1)!);
            final month = int.parse(m.group(2)!);
            final year = int.parse(m.group(3)!);
            if (year > 2000 && year <= DateTime.now().year) {
              date = DateTime(year, month, day);
            }
          } catch (_) {}
        }
      }

      // 2. "50,630 LT X 36,550" — liters + unit price in one line (best case)
      if (liters == null || pricePerLiter == null) {
        final m = ltXPriceRegex.firstMatch(line);
        if (m != null) {
          final l = _parseDouble(m.group(1)!);
          final p = _parseDouble(m.group(2)!);
          if (l != null && l > 0.5 && l < 500) liters = l;
          if (p != null && p > 5 && p < 300) pricePerLiter = p;
        }
      }

      // 3. Liters-only fallbacks
      if (liters == null) {
        var m = ltOnlyRegex.firstMatch(line);
        m ??= miktarRegex.firstMatch(line);
        if (m != null) {
          final l = _parseDouble(m.group(1)!);
          if (l != null && l > 0.5 && l < 500) liters = l;
        }
      }

      // 4. TOPLAM / TUTAR — pick the last (largest) match to avoid KDV line
      final totalMatch = totalRegex.firstMatch(line);
      if (totalMatch != null) {
        final t = _parseDouble(totalMatch.group(1)!);
        if (t != null && t > 0) {
          // Keep the larger value (TOPLAM may appear twice; pick biggest)
          if (totalCost == null || t >= totalCost!) totalCost = t;
        }
      }
    }

    // 5. Derive totalCost from liters × pricePerLiter if still missing
    if (totalCost == null && liters != null && pricePerLiter != null) {
      totalCost = _roundTo2(liters! * pricePerLiter!);
    }

    // 6. Derive pricePerLiter if missing
    if (pricePerLiter == null && liters != null && totalCost != null && liters! > 0) {
      pricePerLiter = _roundTo2(totalCost! / liters!);
    }

    // 7. Sanity cross-check
    bool isAccurate = liters != null && totalCost != null && date != null;
    String? error;

    if (liters != null && totalCost != null) {
      final ppl = pricePerLiter ?? (totalCost! / liters!);
      if (ppl < 10 || ppl > 300) {
        isAccurate = false;
        error = 'Okunan tutar ve litre değerleri tutarsız görünüyor. Lütfen kontrol edin.';
      }
    } else {
      isAccurate = false;
      final missing = <String>[];
      if (liters == null) missing.add('litre');
      if (totalCost == null) missing.add('toplam tutar');
      if (date == null) missing.add('tarih');
      error = '${missing.join(', ')} okunamadı. Lütfen manuel kontrol edin.';
    }

    return OcrResult(
      liters: liters,
      pricePerLiter: pricePerLiter,
      totalCost: totalCost,
      date: date,
      isAccurate: isAccurate,
      errorMessage: error,
    );
  }

  double _roundTo2(double v) => (v * 100).round() / 100;

  double? _parseDouble(String val) {
    try {
      var clean = val.replaceAll(RegExp(r'[^0-9.,]'), '');
      if (clean.isEmpty) return null;
      if (clean.contains(',') && clean.contains('.')) {
        final lastComma = clean.lastIndexOf(',');
        final lastDot = clean.lastIndexOf('.');
        if (lastComma > lastDot) {
          // "1.850,53" Turkish: dot=thousands, comma=decimal
          clean = clean.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // "1,850.53" English: comma=thousands
          clean = clean.replaceAll(',', '');
        }
      } else if (clean.contains(',')) {
        clean = clean.replaceAll(',', '.');
      }
      return double.parse(clean);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
