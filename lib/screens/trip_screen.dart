import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';
import 'map_picker_screen.dart';

// ── Haversine helper ──────────────────────────────────────────────────────────
double _haversineKm(LatLng a, LatLng b) {
  const r = 6371.0;
  final dLat = (b.latitude - a.latitude) * pi / 180;
  final dLng = (b.longitude - a.longitude) * pi / 180;
  final sinA = sin(dLat / 2) * sin(dLat / 2) +
      cos(a.latitude * pi / 180) *
          cos(b.latitude * pi / 180) *
          sin(dLng / 2) *
          sin(dLng / 2);
  return r * 2 * atan2(sqrt(sinA), sqrt(1 - sinA));
}

// ── Public entry widget ───────────────────────────────────────────────────────
class TripScreen extends StatefulWidget {
  /// Optionally pre-filled destination (from an incoming share/deep-link).
  final double? initialLat;
  final double? initialLng;

  const TripScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> with TickerProviderStateMixin {
  // ── Data ──────────────────────────────────────────────────────────────────
  List<Vehicle> _vehicles = [];
  Vehicle? _selected;
  String _search = '';
  final _searchCtrl = TextEditingController();

  LatLng? _destination;
  double? _distanceKm;
  double? _fuelCost;
  double? _fuelLiters;
  int? _refuels;
  bool _computing = false;

  // ── Animations ────────────────────────────────────────────────────────────
  late final AnimationController _card1Ctrl;
  late final AnimationController _card2Ctrl;
  late final AnimationController _card3Ctrl;
  late final Animation<Offset> _slide1;
  late final Animation<Offset> _slide2;
  late final Animation<Offset> _slide3;

  @override
  void initState() {
    super.initState();

    _card1Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _card2Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _card3Ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _slide1 = Tween<Offset>(begin: const Offset(0.4, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _card1Ctrl, curve: Curves.easeOutCubic));
    _slide2 = Tween<Offset>(begin: const Offset(0.4, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _card2Ctrl, curve: Curves.easeOutCubic));
    _slide3 = Tween<Offset>(begin: const Offset(0.4, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _card3Ctrl, curve: Curves.easeOutCubic));

    if (widget.initialLat != null && widget.initialLng != null) {
      _destination = LatLng(widget.initialLat!, widget.initialLng!);
    }

    _loadVehicles();
  }

  @override
  void dispose() {
    _card1Ctrl.dispose();
    _card2Ctrl.dispose();
    _card3Ctrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final v = await DatabaseHelper.instance.getAllVehicles();
    if (mounted) setState(() => _vehicles = v);
  }

  // ── Location helpers ──────────────────────────────────────────────────────
  Future<LatLng?> _getUserLocation() async {
    try {
      bool svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return null;
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapPickerScreen(initialLocation: _destination),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _destination = result.latLng;
        _distanceKm = null;
        _fuelCost = null;
        _fuelLiters = null;
        _refuels = null;
      });
      _card1Ctrl.reset();
      _card2Ctrl.reset();
      _card3Ctrl.reset();
      if (_selected != null) _compute();
    }
  }

  Future<void> _compute() async {
    if (_selected == null || _destination == null) return;
    setState(() => _computing = true);

    final origin = await _getUserLocation();
    if (origin == null || !mounted) {
      setState(() => _computing = false);
      _showSnack('Konum alınamadı. Konum iznini kontrol edin.');
      return;
    }

    final distKm = _haversineKm(origin, _destination!);

    final stats =
        await DatabaseHelper.instance.getVehicleFuelStats(_selected!.id!);
    final l100 = (stats['litersPer100Km'] as num).toDouble();
    final costPerKm = (stats['costPerKm'] as num).toDouble();
    final avgPrice = (stats['avgPrice'] as num).toDouble();

    // Fallback defaults per fuel type when no records exist
    final defaultL100 = _selected!.fuelType == 'Dizel'
        ? 6.5
        : _selected!.fuelType == 'LPG'
            ? 10.0
            : _selected!.fuelType == 'Elektrik'
                ? 0.0
                : 8.0;
    final defaultPrice =
        _selected!.fuelType == 'Elektrik' ? 2.5 : 45.0;

    final usedL100 = l100 > 0 ? l100 : defaultL100;
    final usedPrice = avgPrice > 0 ? avgPrice : defaultPrice;

    final liters = distKm * usedL100 / 100;
    final cost = costPerKm > 0
        ? distKm * costPerKm
        : liters * usedPrice;
    final tank = _selected!.tankCapacity > 0 ? _selected!.tankCapacity : 50.0;
    final refuels = (liters / tank).ceil();

    if (!mounted) return;
    setState(() {
      _distanceKm = distKm;
      _fuelLiters = liters;
      _fuelCost = cost;
      _refuels = refuels;
      _computing = false;
    });

    // Staggered card animations
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _card1Ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _card2Ctrl.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _card3Ctrl.forward();
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        isDark ? const Color(0xFF1C1917) : const Color(0xFFF5F5F4);
    final surface =
        isDark ? const Color(0xFF292524) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  const SizedBox(height: 16),
                  _buildVehicleSection(isDark, surface),
                  const SizedBox(height: 16),
                  if (_selected != null) ...[
                    _buildLocationSection(isDark, surface),
                    const SizedBox(height: 16),
                  ],
                  if (_computing) _buildLoading(),
                  if (_distanceKm != null && !_computing) ...[
                    _buildDistanceBadge(isDark),
                    const SizedBox(height: 20),
                    _buildQACard(
                      ctrl: _card1Ctrl,
                      slide: _slide1,
                      icon: Icons.attach_money_rounded,
                      iconColor: const Color(0xFF16A34A),
                      question: 'Ne kadara giderim?',
                      answer: '₺ ${_fuelCost!.toStringAsFixed(2)}',
                      subtitle:
                          '${_distanceKm!.toStringAsFixed(1)} km × ₺${(_fuelCost! / _distanceKm!).toStringAsFixed(2)}/km',
                      surface: surface,
                    ),
                    const SizedBox(height: 12),
                    _buildQACard(
                      ctrl: _card2Ctrl,
                      slide: _slide2,
                      icon: Icons.local_gas_station_rounded,
                      iconColor: const Color(0xFFD97706),
                      question: 'Ne kadar yakıt yakarım?',
                      answer: _selected!.fuelType == 'Elektrik'
                          ? '—'
                          : '${_fuelLiters!.toStringAsFixed(2)} Litre',
                      subtitle: _selected!.fuelType == 'Elektrik'
                          ? 'Elektrikli araç'
                          : '${(_fuelLiters! / _distanceKm! * 100).toStringAsFixed(1)} L/100km',
                      surface: surface,
                    ),
                    const SizedBox(height: 12),
                    _buildQACard(
                      ctrl: _card3Ctrl,
                      slide: _slide3,
                      icon: Icons.replay_rounded,
                      iconColor: const Color(0xFF7C3AED),
                      question: 'Kaç kere alım yapmam gerek?',
                      answer: _selected!.fuelType == 'Elektrik'
                          ? '—'
                          : '$_refuels şarj / dolu depo',
                      subtitle: _selected!.fuelType == 'Elektrik'
                          ? 'Şarj noktası planlayın'
                          : 'Depo: ${_selected!.tankCapacity.toStringAsFixed(0)} L',
                      surface: surface,
                    ),
                    const SizedBox(height: 8),
                    _buildDataNote(isDark),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.route_rounded,
                color: AppTheme.accent, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seyahat Hesaplayıcı',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Araç seç → Nokta belirle → Tahmin gör',
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor:
                  isDark ? const Color(0xFF3C3836) : const Color(0xFFE7E5E4),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  // ── Vehicle section ───────────────────────────────────────────────────────
  Widget _buildVehicleSection(bool isDark, Color surface) {
    final filtered = _vehicles
        .where((v) =>
            v.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Araç Seç', Icons.directions_car_rounded),
        const SizedBox(height: 10),
        // Search field
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF44403C)
                  : const Color(0xFFE7E5E4),
            ),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Araç adı ara...',
              hintStyle: TextStyle(color: AppTheme.textHint),
              prefixIcon: Icon(Icons.search_rounded,
                  color: AppTheme.textHint, size: 20),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Carousel
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Araç bulunamadı',
                style: TextStyle(color: AppTheme.textHint, fontSize: 13),
              ),
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) =>
                  _vehicleCard(filtered[i], isDark, surface),
            ),
          ),
      ],
    );
  }

  Widget _vehicleCard(Vehicle v, bool isDark, Color surface) {
    final isSelected = _selected?.id == v.id;
    final fuelColor = AppTheme.getFuelTypeColor(v.fuelType);
    return GestureDetector(
      onTap: () {
        setState(() {
          _selected = v;
          _distanceKm = null;
          _fuelCost = null;
          _fuelLiters = null;
          _refuels = null;
        });
        _card1Ctrl.reset();
        _card2Ctrl.reset();
        _card3Ctrl.reset();
        if (_destination != null) _compute();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 90,
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: isDark ? 0.22 : 0.12)
              : surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.accent
                : isDark
                    ? const Color(0xFF44403C)
                    : const Color(0xFFE7E5E4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Vehicle image or icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: fuelColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: v.imagePath != null && File(v.imagePath!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(v.imagePath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(Icons.directions_car_filled_rounded,
                      color: fuelColor, size: 26),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                v.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppTheme.accent
                      : Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Location section ──────────────────────────────────────────────────────
  Widget _buildLocationSection(bool isDark, Color surface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Varış Noktası', Icons.location_on_rounded),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _openMapPicker,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _destination != null
                    ? AppTheme.accent
                    : isDark
                        ? const Color(0xFF44403C)
                        : const Color(0xFFE7E5E4),
                width: _destination != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _destination != null
                        ? AppTheme.accent.withValues(alpha: 0.15)
                        : isDark
                            ? const Color(0xFF3C3836)
                            : const Color(0xFFF5F5F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _destination != null
                        ? Icons.location_on_rounded
                        : Icons.add_location_alt_rounded,
                    color: _destination != null
                        ? AppTheme.accent
                        : AppTheme.textHint,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _destination == null
                            ? 'Haritadan nokta seç'
                            : 'Nokta seçildi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _destination == null
                            ? 'Haritaya dokunarak varış noktanızı belirleyin'
                            : '${_destination!.latitude.toStringAsFixed(4)}, ${_destination!.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textHint,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Distance badge ────────────────────────────────────────────────────────
  Widget _buildDistanceBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded,
              color: AppTheme.accent, size: 18),
          const SizedBox(width: 10),
          Text(
            'Tahmini mesafe: ${_distanceKm!.toStringAsFixed(1)} km (kuş uçuşu)',
            style: const TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ── Q&A animated card ─────────────────────────────────────────────────────
  Widget _buildQACard({
    required AnimationController ctrl,
    required Animation<Offset> slide,
    required IconData icon,
    required Color iconColor,
    required String question,
    required String answer,
    required String subtitle,
    required Color surface,
  }) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => FadeTransition(
        opacity: ctrl,
        child: SlideTransition(
          position: slide,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: iconColor.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question,
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        answer,
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Loading spinner ───────────────────────────────────────────────────────
  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2.5),
          SizedBox(height: 14),
          Text(
            'Konum alınıyor, hesaplanıyor…',
            style: TextStyle(color: AppTheme.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Data note ─────────────────────────────────────────────────────────────
  Widget _buildDataNote(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        '* Kuş uçuşu mesafe tahminidir. Gerçek yol daha uzun olabilir.',
        style: TextStyle(
          color: AppTheme.textHint.withValues(alpha: 0.7),
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.textHint),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.textHint,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
