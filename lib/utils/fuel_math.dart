import '../models/fuel_record.dart';

/// İki tam depo dolumu arasındaki tüketim penceresi.
///
/// Varsayım: her iki uçtaki kayıt da tam depo. Pencere içindeki tüketim,
/// başlangıç dolumundan SONRAKİ kayıtlardan bitiş dolumu DAHİL alınan
/// yakıtın toplamıdır (bitiş dolumunda depo yeniden tam olduğu için
/// aradaki tüm alımlar yakılmıştır).
class ConsumptionWindow {
  final DateTime startDate;
  final DateTime endDate;
  final double startKm;
  final double endKm;
  final double liters;
  final double cost;

  const ConsumptionWindow({
    required this.startDate,
    required this.endDate,
    required this.startKm,
    required this.endKm,
    required this.liters,
    required this.cost,
  });

  double get kmDriven => endKm - startKm;
  double get litersPer100km => kmDriven > 0 ? liters / kmDriven * 100 : 0;
  double get costPerKm => kmDriven > 0 ? cost / kmDriven : 0;
}

/// Araç için özet yakıt istatistikleri.
class FuelStats {
  final int recordCount;
  final double totalCost;
  final double totalLiters;
  final double avgPricePerLiter;
  final double litersPer100km;
  final double costPerKm;
  final double totalKmDriven;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const FuelStats({
    this.recordCount = 0,
    this.totalCost = 0,
    this.totalLiters = 0,
    this.avgPricePerLiter = 0,
    this.litersPer100km = 0,
    this.costPerKm = 0,
    this.totalKmDriven = 0,
    this.firstDate,
    this.lastDate,
  });
}

/// Kayıtları tarih/km/id sırasına göre sıralar (kararlı hesap için).
List<FuelRecord> sortRecords(List<FuelRecord> records) {
  final sorted = List<FuelRecord>.from(records);
  sorted.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    final byKm = a.km.compareTo(b.km);
    if (byKm != 0) return byKm;
    return (a.id ?? 0).compareTo(b.id ?? 0);
  });
  return sorted;
}

/// Ardışık tam depo dolumları arasındaki geçerli tüketim pencerelerini üretir.
/// km artışı olmayan (<= 0) pencereler atlanır.
List<ConsumptionWindow> computeFullTankWindows(List<FuelRecord> records) {
  final sorted = sortRecords(records);
  final windows = <ConsumptionWindow>[];

  FuelRecord? windowStart;
  var liters = 0.0;
  var cost = 0.0;

  for (final record in sorted) {
    if (windowStart == null) {
      if (record.fullTank) windowStart = record;
      continue;
    }

    liters += record.liters;
    cost += record.totalCost;

    if (record.fullTank) {
      if (record.km > windowStart.km) {
        windows.add(ConsumptionWindow(
          startDate: windowStart.date,
          endDate: record.date,
          startKm: windowStart.km,
          endKm: record.km,
          liters: liters,
          cost: cost,
        ));
      }
      windowStart = record;
      liters = 0.0;
      cost = 0.0;
    }
  }

  return windows;
}

/// Özet istatistikleri hesaplar.
///
/// Toplam maliyet/litre TÜM kayıtları kapsar; tüketim (L/100km) ve km başı
/// maliyet yalnızca tam depo pencereleri üzerinden hesaplanır — böylece
/// kısmi dolumlar başlık metriğini bozmaz.
FuelStats computeFuelStats(List<FuelRecord> records) {
  if (records.isEmpty) return const FuelStats();

  final sorted = sortRecords(records);
  final totalCost =
      sorted.fold<double>(0, (sum, r) => sum + r.totalCost);
  final totalLiters =
      sorted.fold<double>(0, (sum, r) => sum + r.liters);
  final totalKmDriven = sorted.last.km - sorted.first.km;

  final windows = computeFullTankWindows(sorted);
  final windowLiters =
      windows.fold<double>(0, (sum, w) => sum + w.liters);
  final windowCost = windows.fold<double>(0, (sum, w) => sum + w.cost);
  final windowKm = windows.fold<double>(0, (sum, w) => sum + w.kmDriven);

  return FuelStats(
    recordCount: sorted.length,
    totalCost: totalCost,
    totalLiters: totalLiters,
    avgPricePerLiter: totalLiters > 0 ? totalCost / totalLiters : 0,
    litersPer100km: windowKm > 0 ? windowLiters / windowKm * 100 : 0,
    costPerKm: windowKm > 0 ? windowCost / windowKm : 0,
    totalKmDriven: totalKmDriven > 0 ? totalKmDriven : 0,
    firstDate: sorted.first.date,
    lastDate: sorted.last.date,
  );
}
