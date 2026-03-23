class Vehicle {
  final int? id;
  final String name;
  final double currentKm;
  final String fuelType; // LPG, Benzin, Dizel, Elektrik
  final double tankCapacity;
  final String? imagePath;
  final DateTime createdAt;

  Vehicle({
    this.id,
    required this.name,
    required this.currentKm,
    required this.fuelType,
    required this.tankCapacity,
    this.imagePath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currentKm': currentKm,
      'fuelType': fuelType,
      'tankCapacity': tankCapacity,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      name: map['name'] as String,
      currentKm: (map['currentKm'] as num).toDouble(),
      fuelType: map['fuelType'] as String,
      tankCapacity: (map['tankCapacity'] as num).toDouble(),
      imagePath: map['imagePath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Vehicle copyWith({
    int? id,
    String? name,
    double? currentKm,
    String? fuelType,
    double? tankCapacity,
    String? imagePath,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      currentKm: currentKm ?? this.currentKm,
      fuelType: fuelType ?? this.fuelType,
      tankCapacity: tankCapacity ?? this.tankCapacity,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
