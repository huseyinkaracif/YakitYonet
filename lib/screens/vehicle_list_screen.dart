import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../models/insurance_tax_record.dart';
import '../theme/app_theme.dart';
import '../services/google_drive_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'trip_screen.dart';
import 'vehicle_detail_screen.dart';
import '../services/location_sharing_service.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/background_watermark.dart';
import '../services/fuel_price_service.dart';
import '../services/widget_service.dart';

class VehicleListScreen extends StatefulWidget {
  final Uri? initialWidgetUri;
  const VehicleListScreen({super.key, this.initialWidgetUri});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  bool _handledWidgetUri = false;
  List<Vehicle> _vehicles = [];
  List<_UpcomingPayment> _upcomingPayments = [];
  Map<int, Map<String, dynamic>> _fuelStats = {};
  bool _loading = true;
  bool _isBannerView = true;
  FuelPrices? _fuelPrices;
  int? _defaultVehicleId;
  // ignore: cancel_subscriptions
  late final dynamic _widgetClickSub;
  late final AppLifecycleListener _lifecycleListener;

  int get _panelOffset => _upcomingPayments.isEmpty ? 0 : 1;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
    _initLocationSharing();
    _loadFuelPrices();
    // Widget tapped while app is already running
    _widgetClickSub = WidgetService.widgetClickedStream.listen((uri) {
      if (WidgetService.isAddFuelUri(uri)) {
        _navigateToDefaultVehicleAddFuel();
      }
    });
    // Re-push data to widgets whenever the app comes back to foreground
    _lifecycleListener = AppLifecycleListener(
      onResume: _loadVehicles,
    );
  }

  @override
  void dispose() {
    _widgetClickSub?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() => _loading = true);
    final vehicles = await DatabaseHelper.instance.getAllVehicles();
    final stats = <int, Map<String, dynamic>>{};
    for (var v in vehicles) {
      if (v.id != null) {
        stats[v.id!] = await DatabaseHelper.instance.getVehicleFuelStats(v.id!);
      }
    }

    final upcoming = await _loadUpcomingPayments(vehicles);

    int? defaultId = await WidgetService.getDefaultVehicleId();

    if (vehicles.isNotEmpty) {
      Vehicle defaultVehicle;
      if (defaultId != null) {
        final found = vehicles.where((v) => v.id == defaultId).toList();
        if (found.isNotEmpty) {
          defaultVehicle = found.first;
        } else {
          // Default vehicle was deleted — auto-select first and persist it
          defaultVehicle = vehicles.first;
          defaultId = vehicles.first.id;
          await WidgetService.setDefaultVehicleId(defaultId);
        }
      } else {
        // No explicit default → first vehicle is auto-default, persist it
        defaultVehicle = vehicles.first;
        defaultId = vehicles.first.id;
        await WidgetService.setDefaultVehicleId(defaultId);
      }
      final defaultStats = stats[defaultVehicle.id] ?? {};
      await WidgetService.updateWidgetData(
        defaultVehicle,
        costPerKm: (defaultStats['costPerKm'] as num?)?.toDouble() ?? 0.0,
        litersPer100: (defaultStats['litersPer100Km'] as num?)?.toDouble() ?? 0.0,
      );
    } else {
      await WidgetService.updateWidgetData(null);
    }

    setState(() {
      _vehicles = vehicles;
      _upcomingPayments = upcoming;
      _fuelStats = stats;
      _defaultVehicleId = defaultId;
      _loading = false;
    });

    _handleWidgetIntent();
  }

  /// Tüm araçlarda 30 gün içinde bitecek veya süresi geçmiş
  /// sigorta/vergi kayıtlarını toplar.
  Future<List<_UpcomingPayment>> _loadUpcomingPayments(
      List<Vehicle> vehicles) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = <_UpcomingPayment>[];
    for (var v in vehicles) {
      if (v.id == null) continue;
      final records =
          await DatabaseHelper.instance.getInsuranceTaxRecords(v.id!);
      for (var r in records) {
        final expiry = r.expiryDate;
        if (expiry == null) continue;
        final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
        final daysLeft = expiryDay.difference(today).inDays;
        if (daysLeft <= 30) {
          upcoming.add(
              _UpcomingPayment(vehicle: v, record: r, daysLeft: daysLeft));
        }
      }
    }
    upcoming.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
    return upcoming;
  }

  void _handleWidgetIntent() {
    if (!_handledWidgetUri &&
        WidgetService.isAddFuelUri(widget.initialWidgetUri) &&
        _vehicles.isNotEmpty) {
      _handledWidgetUri = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToDefaultVehicleAddFuel();
      });
    }
  }

  void _navigateToDefaultVehicleAddFuel() {
    if (_vehicles.isEmpty) return;
    final targetVehicle = _defaultVehicleId != null
        ? _vehicles.firstWhere((v) => v.id == _defaultVehicleId,
            orElse: () => _vehicles.first)
        : _vehicles.first;
    Navigator.pushNamed(
      context,
      '/vehicle-detail',
      arguments: {'vehicleId': targetVehicle.id!, 'openAddFuel': true},
    ).then((_) => _loadVehicles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: _TripFab(onOpen: () => _openTripScreen(context)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: BackgroundWatermark(
        child: SafeArea(
          child: Column(
          children: [
            _buildAppBar(),
            _buildGreeting(),
            _buildFuelPriceBar(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    )
                  : _vehicles.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadVehicles,
                          color: AppTheme.accent,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _isBannerView
                                ? ListView.builder(
                                    key: const ValueKey('banner'),
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                    itemCount: _vehicles.length + _panelOffset,
                                    itemBuilder: (context, index) {
                                      if (_panelOffset > 0 && index == 0) {
                                        return _buildUpcomingPaymentsCard();
                                      }
                                      return _buildBannerCard(
                                          _vehicles[index - _panelOffset]);
                                    },
                                  )
                                : ListView.builder(
                                    key: const ValueKey('list'),
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                                    itemCount: _vehicles.length + _panelOffset,
                                    itemBuilder: (context, index) {
                                      if (_panelOffset > 0 && index == 0) {
                                        return _buildUpcomingPaymentsCard();
                                      }
                                      return _buildListRow(
                                          _vehicles[index - _panelOffset]);
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

  void _openTripScreen(BuildContext context, [LatLng? prefilled]) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => TripScreen(
        initialLat: prefilled?.latitude,
        initialLng: prefilled?.longitude,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutQuint);
        return ScaleTransition(
          scale: curved,
          alignment: Alignment.bottomRight,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  Future<void> _initLocationSharing() async {
    // Check if app was launched by tapping a geo: link or maps share
    final initial = await LocationSharingService.getInitialSharedLocation();
    if (initial != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _openTripScreen(context, initial));
    }
    // Listen for future shares while app is open
    LocationSharingService.listenForSharedLocations((loc) {
      if (mounted) _openTripScreen(context, loc);
    });
  }

  // ── App Bar ────────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          // Logo mark
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.local_gas_station_rounded,
                size: 20, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Araçlarım',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          // View toggle
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              key: ValueKey(_isBannerView),
              tooltip: _isBannerView ? 'Liste görünümü' : 'Kart görünümü',
              icon: Icon(
                _isBannerView ? Icons.view_list_rounded : Icons.dashboard_rounded,
                color: Theme.of(context).iconTheme.color ?? AppTheme.textSecondary,
                size: 22,
              ),
              onPressed: () => setState(() => _isBannerView = !_isBannerView),
            ),
          ),
          // Theme toggle
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeNotifier,
            builder: (context, currentMode, _) {
              final isDark = currentMode == ThemeMode.dark ||
                  (currentMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness == Brightness.dark);
              return IconButton(
                tooltip: isDark ? 'Açık Tema' : 'Koyu Tema',
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: Theme.of(context).iconTheme.color ?? AppTheme.textSecondary,
                  size: 22,
                ),
                onPressed: () async {
                  final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
                  themeNotifier.value = newMode;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('theme_mode', newMode == ThemeMode.light ? 'light' : 'dark');
                },
              );
            },
          ),
          // Menu
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded,
                color: Theme.of(context).iconTheme.color ?? AppTheme.textSecondary, size: 22),
            onSelected: (value) {
              switch (value) {
                case 'stats':
                  Navigator.pushNamed(context, '/statistics');
                  break;
                case 'report':
                  Navigator.pushNamed(context, '/report');
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
              _menuItem('stats', 'Genel İstatistikler',
                  Icons.bar_chart_rounded, AppTheme.accent),
              _menuItem('report', 'Raporlama',
                  Icons.description_rounded, const Color(0xFF0891B2)),
              _menuItem('export', 'Dışa Aktar',
                  Icons.upload_rounded, AppTheme.successColor),
              _menuItem('import', 'İçe Aktar',
                  Icons.download_rounded, AppTheme.maintColor),
              _menuItem('backup', 'Yedekleme',
                  Icons.cloud_rounded, AppTheme.insurColor),
            ],
          ),
          // Add button
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, '/add-vehicle');
              _loadVehicles();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(
      String value, String label, IconData icon, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _loadFuelPrices() async {
    final prices = await FuelPriceService.instance.getPrices();
    if (!mounted) return;
    setState(() => _fuelPrices = prices);
  }

  // ── Fuel Price Bar ─────────────────────────────────────────────────────────

  Widget _buildFuelPriceBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FuelPriceChip(
              label: 'Benzin',
              icon: Icons.local_gas_station_rounded,
              price: _fuelPrices?.benzin,
              color: AppTheme.fuelColor,
              updatedAt: _fuelPrices?.updatedAt,
            ),
            const SizedBox(width: 8),
            _FuelPriceChip(
              label: 'Dizel',
              icon: Icons.local_gas_station_rounded,
              price: _fuelPrices?.dizel,
              color: AppTheme.maintColor,
              updatedAt: _fuelPrices?.updatedAt,
            ),
            const SizedBox(width: 8),
            _FuelPriceChip(
              label: 'LPG',
              icon: Icons.propane_tank_rounded,
              price: _fuelPrices?.lpg,
              color: AppTheme.successColor,
              updatedAt: _fuelPrices?.updatedAt,
            ),
            const SizedBox(width: 8),
            _FuelPriceChip(
              label: 'Elektrik',
              icon: Icons.bolt_rounded,
              price: _fuelPrices?.elektrik,
              color: const Color(0xFF0891B2),
              updatedAt: _fuelPrices?.updatedAt,
            ),
          ],
        ),
      ),
    );
  }

  // ── Greeting ───────────────────────────────────────────────────────────────

  Widget _buildGreeting() {
    return StreamBuilder<GoogleSignInAccount?>(
      stream: GoogleDriveService.instance.onUserChanged,
      initialData: GoogleDriveService.instance.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Merhaba, ${user?.displayName ?? 'Misafir'}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user != null
                          ? 'Verileriniz bulut ile senkronize.'
                          : 'Yedekleme için Google ile giriş yapın.',
                      style: const TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (user != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Senkronize',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.directions_car_rounded,
                  size: 40, color: AppTheme.accent),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz araç eklenmemiş',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sağ üstteki + butonuna tıklayarak\nilk aracınızı ekleyin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Yaklaşan Ödemeler ──────────────────────────────────────────────────────

  Widget _buildUpcomingPaymentsCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderFor(context), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    size: 16, color: AppTheme.insurColor),
                const SizedBox(width: 8),
                Text(
                  'Yaklaşan Ödemeler',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ..._upcomingPayments.map(_buildUpcomingPaymentRow),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildUpcomingPaymentRow(_UpcomingPayment payment) {
    final urgent = payment.daysLeft <= 7;
    final color = urgent ? AppTheme.dangerColor : AppTheme.insurColor;
    final String countdown;
    if (payment.daysLeft < 0) {
      countdown = '${-payment.daysLeft} gün gecikti';
    } else if (payment.daysLeft == 0) {
      countdown = 'Bugün son gün';
    } else {
      countdown = '${payment.daysLeft} gün kaldı';
    }
    final expiry = payment.record.expiryDate!;

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VehicleDetailScreen(
              vehicleId: payment.vehicle.id!,
              initialTab: 2,
            ),
          ),
        );
        _loadVehicles();
      },
      child: Container(
        color: urgent
            ? AppTheme.dangerColor.withValues(alpha: 0.06)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(Icons.shield_rounded, size: 14, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.vehicle.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    payment.record.type,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryFor(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(expiry),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  countdown,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Banner Card ────────────────────────────────────────────────────────────

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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).cardTheme.shape is RoundedRectangleBorder ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).side.color : AppTheme.borderSubtle, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x081C1917),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Vehicle image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              child: SizedBox(
                height: 156,
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
                          // Bottom gradient for text legibility
                          Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Color(0xCC000000),
                                ],
                                stops: [0.4, 1.0],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 14,
                            child: Row(
                              children: [
                                Text(
                                  vehicle.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (vehicle.id == _defaultVehicleId) ...
                                  const [
                                    SizedBox(width: 6),
                                    Icon(Icons.star_rounded,
                                        size: 16, color: Color(0xFFFF9800)),
                                  ],
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 14,
                            child: _fuelBadgeLight(vehicle.fuelType, fuelColor),
                          ),
                        ],
                      )
                    : Container(
                        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF292524) : AppTheme.surfaceAlt,
                        child: Stack(
                          children: [
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.directions_car_rounded,
                                    size: 44,
                                    color: fuelColor.withValues(alpha: 0.25),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _showAddPhotoDialog(vehicle),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardTheme.color,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Theme.of(context).dividerTheme.color ?? AppTheme.borderSubtle),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.add_a_photo_rounded,
                                              size: 14,
                                              color: AppTheme.textSecondary),
                                          SizedBox(width: 5),
                                          Text(
                                            'Fotoğraf Ekle',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              left: 14,
                              child: Row(
                                children: [
                                  Text(
                                    vehicle.name,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (vehicle.id == _defaultVehicleId) ...
                                    const [
                                      SizedBox(width: 6),
                                      Icon(Icons.star_rounded,
                                          size: 16, color: Color(0xFFFF9800)),
                                    ],
                                ],
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  // Row 1
                  Row(
                    children: [
                      _statCell(
                        '${vehicle.currentKm.toStringAsFixed(0)} km',
                        'Son Kilometre',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      _vDivider(),
                      _statCell(
                        costPerKm > 0
                            ? '${costPerKm.toStringAsFixed(2)} ₺'
                            : '—',
                        'TL / KM',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).dividerTheme.color ?? AppTheme.dividerColor),
                  const SizedBox(height: 10),
                  // Row 2
                  Row(
                    children: [
                      _statCell(
                        litersPer100 > 0
                            ? '${litersPer100.toStringAsFixed(1)} L'
                            : '—',
                        'L / 100 km',
                        color: litersPer100 > 0
                            ? Theme.of(context).colorScheme.onSurface
                            : AppTheme.textHint,
                      ),
                      _vDivider(context),
                      _statCell(
                        totalCost > 0
                            ? '${totalCost.toStringAsFixed(0)} ₺'
                            : '—',
                        'Toplam Harcama',
                        color: totalCost > 0
                            ? Theme.of(context).colorScheme.onSurface
                            : AppTheme.textHint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(
                      height: 1,
                      thickness: 1,
                      color: Theme.of(context).dividerTheme.color ?? AppTheme.dividerColor),
                  const SizedBox(height: 10),
                  // Row 3
                  Row(
                    children: [
                      _statCell(
                        '$count alım',
                        'Yakıt Alımı',
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      _vDivider(),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Detayları Gör',
                              style: TextStyle(
                                color: AppTheme.accent,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppTheme.accent, size: 18),
                          ],
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

  // ── List Row ───────────────────────────────────────────────────────────────

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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppTheme.borderSubtle, width: 1),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: fuelColor.withValues(alpha: 0.08),
                border: Border.all(
                    color: fuelColor.withValues(alpha: 0.15), width: 1),
              ),
              child: vehicle.imagePath != null &&
                      File(vehicle.imagePath!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.file(File(vehicle.imagePath!),
                          fit: BoxFit.cover),
                    )
                  : Icon(Icons.directions_car_rounded,
                      color: fuelColor, size: 26),
            ),
            const SizedBox(width: 14),
            // Name + fuel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          vehicle.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (vehicle.id == _defaultVehicleId) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded,
                            size: 13, color: Color(0xFFFF9800)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  _fuelBadge(vehicle.fuelType, fuelColor, fontSize: 11),
                ],
              ),
            ),
            // Stats
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  costPerKm > 0 ? '${costPerKm.toStringAsFixed(2)} ₺/km' : '—',
                  style: TextStyle(
                    color: costPerKm > 0 ? AppTheme.accent : AppTheme.textHint,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  litersPer100 > 0
                      ? '${litersPer100.toStringAsFixed(1)} L/100'
                      : '—',
                  style: TextStyle(
                    color: litersPer100 > 0
                        ? AppTheme.textSecondary
                        : AppTheme.textHint,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${vehicle.currentKm.toStringAsFixed(0)} km',
                  style: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textHint, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _fuelBadge(String fuelType, Color color, {double fontSize = 12}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppTheme.getFuelTypeIcon(fuelType), size: 11, color: color),
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

  /// Badge variant for photo overlay (dark bg → always white text)
  Widget _fuelBadgeLight(String fuelType, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppTheme.getFuelTypeIcon(fuelType), size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            fuelType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell(String value, String label, {required Color color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textHint,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider([BuildContext? ctx]) {
    final c = ctx ?? context;
    return Container(
      width: 1,
      height: 32,
      color: Theme.of(c).dividerTheme.color ?? AppTheme.dividerColor,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  // ── Photo picker ───────────────────────────────────────────────────────────

  void _showAddPhotoDialog(Vehicle vehicle) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Fotoğraf Ekle',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _photoOption(
                icon: Icons.camera_alt_rounded,
                title: 'Kamera',
                subtitle: 'Fotoğraf çek',
                color: AppTheme.accent,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSaveImageForVehicle(vehicle, ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              _photoOption(
                icon: Icons.photo_library_rounded,
                title: 'Galeri',
                subtitle: 'Galeriden seç',
                color: AppTheme.maintColor,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSaveImageForVehicle(vehicle, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    )),
                Text(subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSaveImageForVehicle(
      Vehicle vehicle, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile =
          await picker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (pickedFile != null) {
        final image = File(pickedFile.path);
        final dir = await getApplicationDocumentsDirectory();
        final vehicleImagesDir = Directory('${dir.path}/vehicle_images');
        if (!await vehicleImagesDir.exists()) {
          await vehicleImagesDir.create(recursive: true);
        }
        final fileName =
            'vehicle_${DateTime.now().millisecondsSinceEpoch}${p.extension(image.path)}';
        final savedImage =
            await image.copy('${vehicleImagesDir.path}/$fileName');
        final oldImagePath = vehicle.imagePath;
        final updatedVehicle = vehicle.copyWith(imagePath: savedImage.path);
        await DatabaseHelper.instance.updateVehicle(updatedVehicle);
        if (oldImagePath != null && oldImagePath != savedImage.path) {
          final oldFile = File(oldImagePath);
          if (await oldFile.exists()) {
            try {
              await oldFile.delete();
            } catch (_) {}
          }
        }
        await _loadVehicles();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fotoğraf başarıyla eklendi')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: Fotoğraf eklenemedi ($e)')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    try {
      final data = await DatabaseHelper.instance.exportAllData();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Yedek dosyasını kaydet',
        fileName: 'yakit_yonet_yedek_$dateStr.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(utf8.encode(jsonEncode(data))),
      );
      if (savedPath == null) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veriler başarıyla dışa aktarıldı')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _importData() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'İçe aktarılacak yedek dosyasını seçin',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
      return;
    }
    if (result == null || result.files.single.path == null) return;

    Map<String, dynamic> data;
    try {
      final jsonStr = await File(result.files.single.path!).readAsString();
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Geçersiz yedek biçimi');
      }
      data = decoded;
    } catch (_) {
      if (mounted) _showImportErrorDialog();
      return;
    }

    final vehicleCount = (data['vehicles'] as List?)?.length ?? 0;
    final fuelCount = (data['fuel_records'] as List?)?.length ?? 0;
    final maintCount = (data['maintenance_records'] as List?)?.length ?? 0;
    final insurCount = (data['insurance_tax_records'] as List?)?.length ?? 0;
    String exportDateText = 'Bilinmiyor';
    final exportDateRaw = data['exportDate'];
    if (exportDateRaw is String) {
      final parsed = DateTime.tryParse(exportDateRaw);
      if (parsed != null) {
        exportDateText = DateFormat('dd MMM yyyy HH:mm').format(parsed);
      }
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yedeği Geri Yükle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Yedek tarihi: $exportDateText'),
            const SizedBox(height: 8),
            Text('Araç: $vehicleCount\n'
                'Yakıt kaydı: $fuelCount\n'
                'Bakım kaydı: $maintCount\n'
                'Sigorta/Vergi kaydı: $insurCount'),
            const SizedBox(height: 12),
            const Text(
              'Mevcut TÜM veriler silinip yerine bu yedek yüklenecek. '
              'Devam edilsin mi?',
              style: TextStyle(
                color: AppTheme.dangerColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('İçe Aktar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await DatabaseHelper.instance.importAllData(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veriler başarıyla içe aktarıldı')),
        );
        _loadVehicles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Hata: İçeri aktarma başarısız oldu. ($e)')),
        );
      }
    }
  }

  void _showImportErrorDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dosya Okunamadı'),
        content: const Text(
          'Seçilen dosya geçerli bir yedek dosyası değil. '
          'Lütfen "Dışa Aktar" ile oluşturulmuş bir JSON dosyası seçin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}

class _UpcomingPayment {
  final Vehicle vehicle;
  final InsuranceTaxRecord record;
  final int daysLeft;

  const _UpcomingPayment({
    required this.vehicle,
    required this.record,
    required this.daysLeft,
  });
}

// ── Animated Trip FAB ────────────────────────────────────────────────────────
class _TripFab extends StatefulWidget {
  final VoidCallback onOpen;
  const _TripFab({required this.onOpen});

  @override
  State<_TripFab> createState() => _TripFabState();
}

class _TripFabState extends State<_TripFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onOpen();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.route_rounded, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                'Seyahat Hesaplayıcı',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FuelPriceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final double? price;
  final Color color;
  final DateTime? updatedAt;

  const _FuelPriceChip({
    required this.label,
    required this.icon,
    required this.price,
    required this.color,
    required this.updatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF3C3836) : AppTheme.surfaceAlt;
    final border = isDark ? const Color(0xFF44403C) : AppTheme.borderSubtle;
    final priceText = price != null ? '${price!.toStringAsFixed(2)} ₺' : '--';

    return GestureDetector(
      onTap: () {
        final timeStr = updatedAt != null
            ? DateFormat('HH:mm').format(updatedAt!.toLocal())
            : '--:--';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fiyatlar Ankara bazlıdır\nGüncelleme Zamanı: $timeStr', textAlign: TextAlign.center),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark
                        ? const Color(0xFFA8A29E)
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  priceText,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

