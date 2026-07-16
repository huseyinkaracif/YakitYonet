import 'package:flutter_test/flutter_test.dart';
import 'package:yakit_yonet/utils/parsing.dart';

void main() {
  group('parseFlexibleDouble', () {
    test('nokta ondalık', () {
      expect(parseFlexibleDouble('45.5'), 45.5);
    });

    test('virgül ondalık', () {
      expect(parseFlexibleDouble('45,5'), 45.5);
    });

    test('binlik nokta + virgül ondalık', () {
      expect(parseFlexibleDouble('1.500,50'), 1500.50);
    });

    test('binlik virgül + nokta ondalık', () {
      expect(parseFlexibleDouble('1,500.50'), 1500.50);
    });

    test('çoklu binlik ayraç', () {
      expect(parseFlexibleDouble('1.500.000'), 1500000);
      expect(parseFlexibleDouble('1,500,000'), 1500000);
    });

    test('tam sayı', () {
      expect(parseFlexibleDouble('120000'), 120000);
    });

    test('boşluk ve para birimi temizliği', () {
      expect(parseFlexibleDouble(' 1.250,75 TL '), 1250.75);
      expect(parseFlexibleDouble('₺45,90'), 45.90);
    });

    test('geçersiz girişler null döner', () {
      expect(parseFlexibleDouble(''), isNull);
      expect(parseFlexibleDouble(null), isNull);
      expect(parseFlexibleDouble('abc'), isNull);
      expect(parseFlexibleDouble('12.34.5,6,7'), isNull);
    });
  });

  group('parsePositiveDouble', () {
    test('pozitif değer geçer', () {
      expect(parsePositiveDouble('10,5'), 10.5);
    });

    test('sıfır ve negatif null döner', () {
      expect(parsePositiveDouble('0'), isNull);
      expect(parsePositiveDouble('-5'), isNull);
    });
  });

  group('parseFlexibleInt', () {
    test('km girişi', () {
      expect(parseFlexibleInt('125.000'), 125000);
      expect(parseFlexibleInt('125000'), 125000);
    });
  });
}
