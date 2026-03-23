import 'dart:io';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import 'tabs/fuel_tab.dart';
import 'tabs/maintenance_tab.dart';
import 'tabs/insurance_tax_tab.dart';

class VehicleDetailScreen extends StatefulWidget {
  final int vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Vehicle? _vehicle;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    setState(() => _loading = true);
    final vehicle = await DatabaseHelper.instance.getVehicle(widget.vehicleId);
    setState(() {
      _vehicle = vehicle;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.accentBlue)),
      );
    }

    if (_vehicle == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Araç bulunamadı',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }

    final vehicle = _vehicle!;
    final fuelColor = AppTheme.getFuelTypeColor(vehicle.fuelType);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: SafeArea(
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // App bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: AppTheme.textPrimary),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                vehicle.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppTheme.accentRed),
                              onPressed: () => _confirmDelete(vehicle),
                            ),
                          ],
                        ),
                      ),

                      // Vehicle summary card
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          children: [
                            // Vehicle image
                            if (vehicle.imagePath != null &&
                                File(vehicle.imagePath!).existsSync())
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                child: SizedBox(
                                  height: 140,
                                  width: double.infinity,
                                  child: Image.file(
                                    File(vehicle.imagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                            // KM Info
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  _buildKmCard(
                                    'Son KM',
                                    '${vehicle.currentKm.toStringAsFixed(0)}',
                                    Icons.speed_rounded,
                                    AppTheme.accentBlue,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildKmCard(
                                    'Yakıt Türü',
                                    vehicle.fuelType,
                                    AppTheme.getFuelTypeIcon(vehicle.fuelType),
                                    fuelColor,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildKmCard(
                                    'Depo',
                                    '${vehicle.tankCapacity.toStringAsFixed(0)} ${vehicle.fuelType == 'Elektrik' ? 'kWh' : 'L'}',
                                    Icons.local_gas_station_rounded,
                                    AppTheme.accentGreen,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tab bar
                      Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          unselectedLabelStyle: const TextStyle(fontSize: 13),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            gradient: AppTheme.accentGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelColor: AppTheme.primaryDark,
                          unselectedLabelColor: AppTheme.textSecondary,
                          tabs: const [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_gas_station_rounded,
                                      size: 16),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text('Akaryakıt',
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.build_rounded, size: 16),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text('Bakım',
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.security_rounded, size: 16),
                                  SizedBox(width: 4),
                                  Flexible(
                                    child: Text('Sigorta',
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                FuelTab(vehicleId: widget.vehicleId, onDataChanged: _loadVehicle),
                MaintenanceTab(vehicleId: widget.vehicleId, onDataChanged: _loadVehicle),
                InsuranceTaxTab(vehicleId: widget.vehicleId, onDataChanged: _loadVehicle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKmCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Aracı Sil',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: Text(
          '${vehicle.name} aracını ve tüm verilerini silmek istediğinize emin misiniz?',
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
            ),
            onPressed: () async {
              await DatabaseHelper.instance.deleteVehicle(vehicle.id!);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context, true);
              }
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
