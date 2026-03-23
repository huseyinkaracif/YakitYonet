class FuelRecord {
  final int? id;
  final int vehicleId;
  final DateTime date;
  final double km;
  final double liters;
  final double pricePerLiter;
  final double totalCost;
  final bool fullTank;
  final String? note;

  FuelRecord({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.km,
    required this.liters,
    required this.pricePerLiter,
    required this.totalCost,
    this.fullTank = true,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'km': km,
      'liters': liters,
      'pricePerLiter': pricePerLiter,
      'totalCost': totalCost,
      'fullTank': fullTank ? 1 : 0,
      'note': note,
    };
  }

  factory FuelRecord.fromMap(Map<String, dynamic> map) {
    return FuelRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicleId'] as int,
      date: DateTime.parse(map['date'] as String),
      km: (map['km'] as num).toDouble(),
      liters: (map['liters'] as num).toDouble(),
      pricePerLiter: (map['pricePerLiter'] as num).toDouble(),
      totalCost: (map['totalCost'] as num).toDouble(),
      fullTank: (map['fullTank'] as int) == 1,
      note: map['note'] as String?,
    );
  }

  FuelRecord copyWith({
    int? id,
    int? vehicleId,
    DateTime? date,
    double? km,
    double? liters,
    double? pricePerLiter,
    double? totalCost,
    bool? fullTank,
    String? note,
  }) {
    return FuelRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      km: km ?? this.km,
      liters: liters ?? this.liters,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      totalCost: totalCost ?? this.totalCost,
      fullTank: fullTank ?? this.fullTank,
      note: note ?? this.note,
    );
  }
}
