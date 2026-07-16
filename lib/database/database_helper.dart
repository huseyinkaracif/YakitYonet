import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/vehicle.dart';
import '../models/fuel_record.dart';
import '../models/maintenance_record.dart';
import '../models/insurance_tax_record.dart';
import '../utils/fuel_math.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  static const int _exportVersion = 1;

  static const Map<String, List<String>> _importColumns = {
    'vehicles': [
      'id',
      'name',
      'currentKm',
      'initialKm',
      'fuelType',
      'tankCapacity',
      'imagePath',
      'createdAt',
    ],
    'fuel_records': [
      'id',
      'vehicleId',
      'date',
      'km',
      'liters',
      'pricePerLiter',
      'totalCost',
      'fullTank',
      'note',
    ],
    'maintenance_records': [
      'id',
      'vehicleId',
      'date',
      'km',
      'title',
      'description',
      'cost',
      'category',
      'note',
    ],
    'insurance_tax_records': [
      'id',
      'vehicleId',
      'date',
      'type',
      'provider',
      'cost',
      'expiryDate',
      'policyNumber',
      'note',
    ],
  };

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('yakit_yonet.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        currentKm REAL NOT NULL,
        initialKm REAL,
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

    await db.execute(
        'CREATE INDEX idx_fuel_records_vehicleId ON fuel_records(vehicleId)');
    await db.execute(
        'CREATE INDEX idx_maintenance_records_vehicleId ON maintenance_records(vehicleId)');
    await db.execute(
        'CREATE INDEX idx_insurance_tax_records_vehicleId ON insurance_tax_records(vehicleId)');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      switch (v) {
        // Gelecek şema sürümleri buraya eklenecek (case 2: ...)
        default:
          break;
      }
    }
  }

  // ==================== VEHICLE CRUD ====================

  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    final map = vehicle.toMap();
    map['initialKm'] = vehicle.currentKm;
    return await db.insert('vehicles', map);
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
    final vehicle = await getVehicle(id);

    final count = await db.transaction((txn) async {
      await txn
          .delete('fuel_records', where: 'vehicleId = ?', whereArgs: [id]);
      await txn.delete('maintenance_records',
          where: 'vehicleId = ?', whereArgs: [id]);
      await txn.delete('insurance_tax_records',
          where: 'vehicleId = ?', whereArgs: [id]);
      return await txn.delete('vehicles', where: 'id = ?', whereArgs: [id]);
    });

    final imagePath = vehicle?.imagePath;
    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        final file = File(imagePath);
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Görsel silinemese de araç silme işlemi başarılı sayılır
      }
    }

    return count;
  }

  // ==================== FUEL RECORD CRUD ====================

  Future<int> insertFuelRecord(FuelRecord record) async {
    final db = await database;
    return await db.transaction((txn) async {
      final id = await txn.insert('fuel_records', record.toMap());
      await txn.rawUpdate(
        'UPDATE vehicles SET currentKm = ? WHERE id = ? AND currentKm < ?',
        [record.km, record.vehicleId, record.km],
      );
      return id;
    });
  }

  Future<List<FuelRecord>> getFuelRecords(int vehicleId) async {
    final db = await database;
    final maps = await db.query('fuel_records',
        where: 'vehicleId = ?',
        whereArgs: [vehicleId],
        orderBy: 'date ASC, km ASC, id ASC');
    return maps.map((map) => FuelRecord.fromMap(map)).toList();
  }

  Future<int> updateFuelRecord(FuelRecord record) async {
    final db = await database;
    return await db.transaction((txn) async {
      final count = await txn.update('fuel_records', record.toMap(),
          where: 'id = ?', whereArgs: [record.id]);
      await _recalcCurrentKm(txn, record.vehicleId);
      return count;
    });
  }

  Future<int> deleteFuelRecord(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      final rows = await txn.query('fuel_records',
          columns: ['vehicleId'], where: 'id = ?', whereArgs: [id]);
      final count =
          await txn.delete('fuel_records', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        await _recalcCurrentKm(txn, rows.first['vehicleId'] as int);
      }
      return count;
    });
  }

  // ==================== MAINTENANCE RECORD CRUD ====================

  Future<int> insertMaintenanceRecord(MaintenanceRecord record) async {
    final db = await database;
    return await db.transaction((txn) async {
      final id = await txn.insert('maintenance_records', record.toMap());
      await txn.rawUpdate(
        'UPDATE vehicles SET currentKm = ? WHERE id = ? AND currentKm < ?',
        [record.km, record.vehicleId, record.km],
      );
      return id;
    });
  }

  Future<List<MaintenanceRecord>> getMaintenanceRecords(int vehicleId) async {
    final db = await database;
    final maps = await db.query('maintenance_records',
        where: 'vehicleId = ?', whereArgs: [vehicleId], orderBy: 'date DESC');
    return maps.map((map) => MaintenanceRecord.fromMap(map)).toList();
  }

  Future<int> updateMaintenanceRecord(MaintenanceRecord record) async {
    final db = await database;
    return await db.transaction((txn) async {
      final count = await txn.update('maintenance_records', record.toMap(),
          where: 'id = ?', whereArgs: [record.id]);
      await _recalcCurrentKm(txn, record.vehicleId);
      return count;
    });
  }

  Future<int> deleteMaintenanceRecord(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      final rows = await txn.query('maintenance_records',
          columns: ['vehicleId'], where: 'id = ?', whereArgs: [id]);
      final count = await txn.delete('maintenance_records',
          where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        await _recalcCurrentKm(txn, rows.first['vehicleId'] as int);
      }
      return count;
    });
  }

  /// currentKm'yi yakıt + bakım kayıtlarının MAX(km) değerinden yeniden
  /// hesaplar; kayıt yoksa araç oluşturulurken girilen initialKm'ye döner.
  Future<void> _recalcCurrentKm(DatabaseExecutor txn, int vehicleId) async {
    final vehicleRows = await txn.query('vehicles',
        columns: ['currentKm', 'initialKm'],
        where: 'id = ?',
        whereArgs: [vehicleId]);
    if (vehicleRows.isEmpty) return;

    final initialKm = (vehicleRows.first['initialKm'] as num?)?.toDouble() ??
        (vehicleRows.first['currentKm'] as num).toDouble();

    final result = await txn.rawQuery('''
      SELECT MAX(km) AS maxKm FROM (
        SELECT km FROM fuel_records WHERE vehicleId = ?
        UNION ALL
        SELECT km FROM maintenance_records WHERE vehicleId = ?
      )
    ''', [vehicleId, vehicleId]);
    final maxKm = (result.first['maxKm'] as num?)?.toDouble();

    final newKm = (maxKm != null && maxKm > initialKm) ? maxKm : initialKm;
    await txn.update('vehicles', {'currentKm': newKm},
        where: 'id = ?', whereArgs: [vehicleId]);
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
    final stats = computeFuelStats(records);
    return {
      'firstDate': stats.firstDate,
      'totalCost': stats.totalCost,
      'totalLiters': stats.totalLiters,
      'avgPrice': stats.avgPricePerLiter,
      'count': stats.recordCount,
      'costPerKm': stats.costPerKm,
      'litersPer100Km': stats.litersPer100km,
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
      'version': _exportVersion,
    };
  }

  Future<void> importAllData(Map<String, dynamic> data) async {
    final version = data['version'];
    if (version != _exportVersion) {
      throw FormatException(
          'Desteklenmeyen yedek dosyası sürümü ($version). '
          'Lütfen uygulamanın güncel sürümüyle alınmış bir yedek kullanın.');
    }
    for (final table in _importColumns.keys) {
      if (data[table] is! List) {
        throw FormatException('Geçersiz yedek dosyası: "$table" verisi eksik.');
      }
    }

    // İçe aktarma öncesi mevcut verinin güvenlik yedeği
    try {
      final current = await exportAllData();
      final dir = await getApplicationDocumentsDirectory();
      final timestamp =
          DateTime.now().toIso8601String().replaceAll(':', '-');
      final file =
          File(join(dir.path, 'yedek_oncesi_import_$timestamp.json'));
      await file.writeAsString(jsonEncode(current));
    } catch (_) {
      // Güvenlik yedeği alınamasa da içe aktarma devam eder
    }

    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('insurance_tax_records');
      await txn.delete('maintenance_records');
      await txn.delete('fuel_records');
      await txn.delete('vehicles');

      for (final entry in _importColumns.entries) {
        for (final row in (data[entry.key] as List)) {
          final map = Map<String, dynamic>.from(row as Map);
          map.removeWhere((key, _) => !entry.value.contains(key));
          await txn.insert(entry.key, map);
        }
      }
    });
  }

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'yakit_yonet.db');
  }

  Future<void> checkpointWal() async {
    final db = await database;
    await db.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
