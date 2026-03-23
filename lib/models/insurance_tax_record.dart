class InsuranceTaxRecord {
  final int? id;
  final int vehicleId;
  final DateTime date;
  final String type; // Trafik Sigortası, Kasko, MTV, Muayene, Diğer
  final String? provider; // Sigorta şirketi veya kurum
  final double cost;
  final DateTime? expiryDate;
  final String? policyNumber;
  final String? note;

  InsuranceTaxRecord({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.type,
    this.provider,
    required this.cost,
    this.expiryDate,
    this.policyNumber,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'type': type,
      'provider': provider,
      'cost': cost,
      'expiryDate': expiryDate?.toIso8601String(),
      'policyNumber': policyNumber,
      'note': note,
    };
  }

  factory InsuranceTaxRecord.fromMap(Map<String, dynamic> map) {
    return InsuranceTaxRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicleId'] as int,
      date: DateTime.parse(map['date'] as String),
      type: map['type'] as String,
      provider: map['provider'] as String?,
      cost: (map['cost'] as num).toDouble(),
      expiryDate: map['expiryDate'] != null
          ? DateTime.parse(map['expiryDate'] as String)
          : null,
      policyNumber: map['policyNumber'] as String?,
      note: map['note'] as String?,
    );
  }

  InsuranceTaxRecord copyWith({
    int? id,
    int? vehicleId,
    DateTime? date,
    String? type,
    String? provider,
    double? cost,
    DateTime? expiryDate,
    String? policyNumber,
    String? note,
  }) {
    return InsuranceTaxRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      cost: cost ?? this.cost,
      expiryDate: expiryDate ?? this.expiryDate,
      policyNumber: policyNumber ?? this.policyNumber,
      note: note ?? this.note,
    );
  }
}
