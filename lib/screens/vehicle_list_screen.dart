import 'dart:io';
import 'package:flutter/material.dart';
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
              const SizedBox(height: 16),
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
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              itemCount: _vehicles.length,
                              itemBuilder: (context, index) {
                                return _buildVehicleCard(_vehicles[index]);
                              },
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

  Widget _buildVehicleCard(Vehicle vehicle) {
    final stats = _fuelStats[vehicle.id] ?? {};
    final costPerKm = (stats['costPerKm'] as num?)?.toDouble() ?? 0.0;
    final fuelColor = AppTheme.getFuelTypeColor(vehicle.fuelType);

    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/vehicle-detail',
            arguments: vehicle.id);
        _loadVehicles();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: AppTheme.cardDecoration,
        child: Column(
          children: [
            // Vehicle image section
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: vehicle.imagePath != null &&
                        File(vehicle.imagePath!).existsSync()
                    ? Image.file(
                        File(vehicle.imagePath!),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              fuelColor.withValues(alpha: 0.2),
                              AppTheme.surfaceCard,
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.directions_car_rounded,
                          size: 64,
                          color: fuelColor.withValues(alpha: 0.5),
                        ),
                      ),
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: fuelColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        AppTheme.getFuelTypeIcon(
                                            vehicle.fuelType),
                                        size: 14,
                                        color: fuelColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        vehicle.fuelType,
                                        style: TextStyle(
                                          color: fuelColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppTheme.textHint),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.speed_rounded,
                        '${vehicle.currentKm.toStringAsFixed(0)} km',
                        AppTheme.accentBlue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatChip(
                        Icons.payments_rounded,
                        '${costPerKm.toStringAsFixed(2)} ₺/km',
                        costPerKm > 0
                            ? AppTheme.accentOrange
                            : AppTheme.textHint,
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

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _exportData() async {
    try {
      await DatabaseHelper.instance.exportAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veriler dışa aktarıldı')),
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

  void _importData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('İçe aktarma özelliği yakında gelecek')),
    );
  }
}
