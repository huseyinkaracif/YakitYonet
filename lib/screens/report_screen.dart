import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  // ── state ──────────────────────────────────────────────────────────────────
  String _fmt = 'pdf'; // 'pdf' | 'excel'
  List<Vehicle> _vehicles = [];
  final Set<int> _sel = {};
  bool _loading = true;
  bool _inclFuel = true;
  bool _inclMaint = true;
  bool _inclIns = true;

  late AnimationController _fabAnim;

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadVehicles();
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    final v = await DatabaseHelper.instance.getAllVehicles();
    setState(() {
      _vehicles = v;
      _sel.addAll(v.where((x) => x.id != null).map((x) => x.id!));
      _loading = false;
    });
    _fabAnim.forward();
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _appBar(),
            Divider(
                height: 1,
                thickness: 1,
                color: Theme.of(context).dividerTheme.color ??
                    AppTheme.dividerColor),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.accent))
                  : SingleChildScrollView(
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 110),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionLabel(
                              Icons.description_rounded, 'Rapor Formatı'),
                          const SizedBox(height: 10),
                          _formatRow(isDark),
                          const SizedBox(height: 24),
                          _sectionLabel(
                              Icons.directions_car_rounded, 'Araç Seçimi'),
                          const SizedBox(height: 10),
                          _vehicleSection(isDark),
                          const SizedBox(height: 24),
                          _sectionLabel(
                              Icons.list_alt_rounded, 'Rapor İçeriği'),
                          const SizedBox(height: 10),
                          _contentSection(isDark),
                          const SizedBox(height: 8),
                          if (_sel.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.info_outline_rounded,
                                      size: 14,
                                      color: AppTheme.textHint),
                                  const SizedBox(width: 6),
                                  Text(
                                    'En az bir araç seçin',
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.4),
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _loading
          ? null
          : ScaleTransition(
              scale: CurvedAnimation(
                  parent: _fabAnim, curve: Curves.easeOutBack),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _sel.isEmpty
                          ? AppTheme.accent.withValues(alpha: 0.4)
                          : AppTheme.accent,
                      foregroundColor: Colors.white,
                      elevation: _sel.isEmpty ? 0 : 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _sel.isEmpty ? null : _generate,
                    icon: Icon(
                      _fmt == 'pdf'
                          ? Icons.picture_as_pdf_rounded
                          : Icons.table_chart_rounded,
                      size: 22,
                    ),
                    label: const Text(
                      'Rapor Oluştur',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded,
                color: Theme.of(context).iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Text(
            'Raporlama',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────

  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.accent),
        const SizedBox(width: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.accent,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ── Format row ─────────────────────────────────────────────────────────────

  Widget _formatRow(bool isDark) {
    return Row(
      children: [
        Expanded(
            child: _fmtCard(
          id: 'pdf',
          label: 'PDF',
          subtitle: 'Güzel görünümlü rapor',
          icon: Icons.picture_as_pdf_rounded,
          extension: '.pdf',
          color: const Color(0xFFDC2626),
          isDark: isDark,
        )),
        const SizedBox(width: 12),
        Expanded(
            child: _fmtCard(
          id: 'excel',
          label: 'Excel',
          subtitle: 'Düzenlenebilir tablo',
          icon: Icons.table_chart_rounded,
          extension: '.xlsx',
          color: const Color(0xFF15803D),
          isDark: isDark,
        )),
      ],
    );
  }

  Widget _fmtCard({
    required String id,
    required String label,
    required String subtitle,
    required IconData icon,
    required String extension,
    required Color color,
    required bool isDark,
  }) {
    final sel = _fmt == id;
    return GestureDetector(
      onTap: () => setState(() => _fmt = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
          color: sel
              ? color.withValues(alpha: isDark ? 0.15 : 0.07)
              : AppTheme.surfaceFor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? color : AppTheme.borderFor(context),
            width: sel ? 2 : 1,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: sel
                    ? color.withValues(alpha: 0.15)
                    : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: sel
                    ? color
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.45),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              extension,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    color.withValues(alpha: sel ? 0.8 : 0.4),
              ),
            ),
            if (sel) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Seçildi ✓',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Vehicle section ────────────────────────────────────────────────────────

  Widget _vehicleSection(bool isDark) {
    final allSel = _sel.length == _vehicles.length && _vehicles.isNotEmpty;
    final someSel =
        _sel.isNotEmpty && _sel.length < _vehicles.length;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        children: [
          // All vehicles row
          InkWell(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () {
              setState(() {
                if (allSel) {
                  _sel.clear();
                } else {
                  _sel.addAll(_vehicles
                      .where((v) => v.id != null)
                      .map((v) => v.id!));
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:
                          AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_car_filled_rounded,
                        color: AppTheme.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tüm Araçlar',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${_vehicles.length} araç',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Checkbox(
                    value: allSel ? true : (someSel ? null : false),
                    tristate: true,
                    onChanged: (_) {
                      setState(() {
                        if (allSel) {
                          _sel.clear();
                        } else {
                          _sel.addAll(_vehicles
                              .where((v) => v.id != null)
                              .map((v) => v.id!));
                        }
                      });
                    },
                    activeColor: AppTheme.accent,
                  ),
                ],
              ),
            ),
          ),
          // Individual vehicles
          ..._vehicles.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;
            final isLast = i == _vehicles.length - 1;
            return Column(
              children: [
                Divider(
                    height: 1,
                    color: AppTheme.borderFor(context)),
                _vehicleRow(v, isLast),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _vehicleRow(Vehicle vehicle, bool isLast) {
    final selected =
        vehicle.id != null && _sel.contains(vehicle.id);
    final fuelColor =
        AppTheme.getFuelTypeColor(vehicle.fuelType);
    return InkWell(
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(14))
          : BorderRadius.zero,
      onTap: () {
        if (vehicle.id == null) return;
        setState(() {
          if (selected) {
            _sel.remove(vehicle.id);
          } else {
            _sel.add(vehicle.id!);
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: fuelColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: fuelColor.withValues(alpha: 0.2)),
              ),
              child: Icon(
                  AppTheme.getFuelTypeIcon(vehicle.fuelType),
                  color: fuelColor,
                  size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name,
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${vehicle.fuelType}  ·  ${vehicle.currentKm.toStringAsFixed(0)} km',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: selected,
              onChanged: (_) {
                if (vehicle.id == null) return;
                setState(() {
                  if (selected) {
                    _sel.remove(vehicle.id);
                  } else {
                    _sel.add(vehicle.id!);
                  }
                });
              },
              activeColor: AppTheme.accent,
            ),
          ],
        ),
      ),
    );
  }

  // ── Content toggles ────────────────────────────────────────────────────────

  Widget _contentSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderFor(context)),
      ),
      child: Column(
        children: [
          _toggle('Yakıt Kayıtları', 'Tarih, km, litre, fiyat',
              Icons.local_gas_station_rounded, AppTheme.fuelColor,
              _inclFuel, (v) => setState(() => _inclFuel = v),
              isFirst: true),
          Divider(height: 1, color: AppTheme.borderFor(context)),
          _toggle('Bakım Kayıtları', 'Başlık, kategori, maliyet',
              Icons.build_rounded, AppTheme.maintColor,
              _inclMaint, (v) => setState(() => _inclMaint = v)),
          Divider(height: 1, color: AppTheme.borderFor(context)),
          _toggle('Sigorta / Vergi', 'Tür, kurum, poliçe, maliyet',
              Icons.shield_rounded, AppTheme.insurColor,
              _inclIns, (v) => setState(() => _inclIns = v),
              isLast: true),
        ],
      ),
    );
  }

  Widget _toggle(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(14) : Radius.zero,
        bottom: isLast ? const Radius.circular(14) : Radius.zero,
      ),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                          fontSize: 12)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  // ── Generate ───────────────────────────────────────────────────────────────

  Future<void> _generate() async {
    if (_sel.isEmpty) return;
    _showProgress();
    try {
      final selected =
          _vehicles.where((v) => v.id != null && _sel.contains(v.id)).toList();
      final data = await ReportService.loadData(selected);

      String filePath;
      if (_fmt == 'pdf') {
        final f = await ReportService.generatePdf(data,
            includeFuel: _inclFuel,
            includeMaint: _inclMaint,
            includeIns: _inclIns);
        filePath = f.path;
      } else {
        final f = await ReportService.generateExcel(data,
            includeFuel: _inclFuel,
            includeMaint: _inclMaint,
            includeIns: _inclIns);
        filePath = f.path;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // close progress
      _showSuccess(filePath);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close progress
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Rapor oluşturulamadı: $e'),
        backgroundColor: AppTheme.dangerColor,
      ));
    }
  }

  void _showProgress() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppTheme.surfaceFor(context),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated progress ring
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        color: AppTheme.accent,
                        strokeWidth: 4,
                      ),
                    ),
                    Icon(
                      _fmt == 'pdf'
                          ? Icons.picture_as_pdf_rounded
                          : Icons.table_chart_rounded,
                      color: AppTheme.accent,
                      size: 28,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Rapor Hazırlanıyor…',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Veriler işleniyor, lütfen bekleyin.',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccess(String filePath) {
    final isPdf = filePath.endsWith('.pdf');
    final fileName = filePath.split('/').last;
    final fileColor = isPdf
        ? const Color(0xFFDC2626)
        : const Color(0xFF15803D);
    final fileIcon = isPdf
        ? Icons.picture_as_pdf_rounded
        : Icons.table_chart_rounded;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.surfaceFor(ctx),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.successColor, size: 44),
              ),
              const SizedBox(height: 16),
              Text(
                'Rapor Hazır!',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${isPdf ? 'PDF' : 'Excel'} dosyanız başarıyla oluşturuldu.',
                style: TextStyle(
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.55),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // File name chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: fileColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: fileColor.withValues(alpha: 0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(fileIcon, color: fileColor, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        fileName,
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Kapat'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text(
                        'Paylaş / İndir',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await Share.shareXFiles(
                          [XFile(filePath)],
                          subject: 'Yakıt Yönet Raporu',
                          text:
                              'Yakıt Yönet – ${isPdf ? 'PDF' : 'Excel'} raporu ekte.',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
