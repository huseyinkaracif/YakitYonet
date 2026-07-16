/// Türkçe klavye girişleriyle uyumlu esnek sayı ayrıştırma yardımcıları.
///
/// Kullanıcılar ondalık ayracı olarak virgül (45,5) veya nokta (45.5)
/// girebilir; binlik ayraçlı girişler (1.500,50 / 1,500.50) de desteklenir.
library;

/// "1.500,50", "1,500.50", "45,5", "45.5" gibi girdileri double'a çevirir.
/// Ayrıştırılamazsa null döner.
double? parseFlexibleDouble(String? input) {
  if (input == null) return null;
  var s = input.trim();
  if (s.isEmpty) return null;

  s = s.replaceAll(' ', '').replaceAll('₺', '').replaceAll('TL', '');
  if (s.isEmpty) return null;

  final lastComma = s.lastIndexOf(',');
  final lastDot = s.lastIndexOf('.');

  if (lastComma >= 0 && lastDot >= 0) {
    if (lastComma > lastDot) {
      // 1.500,50 → nokta binlik, virgül ondalık
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // 1,500.50 → virgül binlik, nokta ondalık
      s = s.replaceAll(',', '');
    }
  } else if (lastComma >= 0) {
    final commaCount = ','.allMatches(s).length;
    if (commaCount > 1) {
      // 1,500,000 → binlik ayraç
      s = s.replaceAll(',', '');
    } else {
      s = s.replaceAll(',', '.');
    }
  } else if (lastDot >= 0) {
    final dotCount = '.'.allMatches(s).length;
    final digitsAfter = s.length - lastDot - 1;
    if (dotCount > 1 || (digitsAfter == 3 && s.length > 4)) {
      // 1.500.000 veya 1.500 → binlik ayraç
      s = s.replaceAll('.', '');
    }
  }

  return double.tryParse(s);
}

/// [parseFlexibleDouble] sonucu pozitif değilse null döner.
double? parsePositiveDouble(String? input) {
  final value = parseFlexibleDouble(input);
  if (value == null || value <= 0) return null;
  return value;
}

/// Tam sayı (km gibi) alanları için esnek ayrıştırma.
int? parseFlexibleInt(String? input) {
  final value = parseFlexibleDouble(input);
  if (value == null) return null;
  return value.round();
}
