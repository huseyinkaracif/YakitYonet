import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/fuel_record.dart';
import '../../theme/app_theme.dart';

class FuelTab extends StatefulWidget {
  final int vehicleId;
  final VoidCallback onDataChanged;

  const FuelTab({super.key, required this.vehicleId, required this.onDataChanged});

  @override
  State<FuelTab> createState() => _FuelTabState();
}

class _FuelTabState extends State<FuelTab> {
  List<FuelRecord> _records = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final records =
        await DatabaseHelper.instance.getFuelRecords(widget.vehicleId);
    final stats =
        await DatabaseHelper.instance.getVehicleFuelStats(widget.vehicleId);
    setState(() {
      _records = records;
      _stats = stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accentBlue));
    }

    return Container(
      color: AppTheme.primaryDark,
      child: Stack(
        children: [
          _records.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Stats Grid
                      _buildStatsGrid(),
                      const SizedBox(height: 16),
                      // Info note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: AppTheme.accentOrange, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Not: Tüketim hesaplamalarının doğruluğu amacıyla son akaryakıt alımı toplam maliyet ve miktara dahil edilmemiştir.',
                                style: TextStyle(
                                  color: AppTheme.accentOrange,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Chart 1: Price vs Quantity
                      _buildChartCard(
                        'Fiyat & Akaryakıt Miktarı',
                        _buildPriceQuantityChart(),
                      ),
                      const SizedBox(height: 16),
                      // Chart 2: Consumption
                      _buildChartCard(
                        'TL/KM & L/100KM Tüketim',
                        _buildConsumptionChart(),
                      ),
                      const SizedBox(height: 16),
                      // Records list
                      _buildRecordsList(),
                    ],
                  ),
                ),
          // FABs
          Positioned(
            bottom: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fiş Tara (pasif – kamera entegrasyonu ileriye)
                FloatingActionButton.extended(
                  heroTag: 'scan_fab',
                  backgroundColor: AppTheme.surfaceCard,
                  foregroundColor: AppTheme.accentCyan,
                  elevation: 4,
                  onPressed: _showScanComingSoon,
                  icon: const Icon(Icons.document_scanner_rounded),
                  label: const Text(
                    'Fiş Tara',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                // Yakıt Ekle
                FloatingActionButton.extended(
                  heroTag: 'fuel_fab',
                  onPressed: () => _showAddFuelDialog(),
                  backgroundColor: AppTheme.accentOrange,
                  icon: const Icon(Icons.add_rounded, color: AppTheme.primaryDark),
                  label: const Text('Yakıt Ekle'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_gas_station_rounded,
              size: 56, color: AppTheme.accentBlue.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('Henüz yakıt kaydı yok',
              style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('İlk yakıt alımınızı kaydedin',
              style: TextStyle(color: AppTheme.textHint, fontSize: 13)),
          const SizedBox(height: 24)
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final dateFormat = DateFormat('dd MMM yyyy', 'tr_TR');
    final firstDate = _stats['firstDate'] as DateTime?;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildStatTile('İlk Yakıt Tarihi',
            firstDate != null ? dateFormat.format(firstDate) : '-',
            Icons.calendar_today_rounded, AppTheme.accentBlue),
        _buildStatTile('Tüketim (TL/KM)',
            '${(_stats['costPerKm'] as num?)?.toStringAsFixed(2) ?? '0.00'} ₺',
            Icons.payments_rounded, AppTheme.accentOrange),
        _buildStatTile('Tüketim (L/100KM)',
            '${(_stats['litersPer100Km'] as num?)?.toStringAsFixed(1) ?? '0.0'} L',
            Icons.water_drop_rounded, AppTheme.accentCyan),
        _buildStatTile('Ort. Fiyat',
            '${(_stats['avgPrice'] as num?)?.toStringAsFixed(2) ?? '0.00'} ₺',
            Icons.trending_up_rounded, AppTheme.accentGreen),
        _buildStatTile('Alım Sayısı',
            '${_stats['count'] ?? 0}',
            Icons.receipt_long_rounded, AppTheme.accentPurple),
        _buildStatTile('Toplam Maliyet',
            '${(_stats['totalCost'] as num?)?.toStringAsFixed(0) ?? '0'} ₺',
            Icons.account_balance_wallet_rounded, AppTheme.accentRed),
        _buildStatTile('Toplam Miktar',
            '${(_stats['totalLiters'] as num?)?.toStringAsFixed(1) ?? '0.0'} L',
            Icons.local_gas_station_rounded, AppTheme.accentBlue),
      ],
    );
  }

  Widget _buildStatTile(
      String label, String value, IconData icon, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 42) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 10),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      decoration: AppTheme.glassDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildPriceQuantityChart() {
    if (_records.length < 2) {
      return const Center(
          child: Text('En az 2 kayıt gerekli',
              style: TextStyle(color: AppTheme.textHint)));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _records.map((r) => r.liters).reduce((a, b) => a > b ? a : b) *
            1.3,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final record = _records[group.x.toInt()];
              return BarTooltipItem(
                '${record.liters.toStringAsFixed(1)} L\n${record.pricePerLiter.toStringAsFixed(2)} ₺/L',
                const TextStyle(color: Colors.white, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= _records.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('dd/MM').format(_records[value.toInt()].date),
                    style: const TextStyle(
                        color: AppTheme.textHint, fontSize: 9),
                  ),
                );
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style:
                      const TextStyle(color: AppTheme.textHint, fontSize: 10),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval:
              (_records.map((r) => r.liters).reduce((a, b) => a > b ? a : b) /
                  4),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.dividerColor.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(_records.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: _records[index].liters,
                gradient: const LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [AppTheme.accentBlue, AppTheme.accentCyan],
                ),
                width: _records.length > 10 ? 10 : 18,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildConsumptionChart() {
    if (_records.length < 3) {
      return const Center(
          child: Text('En az 3 kayıt gerekli',
              style: TextStyle(color: AppTheme.textHint)));
    }

    // Calculate per-fill consumption
    final points = <FlSpot>[];
    for (int i = 1; i < _records.length; i++) {
      final kmDiff = _records[i].km - _records[i - 1].km;
      if (kmDiff > 0) {
        final lPer100 = (_records[i].liters / kmDiff) * 100;
        points.add(FlSpot(i.toDouble(), lPer100));
      }
    }

    if (points.isEmpty) {
      return const Center(
          child: Text('Yeterli veri yok',
              style: TextStyle(color: AppTheme.textHint)));
    }

    final maxY = points.map((p) => p.y).reduce((a, b) => a > b ? a : b) * 1.3;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppTheme.dividerColor.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx <= 0 || idx >= _records.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('dd/MM').format(_records[idx].date),
                    style: const TextStyle(
                        color: AppTheme.textHint, fontSize: 9),
                  ),
                );
              },
              reservedSize: 24,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style:
                      const TextStyle(color: AppTheme.textHint, fontSize: 10),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: points,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [AppTheme.accentOrange, AppTheme.accentRed],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.accentOrange,
                  strokeWidth: 2,
                  strokeColor: AppTheme.primaryDark,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.accentOrange.withValues(alpha: 0.3),
                  AppTheme.accentOrange.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} L/100km',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecordsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Son Kayıtlar',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
        ...List.generate(
          _records.length,
          (index) {
            final record = _records[_records.length - 1 - index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceOverlay,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_gas_station_rounded,
                        size: 18, color: AppTheme.accentBlue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(record.date),
                          style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${record.liters.toStringAsFixed(1)} L • ${record.pricePerLiter.toStringAsFixed(2)} ₺/L',
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${record.totalCost.toStringAsFixed(0)} ₺',
                        style: const TextStyle(
                            color: AppTheme.accentOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      Text(
                        '${record.km.toStringAsFixed(0)} km',
                        style: const TextStyle(
                            color: AppTheme.textHint, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _confirmDeleteRecord(record),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppTheme.textHint),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showScanComingSoon() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentCyan.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.document_scanner_rounded,
                  size: 48, color: AppTheme.accentCyan),
            ),
            const SizedBox(height: 20),
            const Text(
              'Fiş Tarama',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Kamera ile akaryakıt fişinizi tarayarak otomatik kayıt oluşturma özelliği yakında geliyor!\n\nŞimdilik "Yakıt Ekle" butonunu kullanabilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Anladım'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFuelDialog() {
    final dateController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
    final kmController = TextEditingController();
    final litersController = TextEditingController();
    final priceController = TextEditingController();
    final totalController = TextEditingController();
    bool fullTank = true;
    DateTime selectedDate = DateTime.now();

    // Auto-calc total when liters and price change
    void calcTotal() {
      final liters = double.tryParse(litersController.text);
      final price = double.tryParse(priceController.text);
      if (liters != null && price != null) {
        totalController.text = (liters * price).toStringAsFixed(2);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Yeni Yakıt Alımı',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                // Date
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.accentBlue,
                              surface: AppTheme.surfaceCard,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (date != null) {
                      selectedDate = date;
                      dateController.text =
                          DateFormat('dd/MM/yyyy').format(date);
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: dateController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Tarih',
                        prefixIcon: Icon(Icons.calendar_today_rounded,
                            color: AppTheme.textHint, size: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: kmController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Kilometre',
                    prefixIcon: Icon(Icons.speed_rounded,
                        color: AppTheme.textHint, size: 20),
                    suffixText: 'km',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: litersController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        onChanged: (_) => calcTotal(),
                        decoration: const InputDecoration(
                          labelText: 'Litre',
                          prefixIcon: Icon(Icons.water_drop_rounded,
                              color: AppTheme.textHint, size: 20),
                          suffixText: 'L',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        onChanged: (_) => calcTotal(),
                        decoration: const InputDecoration(
                          labelText: 'Birim Fiyat',
                          prefixIcon: Icon(Icons.monetization_on_rounded,
                              color: AppTheme.textHint, size: 20),
                          suffixText: '₺/L',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: totalController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Toplam Tutar',
                    prefixIcon: Icon(Icons.payments_rounded,
                        color: AppTheme.textHint, size: 20),
                    suffixText: '₺',
                  ),
                ),
                const SizedBox(height: 12),
                // Full tank switch
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceOverlay,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_gas_station_rounded,
                          color: AppTheme.textHint, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Depo doldu mu?',
                            style: TextStyle(color: AppTheme.textPrimary)),
                      ),
                      Switch(
                        value: fullTank,
                        onChanged: (val) =>
                            setModalState(() => fullTank = val),
                        activeColor: AppTheme.accentBlue,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final km = double.tryParse(kmController.text);
                    final liters = double.tryParse(litersController.text);
                    final price = double.tryParse(priceController.text);
                    final total = double.tryParse(totalController.text);

                    if (km == null ||
                        liters == null ||
                        price == null ||
                        total == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Lütfen tüm alanları doldurun')),
                      );
                      return;
                    }

                    final record = FuelRecord(
                      vehicleId: widget.vehicleId,
                      date: selectedDate,
                      km: km,
                      liters: liters,
                      pricePerLiter: price,
                      totalCost: total,
                      fullTank: fullTank,
                    );

                    await DatabaseHelper.instance.insertFuelRecord(record);
                    await _loadData();
                    widget.onDataChanged();
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Kaydet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteRecord(FuelRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kaydı Sil',
            style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Bu yakıt kaydını silmek istediğinize emin misiniz?',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
            onPressed: () async {
              await DatabaseHelper.instance.deleteFuelRecord(record.id!);
              await _loadData();
              widget.onDataChanged();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
