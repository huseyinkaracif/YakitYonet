import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  final double? liters;
  final double? totalCost;
  final DateTime? date;
  final bool isAccurate;
  final String? errorMessage;

  OcrResult({
    this.liters,
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
    double? totalCost;
    DateTime? date;

    final lines = text.split('\n');
    
    // Regex Patterns
    final dateRegex = RegExp(r'(\d{2})[-/.](\d{2})[-/.](\d{4})');
    final totalRegex = RegExp(r'(?:TOPLAM|TUTAR|KDV DAH[Iİ]L)[:\s]*([\d.,]+)', caseSensitive: false);
    final literRegex = RegExp(r'(?:M[Iİ]KTAR|L[Iİ]TRE|L(?:T)?|HACM[Iİ])[:\s]*([\d.,]+)', caseSensitive: false);

    for (var line in lines) {
      line = line.toUpperCase().replaceAll(' ', '');

      // Parse Date
      if (date == null) {
        final dateMatch = dateRegex.firstMatch(line);
        if (dateMatch != null) {
          try {
            final day = int.parse(dateMatch.group(1)!);
            final month = int.parse(dateMatch.group(2)!);
            final year = int.parse(dateMatch.group(3)!);
            if (year > 2000 && year <= DateTime.now().year) {
               date = DateTime(year, month, day);
            }
          } catch (_) {}
        }
      }

      // Parse Total Cost
      if (totalCost == null) {
        final totalMatch = totalRegex.firstMatch(line);
        if (totalMatch != null) {
          totalCost = _parseDouble(totalMatch.group(1)!);
        }
      }

      // Parse Liters
      if (liters == null) {
         final literMatch = literRegex.firstMatch(line);
         if (literMatch != null) {
           liters = _parseDouble(literMatch.group(1)!);
         }
      }
    }

    // Heuristic fallback if regex missed total/liters but they exist as numbers
    if (totalCost == null || liters == null) {
       final numbers = _extractAllNumbers(text);
       if (numbers.isNotEmpty) {
           numbers.sort((a, b) => b.compareTo(a)); // largest first
           if (totalCost == null && numbers.isNotEmpty) {
               totalCost = numbers.first;
           }
           if (liters == null && numbers.length > 1) {
               // usually liters is smaller than total cost but bigger than unit price
               for(var n in numbers) {
                   if (n < (totalCost ?? double.infinity) && n > 5.0 && n < 150.0) {
                       liters = n;
                       break;
                   }
               }
           }
       }
    }


    bool isAccurate = liters != null && totalCost != null && date != null;
    String? error;
    
    if (liters != null && totalCost != null) {
       // Basic sanity check: is the price per liter reasonable? (e.g. between 20 TL and 60 TL)
       final pricePerLiter = totalCost / liters;
       if (pricePerLiter < 10 || pricePerLiter > 100) {
           isAccurate = false;
           error = 'Okunan tutar ve litre oranları tutarsız görünüyor.';
       }
    } else {
        isAccurate = false;
        error = 'Bazı zorunlu alanlar okunamadı. Lütfen manuel kontrol edin.';
    }

    return OcrResult(
      liters: liters,
      totalCost: totalCost,
      date: date,
      isAccurate: isAccurate,
      errorMessage: error,
    );
  }

  double? _parseDouble(String val) {
    try {
      // Handle Turkish format (comma as decimal separator)
      var clean = val.replaceAll(RegExp(r'[^0-9.,]'), '');
      if (clean.contains(',') && clean.contains('.')) {
         // Has both. Assume the last one is the decimal separator
         final lastComma = clean.lastIndexOf(',');
         final lastDot = clean.lastIndexOf('.');
         if (lastComma > lastDot) {
             clean = clean.replaceAll('.', '').replaceAll(',', '.');
         } else {
             clean = clean.replaceAll(',', '');
         }
      } else if (clean.contains(',')) {
         clean = clean.replaceAll(',', '.');
      }
      return double.parse(clean);
    } catch (e) {
      return null;
    }
  }

  List<double> _extractAllNumbers(String text) {
      final matches = RegExp(r'(\d+[\.,]\d+)').allMatches(text);
      List<double> nums = [];
      for (var m in matches) {
          final p = _parseDouble(m.group(1)!);
          if (p != null) nums.add(p);
      }
      return nums;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
