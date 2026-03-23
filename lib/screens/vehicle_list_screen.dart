import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import '../services/google_drive_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  List<Vehicle> _vehicles = [];
  Map<int, Map<String, dynamic>> _fuelStats = {};
  bool _loading = true;
  bool _isBannerView = true; // true = banner (eski), false = liste

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _loading = true);
    final vehicles = await DatabaseHelper.instance.getAllVehicles();
    final stats = <int, Map<String, dynamic>>{};
    for (var v in vehicles) {
      if (v.id != null) {
        stats[v.id!] =
            await DatabaseHelper.instance.getVehicleFuelStats(v.id!);
      }
    }
    setState(() {
      _vehicles = vehicles;
      _fuelStats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.accentGradient.createShader(bounds),
                      child: const Icon(Icons.local_gas_station_rounded,
                          size: 28, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Araçlarım',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    // View toggle button
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: IconButton(
                        key: ValueKey(_isBannerView),
                        tooltip: _isBannerView ? 'Liste görünümü' : 'Kart görünümü',
                        icon: Icon(
                          _isBannerView
                              ? Icons.view_list_rounded
                              : Icons.dashboard_rounded,
                          color: AppTheme.accentCyan,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() => _isBannerView = !_isBannerView);
                        },
                      ),
                    ),
                    // Menu button
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: AppTheme.textSecondary),
                      color: AppTheme.surfaceCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'stats':
                            Navigator.pushNamed(context, '/statistics');
                            break;
                          case 'export':
                            _exportData();
                            break;
                          case 'import':
                            _importData();
                            break;
                          case 'backup':
                            Navigator.pushNamed(context, '/backup');
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'stats',
                          child: Row(
                            children: [
                              Icon(Icons.bar_chart_rounded,
                                  color: AppTheme.accentBlue, size: 20),
                              SizedBox(width: 12),
                              Text('Genel İstatistikler',
                                  style:
                                      TextStyle(color: AppTheme.textPrimary)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.upload_rounded,
                                  color: AppTheme.accentGreen, size: 20),
                              SizedBox(width: 12),
                              Text('Dışa Aktar',
                                  style:
                                      TextStyle(color: AppTheme.textPrimary)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'import',
                          child: Row(
                            children: [
                              Icon(Icons.download_rounded,
                                  color: AppTheme.accentOrange, size: 20),
                              SizedBox(width: 12),
                              Text('İçe Aktar',
                                  style:
                                      TextStyle(color: AppTheme.textPrimary)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'backup',
                          child: Row(
                            children: [
                              Icon(Icons.cloud_rounded,
                                  color: AppTheme.accentPurple, size: 20),
                              SizedBox(width: 12),
                              Text('Yedekleme',
                                  style:
                                      TextStyle(color: AppTheme.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Add button
                    Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add_rounded,
                            color: AppTheme.primaryDark),
                        onPressed: () async {
                          await Navigator.pushNamed(context, '/add-vehicle');
                          _loadVehicles();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Greeting section
              StreamBuilder<GoogleSignInAccount?>(
                stream: GoogleDriveService.instance.onUserChanged,
                initialData: GoogleDriveService.instance.currentUser,
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  final name = user?.displayName ?? 'Misafir';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Merhaba, $name 👋',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user != null
                              ? 'Verileriniz bulut ile senkronize ediliyor.'
                              : 'Yedekleme için Google ile giriş yapın.',
                            style: const TextStyle(
                              color: AppTheme.textHint,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              ),
              const SizedBox(height: 12),
              // Vehicle List
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentBlue,
                        ),
                      )
                    : _vehicles.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadVehicles,
                            color: AppTheme.accentBlue,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              child: _isBannerView
                                  ? ListView.builder(
                                      key: const ValueKey('banner'),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      itemCount: _vehicles.length,
                                      itemBuilder: (context, index) {
                                        return _buildBannerCard(_vehicles[index]);
                                      },
                                    )
                                  : ListView.builder(
                                      key: const ValueKey('list'),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      itemCount: _vehicles.length,
                                      itemBuilder: (context, index) {
                                        return _buildListRow(_vehicles[index]);
                                      },
                                    ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accentBlue.withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.directions_car_rounded,
                size: 48, color: AppTheme.accentBlue),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz araç eklenmemiş',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sağ üstteki + butonuna tıklayarak\nilk aracınızı ekleyin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── BANNER CARD (eski zenginleştirilmiş görünüm) ──────────────────────────
  Widget _buildBannerCard(Vehicle vehicle) {
    final stats = _fuelStats[vehicle.id] ?? {};
    final costPerKm = (stats['costPerKm'] as num?)?.toDouble() ?? 0.0;
    final litersPer100 = (stats['litersPer100Km'] as num?)?.toDouble() ?? 0.0;
    final totalCost = (stats['totalCost'] as num?)?.toDouble() ?? 0.0;
    final count = (stats['count'] as int?) ?? 0;
    final fuelColor = AppTheme.getFuelTypeColor(vehicle.fuelType);

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/vehicle-detail',
            arguments: vehicle.id);
        _loadVehicles();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: AppTheme.cardDecoration,
        child: Column(
          children: [
            // Image / placeholder
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: vehicle.imagePath != null &&
                        File(vehicle.imagePath!).existsSync()
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(vehicle.imagePath!),
                            fit: BoxFit.cover,
                          ),
                          // gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.55),
                                ],
                              ),
                            ),
                          ),
                          // name overlay
                          Positioned(
                            bottom: 12,
                            left: 14,
                            child: Text(
                              vehicle.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 8, color: Colors.black54),
                                ],
                              ),
                            ),
                          ),
                          // fuel badge
                          Positioned(
                            bottom: 12,
                            right: 14,
                            child: _fuelBadge(vehicle.fuelType, fuelColor),
                          ),
                        ],
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              fuelColor.withValues(alpha: 0.18),
                              AppTheme.surfaceCard,
                            ],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Icon(
                                Icons.directions_car_rounded,
                                size: 72,
                                color: fuelColor.withValues(alpha: 0.35),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 14,
                              child: Text(
                                vehicle.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 14,
                              child: _fuelBadge(vehicle.fuelType, fuelColor),
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            // Stats grid
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                children: [
                  // Row 1
                  Row(
                    children: [
                      _statCard(
                        Icons.speed_rounded,
                        '${vehicle.currentKm.toStringAsFixed(0)} km',
                        'Son Kilometre',
                        AppTheme.accentBlue,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        Icons.payments_rounded,
                        costPerKm > 0
                            ? '${costPerKm.toStringAsFixed(2)} ₺'
                            : '—',
                        'TL / KM',
                        costPerKm > 0
                            ? AppTheme.accentOrange
                            : AppTheme.textHint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 2
                  Row(
                    children: [
                      _statCard(
                        Icons.water_drop_rounded,
                        litersPer100 > 0
                            ? '${litersPer100.toStringAsFixed(1)} L'
                            : '—',
                        'L / 100 km',
                        litersPer100 > 0
                            ? AppTheme.accentCyan
                            : AppTheme.textHint,
                      ),
                      const SizedBox(width: 10),
                      _statCard(
                        Icons.account_balance_wallet_rounded,
                        totalCost > 0
                            ? '${totalCost.toStringAsFixed(0)} ₺'
                            : '—',
                        'Toplam Harcama',
                        totalCost > 0
                            ? AppTheme.accentGreen
                            : AppTheme.textHint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 3: count + arrow
                  Row(
                    children: [
                      _statCard(
                        Icons.receipt_long_rounded,
                        '$count alım',
                        'Yakıt Alımı',
                        AppTheme.accentPurple,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.accentBlue.withValues(alpha: 0.15),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Detaylar',
                                style: TextStyle(
                                  color: AppTheme.accentBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded,
                                  color: AppTheme.accentBlue, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LIST ROW (kompakt sıralı görünüm) ────────────────────────────────────
  Widget _buildListRow(Vehicle vehicle) {
    final stats = _fuelStats[vehicle.id] ?? {};
    final costPerKm = (stats['costPerKm'] as num?)?.toDouble() ?? 0.0;
    final litersPer100 = (stats['litersPer100Km'] as num?)?.toDouble() ?? 0.0;
    final fuelColor = AppTheme.getFuelTypeColor(vehicle.fuelType);

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/vehicle-detail',
            arguments: vehicle.id);
        _loadVehicles();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.dividerColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: fuelColor.withValues(alpha: 0.12),
              ),
              child: vehicle.imagePath != null &&
                      File(vehicle.imagePath!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(vehicle.imagePath!),
                          fit: BoxFit.cover),
                    )
                  : Icon(Icons.directions_car_rounded,
                      color: fuelColor, size: 28),
            ),
            const SizedBox(width: 14),
            // Name + fuel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  _fuelBadge(vehicle.fuelType, fuelColor, fontSize: 11),
                ],
              ),
            ),
            // Stats column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(Icons.payments_rounded,
                        size: 13, color: AppTheme.accentOrange),
                    const SizedBox(width: 3),
                    Text(
                      costPerKm > 0
                          ? '${costPerKm.toStringAsFixed(2)} ₺/km'
                          : '—',
                      style: TextStyle(
                        color: costPerKm > 0
                            ? AppTheme.accentOrange
                            : AppTheme.textHint,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.water_drop_rounded,
                        size: 13, color: AppTheme.accentCyan),
                    const SizedBox(width: 3),
                    Text(
                      litersPer100 > 0
                          ? '${litersPer100.toStringAsFixed(1)} L/100'
                          : '—',
                      style: TextStyle(
                        color: litersPer100 > 0
                            ? AppTheme.accentCyan
                            : AppTheme.textHint,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.speed_rounded,
                        size: 13, color: AppTheme.accentBlue),
                    const SizedBox(width: 3),
                    Text(
                      '${vehicle.currentKm.toStringAsFixed(0)} km',
                      style: const TextStyle(
                        color: AppTheme.accentBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textHint, size: 20),
          ],
        ),
      ),
    );
  }

  // ── HELPERS ───────────────────────────────────────────────────────────────

  Widget _fuelBadge(String fuelType, Color color, {double fontSize = 12}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppTheme.getFuelTypeIcon(fuelType), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            fuelType,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exportData() async {
    try {
      final String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Dışa aktarılacak klasörü seçin',
      );

      if (selectedDirectory == null) {
        return; // Kullanıcı iptal etti
      }

      final data = await DatabaseHelper.instance.exportAllData();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('$selectedDirectory/yakit_yonet_yedek_$dateStr.json');
      
      await file.writeAsString(jsonEncode(data));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Veriler başarıyla dışa aktarıldı:\n${file.path}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  void _importData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'İçe aktarılacak yedek dosyasını seçin',
      );

      if (result == null || result.files.single.path == null) {
        return; // Kullanıcı iptal etti
      }

      final file = File(result.files.single.path!);
      final String jsonStr = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonStr);

      await DatabaseHelper.instance.importAllData(data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veriler başarıyla içe aktarıldı')),
        );
        _loadVehicles(); // Listeyi yenile
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: İçeri aktarma başarısız oldu. ($e)')),
        );
      }
    }
  }
}
