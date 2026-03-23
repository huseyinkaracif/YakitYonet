import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/vehicle.dart';
import '../models/fuel_record.dart';
import '../models/maintenance_record.dart';
import '../models/insurance_tax_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('yakit_yonet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        currentKm REAL NOT NULL,
        fuelType TEXT NOT NULL,
        tankCapacity REAL NOT NULL,
        imagePath TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE fuel_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        date TEXT NOT NULL,
        km REAL NOT NULL,
        liters REAL NOT NULL,
        pricePerLiter REAL NOT NULL,
        totalCost REAL NOT NULL,
        fullTank INTEGER NOT NULL DEFAULT 1,
        note TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        date TEXT NOT NULL,
        km REAL NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        cost REAL NOT NULL,
        category TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE insurance_tax_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        provider TEXT,
        cost REAL NOT NULL,
        expiryDate TEXT,
        policyNumber TEXT,
        note TEXT,
        FOREIGN KEY (vehicleId) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');
  }

  // ==================== VEHICLE CRUD ====================

  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.insert('vehicles', vehicle.toMap());
  }

  Future<List<Vehicle>> getAllVehicles() async {
    final db = await database;
    final maps = await db.query('vehicles', orderBy: 'createdAt DESC');
    return maps.map((map) => Vehicle.fromMap(map)).toList();
  }

  Future<Vehicle?> getVehicle(int id) async {
    final db = await database;
    final maps = await db.query('vehicles', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Vehicle.fromMap(maps.first);
    return null;
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    return await db.update('vehicles', vehicle.toMap(),
        where: 'id = ?', whereArgs: [vehicle.id]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== FUEL RECORD CRUD ====================

  Future<int> insertFuelRecord(FuelRecord record) async {
    final db = await database;
    final id = await db.insert('fuel_records', record.toMap());
    // Update vehicle km
    await db.rawUpdate(
      'UPDATE vehicles SET currentKm = ? WHERE id = ? AND currentKm < ?',
      [record.km, record.vehicleId, record.km],
    );
    return id;
  }

  Future<List<FuelRecord>> getFuelRecords(int vehicleId) async {
    final db = await database;
    final maps = await db.query('fuel_records',
        where: 'vehicleId = ?', whereArgs: [vehicleId], orderBy: 'date ASC');
    return maps.map((map) => FuelRecord.fromMap(map)).toList();
  }

  Future<int> updateFuelRecord(FuelRecord record) async {
    final db = await database;
    return await db.update('fuel_records', record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
  }

  Future<int> deleteFuelRecord(int id) async {
    final db = await database;
    return await db.delete('fuel_records', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== MAINTENANCE RECORD CRUD ====================

  Future<int> insertMaintenanceRecord(MaintenanceRecord record) async {
    final db = await database;
    final id = await db.insert('maintenance_records', record.toMap());
    await db.rawUpdate(
      'UPDATE vehicles SET currentKm = ? WHERE id = ? AND currentKm < ?',
      [record.km, record.vehicleId, record.km],
    );
    return id;
  }

  Future<List<MaintenanceRecord>> getMaintenanceRecords(int vehicleId) async {
    final db = await database;
    final maps = await db.query('maintenance_records',
        where: 'vehicleId = ?', whereArgs: [vehicleId], orderBy: 'date DESC');
    return maps.map((map) => MaintenanceRecord.fromMap(map)).toList();
  }

  Future<int> updateMaintenanceRecord(MaintenanceRecord record) async {
    final db = await database;
    return await db.update('maintenance_records', record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
  }

  Future<int> deleteMaintenanceRecord(int id) async {
    final db = await database;
    return await db.delete('maintenance_records',
        where: 'id = ?', whereArgs: [id]);
  }

  // ==================== INSURANCE/TAX RECORD CRUD ====================

  Future<int> insertInsuranceTaxRecord(InsuranceTaxRecord record) async {
    final db = await database;
    return await db.insert('insurance_tax_records', record.toMap());
  }

  Future<List<InsuranceTaxRecord>> getInsuranceTaxRecords(
      int vehicleId) async {
    final db = await database;
    final maps = await db.query('insurance_tax_records',
        where: 'vehicleId = ?', whereArgs: [vehicleId], orderBy: 'date DESC');
    return maps.map((map) => InsuranceTaxRecord.fromMap(map)).toList();
  }

  Future<int> updateInsuranceTaxRecord(InsuranceTaxRecord record) async {
    final db = await database;
    return await db.update('insurance_tax_records', record.toMap(),
        where: 'id = ?', whereArgs: [record.id]);
  }

  Future<int> deleteInsuranceTaxRecord(int id) async {
    final db = await database;
    return await db.delete('insurance_tax_records',
        where: 'id = ?', whereArgs: [id]);
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getVehicleFuelStats(int vehicleId) async {
    final records = await getFuelRecords(vehicleId);
    if (records.isEmpty) {
      return {
        'firstDate': null,
        'totalCost': 0.0,
        'totalLiters': 0.0,
        'avgPrice': 0.0,
        'count': 0,
        'costPerKm': 0.0,
        'litersPer100Km': 0.0,
      };
    }

    // Son kaydı toplam maliyet ve miktara DAHİL ETME
    final recordsExcludingLast =
        records.length > 1 ? records.sublist(0, records.length - 1) : <FuelRecord>[];

    double totalCost = 0;
    double totalLiters = 0;
    double totalPriceSum = 0;

    for (var r in recordsExcludingLast) {
      totalCost += r.totalCost;
      totalLiters += r.liters;
      totalPriceSum += r.pricePerLiter;
    }

    double avgPrice = records.isNotEmpty
        ? records.map((r) => r.pricePerLiter).reduce((a, b) => a + b) /
            records.length
        : 0;

    // Consumption calculations
    double totalKmDriven = 0;
    double totalLitersConsumed = 0;
    for (int i = 1; i < records.length; i++) {
      totalKmDriven += records[i].km - records[i - 1].km;
      totalLitersConsumed += records[i].liters;
    }

    double costPerKm =
        totalKmDriven > 0 ? totalCost / totalKmDriven : 0;
    double litersPer100Km =
        totalKmDriven > 0 ? (totalLitersConsumed / totalKmDriven) * 100 : 0;

    return {
      'firstDate': records.first.date,
      'totalCost': totalCost,
      'totalLiters': totalLiters,
      'avgPrice': avgPrice,
      'count': records.length,
      'costPerKm': costPerKm,
      'litersPer100Km': litersPer100Km,
    };
  }

  Future<double> getTotalMaintenanceCost(int vehicleId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(cost) as total FROM maintenance_records WHERE vehicleId = ?',
      [vehicleId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<double> getTotalInsuranceTaxCost(int vehicleId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(cost) as total FROM insurance_tax_records WHERE vehicleId = ?',
      [vehicleId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // ==================== EXPORT / IMPORT ====================

  Future<Map<String, dynamic>> exportAllData() async {
    final db = await database;
    final vehicles = await db.query('vehicles');
    final fuelRecords = await db.query('fuel_records');
    final maintenanceRecords = await db.query('maintenance_records');
    final insuranceTaxRecords = await db.query('insurance_tax_records');

    return {
      'vehicles': vehicles,
      'fuel_records': fuelRecords,
      'maintenance_records': maintenanceRecords,
      'insurance_tax_records': insuranceTaxRecords,
      'exportDate': DateTime.now().toIso8601String(),
      'version': 1,
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete('insurance_tax_records');
      await txn.delete('maintenance_records');
      await txn.delete('fuel_records');
      await txn.delete('vehicles');

      // Import vehicles
      for (var v in (data['vehicles'] as List)) {
        await txn.insert('vehicles', Map<String, dynamic>.from(v));
      }
      for (var r in (data['fuel_records'] as List)) {
        await txn.insert('fuel_records', Map<String, dynamic>.from(r));
      }
      for (var r in (data['maintenance_records'] as List)) {
        await txn.insert('maintenance_records', Map<String, dynamic>.from(r));
      }
      for (var r in (data['insurance_tax_records'] as List)) {
        await txn.insert('insurance_tax_records', Map<String, dynamic>.from(r));
      }
    });
  }

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'yakit_yonet.db');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
