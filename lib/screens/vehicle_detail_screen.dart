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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
      );
    }

    if (_vehicle == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppTheme.textHint),
              const SizedBox(height: 16),
              const Text('Araç bulunamadı',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  )),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // App Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
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
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppTheme.dangerColor, size: 22),
                            onPressed: () => _confirmDelete(vehicle),
                          ),
                        ],
                      ),
                    ),

                    // Vehicle summary card
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppTheme.borderSubtle, width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x081C1917),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Vehicle image
                          if (vehicle.imagePath != null &&
                              File(vehicle.imagePath!).existsSync())
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(13)),
                              child: SizedBox(
                                height: 140,
                                width: double.infinity,
                                child: Image.file(
                                  File(vehicle.imagePath!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                          // Info chips
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                _infoChip(
                                  label: 'Son KM',
                                  value:
                                      '${vehicle.currentKm.toStringAsFixed(0)}',
                                  icon: Icons.speed_rounded,
                                  color: AppTheme.accent,
                                ),
                                const SizedBox(width: 10),
                                _infoChip(
                                  label: 'Yakıt',
                                  value: vehicle.fuelType,
                                  icon: AppTheme.getFuelTypeIcon(
                                      vehicle.fuelType),
                                  color: fuelColor,
                                ),
                                const SizedBox(width: 10),
                                _infoChip(
                                  label: 'Depo',
                                  value:
                                      '${vehicle.tankCapacity.toStringAsFixed(0)} ${vehicle.fuelType == 'Elektrik' ? 'kWh' : 'L'}',
                                  icon: Icons.local_gas_station_rounded,
                                  color: AppTheme.successColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.borderSubtle, width: 1),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: TabBar(
                        controller: _tabController,
                        labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle:
                            const TextStyle(fontSize: 13),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: AppTheme.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: AppTheme.textSecondary,
                        tabs: const [
                          Tab(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.local_gas_station_rounded,
                                    size: 15),
                                SizedBox(width: 5),
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
                                Icon(Icons.build_rounded, size: 15),
                                SizedBox(width: 5),
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
                                Icon(Icons.shield_rounded, size: 15),
                                SizedBox(width: 5),
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
              FuelTab(
                  vehicleId: widget.vehicleId,
                  onDataChanged: _loadVehicle),
              MaintenanceTab(
                  vehicleId: widget.vehicleId,
                  onDataChanged: _loadVehicle),
              InsuranceTaxTab(
                  vehicleId: widget.vehicleId,
                  onDataChanged: _loadVehicle),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
        title: const Text('Aracı Sil'),
        content: Text(
          '${vehicle.name} aracını ve tüm verilerini silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
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
