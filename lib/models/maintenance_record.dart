class MaintenanceRecord {
  final int? id;
  final int vehicleId;
  final DateTime date;
  final double km;
  final String title;
  final String? description;
  final double cost;
  final String category; // Yağ Değişimi, Fren, Lastik, Genel Bakım, Diğer
  final String? note;

  MaintenanceRecord({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.km,
    required this.title,
    this.description,
    required this.cost,
    required this.category,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'km': km,
      'title': title,
      'description': description,
      'cost': cost,
      'category': category,
      'note': note,
    };
  }

  factory MaintenanceRecord.fromMap(Map<String, dynamic> map) {
    return MaintenanceRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicleId'] as int,
      date: DateTime.parse(map['date'] as String),
      km: (map['km'] as num).toDouble(),
      title: map['title'] as String,
      description: map['description'] as String?,
      cost: (map['cost'] as num).toDouble(),
      category: map['category'] as String,
      note: map['note'] as String?,
    );
  }

  MaintenanceRecord copyWith({
    int? id,
    int? vehicleId,
    DateTime? date,
    double? km,
    String? title,
    String? description,
    double? cost,
    String? category,
    String? note,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      km: km ?? this.km,
      title: title ?? this.title,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      category: category ?? this.category,
      note: note ?? this.note,
    );
  }
}
