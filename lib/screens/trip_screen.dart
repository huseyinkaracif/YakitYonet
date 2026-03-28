import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';

class TripScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const TripScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen>
    with SingleTickerProviderStateMixin {
  List<Vehicle> _vehicles = [];
  int _selectedIndex = 0;
  final _pageCtrl = PageController(viewportFraction: 0.72);

  final _kmCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _consumCtrl = TextEditingController();

  late final AnimationController _resultsAnim;
  late final Animation<double> _resultsFade;
  late final Animation<Offset> _resultsSlide;

  @override
  void initState() {
    super.initState();
    _resultsAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _resultsFade =
        CurvedAnimation(parent: _resultsAnim, curve: Curves.easeOut);
    _resultsSlide = Tween<Offset>(
            begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _resultsAnim, curve: Curves.easeOutCubic));

    _kmCtrl.addListener(_onInputChange);
    _priceCtrl.addListener(_onInputChange);
    _consumCtrl.addListener(_onInputChange);
    _loadVehicles();
  }

  @override
  void dispose() {
    _resultsAnim.dispose();
    _pageCtrl.dispose();
    _kmCtrl.dispose();
    _priceCtrl.dispose();
    _consumCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final v = await DatabaseHelper.instance.getAllVehicles();
    if (!mounted) return;
    setState(() => _vehicles = v);
    if (v.isNotEmpty) _loadStatsForVehicle(v[0]);
  }

  Future<void> _loadStatsForVehicle(Vehicle v) async {
    if (v.id == null) return;
    final stats = await DatabaseHelper.instance.getVehicleFuelStats(v.id!);
    final l100 = (stats['litersPer100Km'] as num).toDouble();
    final avgPrice = (stats['avgPrice'] as num).toDouble();
    final defaultL100 = _defaultConsumption(v.fuelType);
    final defaultPrice = _defaultPrice(v.fuelType);
    if (!mounted) return;
    setState(() {
      _consumCtrl.text =
          (l100 > 0 ? l100 : defaultL100).toStringAsFixed(1);
      _priceCtrl.text =
          (avgPrice > 0 ? avgPrice : defaultPrice).toStringAsFixed(2);
    });
  }

  double _defaultConsumption(String fuelType) {
    switch (fuelType) {
      case 'Dizel': return 6.5;
      case 'LPG': return 10.0;
      case 'Elektrik': return 0.0;
      default: return 8.0;
    }
  }

  double _defaultPrice(String fuelType) {
    switch (fuelType) {
      case 'LPG': return 18.0;
      case 'Elektrik': return 3.5;
      default: return 45.0;
    }
  }

  void _onInputChange() {
    final km = double.tryParse(_kmCtrl.text.replaceAll(',', '.'));
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
    final consum = double.tryParse(_consumCtrl.text.replaceAll(',', '.'));
    final ready = km != null && km > 0 && price != null && price > 0 && consum != null;
    
    // Anlık değerlerin güncellenmesi için setState çağırıyoruz
    setState(() {});

    if (ready) {
      _resultsAnim.forward();
    } else {
      _resultsAnim.reverse();
    }
  }

  double? get _km => double.tryParse(_kmCtrl.text.replaceAll(',', '.'));
  double? get _price => double.tryParse(_priceCtrl.text.replaceAll(',', '.'));
  double? get _consum => double.tryParse(_consumCtrl.text.replaceAll(',', '.'));

  double get _liters {
    final km = _km ?? 0;
    final c = _consum ?? 0;
    return km * c / 100;
  }

  double get _totalCost => _liters * (_price ?? 0);

  double get _costPerKm {
    final km = _km ?? 0;
    return km > 0 ? _totalCost / km : 0;
  }

  int get _refuels {
    final vehicle = _vehicles.isNotEmpty ? _vehicles[_selectedIndex] : null;
    final tank = vehicle?.tankCapacity ?? 50.0;
    if (tank <= 0 || _liters <= 0) return 0;
    return (_liters / tank).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1917) : const Color(0xFFF5F5F4);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
                children: [
                  _buildVehicleCarousel(isDark),
                  const SizedBox(height: 20),
                  if (_vehicles.isNotEmpty) ...[
                    _buildInputSection(isDark),
                    const SizedBox(height: 20),
                    _buildResults(isDark),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calculate_rounded, color: AppTheme.accent, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Seyahat Hesaplayici',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3)),
                Text('Arac sec. Km gir. Aninda hesapla.',
                    style: TextStyle(color: AppTheme.textHint, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF3C3836) : const Color(0xFFE7E5E4),
              iconSize: 20,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCarousel(bool isDark) {
    if (_vehicles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text('Henuz arac eklenmemis.', style: TextStyle(color: AppTheme.textHint))),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: _vehicles.length,
            onPageChanged: (i) {
              setState(() => _selectedIndex = i);
              _resultsAnim.reset();
              _kmCtrl.clear();
              _loadStatsForVehicle(_vehicles[i]);
            },
            itemBuilder: (_, i) => _vehicleCard(_vehicles[i], i == _selectedIndex, isDark),
          ),
        ),
        const SizedBox(height: 10),
        if (_vehicles.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _vehicles.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _selectedIndex ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _selectedIndex
                      ? AppTheme.accent
                      : AppTheme.textHint.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _vehicleCard(Vehicle v, bool isSelected, bool isDark) {
    final fuelColor = AppTheme.getFuelTypeColor(v.fuelType);
    final surface = isDark ? const Color(0xFF292524) : Colors.white;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: isSelected ? 0 : 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.accent.withValues(alpha: isDark ? 0.18 : 0.08)
            : surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.accent : isDark ? const Color(0xFF44403C) : const Color(0xFFE7E5E4),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: fuelColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: v.imagePath != null && File(v.imagePath!).existsSync()
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(File(v.imagePath!), fit: BoxFit.cover))
                : Icon(Icons.directions_car_filled_rounded, color: fuelColor, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  v.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isSelected ? AppTheme.accent : Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _chip(v.fuelType, fuelColor),
                    const SizedBox(width: 6),
                    _chip('${v.tankCapacity.toStringAsFixed(0)}L', AppTheme.textHint),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInputSection(bool isDark) {
    final surface = isDark ? const Color(0xFF292524) : Colors.white;
    final border = isDark ? const Color(0xFF44403C) : const Color(0xFFE7E5E4);
    final isElectric = _vehicles[_selectedIndex].fuelType == 'Elektrik';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seyahat Bilgileri',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textHint)),
            const SizedBox(height: 14),
            _inputField(
              controller: _kmCtrl,
              label: 'Mesafe',
              suffix: 'km',
              icon: Icons.route_rounded,
              iconColor: AppTheme.accent,
              hint: '0',
            ),
            const SizedBox(height: 12),
            _inputField(
              controller: _priceCtrl,
              label: isElectric ? 'Sarj Fiyati' : 'Yakit Fiyati',
              suffix: isElectric ? 'TL/kWh' : 'TL/L',
              icon: isElectric ? Icons.bolt_rounded : Icons.local_gas_station_rounded,
              iconColor: const Color(0xFFD97706),
              hint: '0.00',
            ),
            const SizedBox(height: 12),
            _inputField(
              controller: _consumCtrl,
              label: 'Tuketim',
              suffix: isElectric ? 'kWh/100' : 'L/100km',
              icon: Icons.speed_rounded,
              iconColor: const Color(0xFF7C3AED),
              hint: '0.0',
              helperText: 'Gecmis veriden',
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
    required Color iconColor,
    required String hint,
    String? helperText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFA8A29E) : AppTheme.textSecondary)),
            if (helperText != null) ...[
              const SizedBox(width: 6),
              Expanded(
                child: Text('- $helperText',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textHint),
            suffixText: suffix,
            suffixStyle: TextStyle(color: iconColor, fontSize: 13, fontWeight: FontWeight.w600),
            filled: true,
            fillColor: isDark ? const Color(0xFF3C3836) : const Color(0xFFF5F5F4),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: iconColor, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildResults(bool isDark) {
    final isElectric = _vehicles[_selectedIndex].fuelType == 'Elektrik';
    return FadeTransition(
      opacity: _resultsFade,
      child: SlideTransition(
        position: _resultsSlide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _resultCard(
                icon: Icons.attach_money_rounded,
                color: const Color(0xFF16A34A),
                question: 'Toplam Maliyet',
                answer: 'TL ${_totalCost.toStringAsFixed(2)}',
                detail: '${(_km ?? 0).toStringAsFixed(0)} km x TL ${_costPerKm.toStringAsFixed(3)}/km',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _resultCard(
                icon: isElectric ? Icons.bolt_rounded : Icons.local_gas_station_rounded,
                color: const Color(0xFFD97706),
                question: isElectric ? 'Enerji Tuketimi' : 'Yakit Tuketimi',
                answer: isElectric ? '${_liters.toStringAsFixed(2)} kWh' : '${_liters.toStringAsFixed(2)} Litre',
                detail: '${(_consum ?? 0).toStringAsFixed(1)} ${isElectric ? "kWh" : "L"}/100km',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _resultCard(
                icon: isElectric ? Icons.ev_station_rounded : Icons.replay_rounded,
                color: const Color(0xFF7C3AED),
                question: isElectric ? 'Sarj Durumu' : 'Depo Sayisi',
                answer: isElectric ? '--' : _refuels == 0 ? '< 1 depo' : '$_refuels dolu depo',
                detail: isElectric ? 'Sarj noktasi planlayın' : 'Depo kap.: ${(_vehicles[_selectedIndex].tankCapacity).toStringAsFixed(0)} L',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultCard({
    required IconData icon,
    required Color color,
    required String question,
    required String answer,
    required String detail,
    required bool isDark,
  }) {
    final surface = isDark ? const Color(0xFF292524) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.07), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question,
                    style: const TextStyle(color: AppTheme.textHint, fontSize: 12, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(answer,
                    style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                Text(detail, style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
