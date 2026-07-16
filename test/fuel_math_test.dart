import 'package:flutter_test/flutter_test.dart';
import 'package:yakit_yonet/models/fuel_record.dart';
import 'package:yakit_yonet/utils/fuel_math.dart';

FuelRecord record({
  int? id,
  required int day,
  required double km,
  required double liters,
  double pricePerLiter = 40,
  bool fullTank = true,
}) {
  return FuelRecord(
    id: id,
    vehicleId: 1,
    date: DateTime(2026, 1, day),
    km: km,
    liters: liters,
    pricePerLiter: pricePerLiter,
    totalCost: liters * pricePerLiter,
    fullTank: fullTank,
  );
}

void main() {
  group('computeFullTankWindows', () {
    test('iki tam depo arası tek pencere', () {
      final windows = computeFullTankWindows([
        record(day: 1, km: 1000, liters: 40),
        record(day: 10, km: 1500, liters: 50),
      ]);

      expect(windows, hasLength(1));
      expect(windows.first.kmDriven, 500);
      expect(windows.first.liters, 50);
      expect(windows.first.litersPer100km, 10);
    });

    test('aradaki kısmi dolum pencereye dahil edilir', () {
      final windows = computeFullTankWindows([
        record(day: 1, km: 1000, liters: 40),
        record(day: 5, km: 1250, liters: 20, fullTank: false),
        record(day: 10, km: 1500, liters: 30),
      ]);

      expect(windows, hasLength(1));
      expect(windows.first.liters, 50);
      expect(windows.first.kmDriven, 500);
      expect(windows.first.litersPer100km, 10);
    });

    test('km artışı olmayan pencere atlanır', () {
      final windows = computeFullTankWindows([
        record(day: 1, km: 1000, liters: 40),
        record(day: 2, km: 1000, liters: 5),
      ]);

      expect(windows, isEmpty);
    });

    test('baştaki kısmi dolumlar pencere başlatmaz', () {
      final windows = computeFullTankWindows([
        record(day: 1, km: 900, liters: 15, fullTank: false),
        record(day: 2, km: 1000, liters: 40),
        record(day: 9, km: 1400, liters: 44),
      ]);

      expect(windows, hasLength(1));
      expect(windows.first.startKm, 1000);
      expect(windows.first.liters, 44);
    });
  });

  group('computeFuelStats', () {
    test('boş liste varsayılanlar', () {
      final stats = computeFuelStats([]);
      expect(stats.recordCount, 0);
      expect(stats.totalCost, 0);
      expect(stats.litersPer100km, 0);
    });

    test('toplamlar tüm kayıtları kapsar, tüketim pencere bazlı', () {
      final stats = computeFuelStats([
        record(day: 1, km: 1000, liters: 40),
        record(day: 10, km: 1500, liters: 50),
        record(day: 15, km: 1700, liters: 18, fullTank: false),
      ]);

      expect(stats.recordCount, 3);
      expect(stats.totalLiters, 108);
      expect(stats.totalCost, 108 * 40);
      expect(stats.avgPricePerLiter, 40);
      expect(stats.litersPer100km, 10);
      expect(stats.costPerKm, 50 * 40 / 500);
      expect(stats.totalKmDriven, 700);
    });

    test('tek kayıt: tüketim 0 ama toplamlar dolu', () {
      final stats = computeFuelStats([
        record(day: 1, km: 1000, liters: 40),
      ]);

      expect(stats.totalCost, 1600);
      expect(stats.litersPer100km, 0);
      expect(stats.costPerKm, 0);
    });

    test('aynı gün kayıtlar km sırasına göre işlenir', () {
      final stats = computeFuelStats([
        record(id: 2, day: 1, km: 1500, liters: 50),
        record(id: 1, day: 1, km: 1000, liters: 40),
      ]);

      expect(stats.litersPer100km, 10);
    });
  });
}
