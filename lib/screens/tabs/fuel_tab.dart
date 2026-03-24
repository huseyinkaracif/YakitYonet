import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../database/database_helper.dart';
import '../../models/fuel_record.dart';
import '../../theme/app_theme.dart';
import '../../services/ocr_service.dart';

class FuelTab extends StatefulWidget {
  final int vehicleId;
  final VoidCallback onDataChanged;

  const FuelTab(
      {super.key, required this.vehicleId, required this.onDataChanged});

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
          child: CircularProgressIndicator(color: AppTheme.accent));
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          _records.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStatsGrid(),
                      const SizedBox(height: 12),
                      // Info note
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppTheme.accentDark, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Not: Son akaryakıt alımı tüketim hesaplamalarına dahil edilmemiştir.',
                                style: TextStyle(
                                  color: AppTheme.accentDark,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildChartCard(
                          'Yakıt Miktarı', _buildPriceQuantityChart()),
                      const SizedBox(height: 12),
                      _buildChartCard(
                          'Tüketim (L/100km)', _buildConsumptionChart()),
                      const SizedBox(height: 16),
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
                FloatingActionButton.extended(
                  heroTag: 'scan_fab',
                  backgroundColor: AppTheme.surface,
                  foregroundColor: AppTheme.textSecondary,
                  elevation: 1,
                  onPressed: _scanReceipt,
                  icon: const Icon(Icons.document_scanner_rounded, size: 20),
                  label: const Text(
                    'Fiş Tara',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.extended(
                  heroTag: 'fuel_fab',
                  onPressed: () => _showAddFuelDialog(),
                  icon: const Icon(Icons.add_rounded),
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
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.local_gas_station_rounded,
                size: 36, color: AppTheme.accent),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz yakıt kaydı yok',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'İlk yakıt alımınızı kaydedin',
            style: TextStyle(color: AppTheme.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final dateFormat = DateFormat('dd MMM yyyy', 'tr_TR');
    final firstDate = _stats['firstDate'] as DateTime?;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _statTile(
          'İlk Yakıt',
          firstDate != null ? dateFormat.format(firstDate) : '-',
          Icons.calendar_today_rounded,
          AppTheme.maintColor,
        ),
        _statTile(
          'TL / KM',
          '${(_stats['costPerKm'] as num?)?.toStringAsFixed(2) ?? '0.00'} ₺',
          Icons.payments_rounded,
          AppTheme.accent,
        ),
        _statTile(
          'L / 100KM',
          '${(_stats['litersPer100Km'] as num?)?.toStringAsFixed(1) ?? '0.0'} L',
          Icons.water_drop_rounded,
          AppTheme.maintColor,
        ),
        _statTile(
          'Ort. Fiyat',
          '${(_stats['avgPrice'] as num?)?.toStringAsFixed(2) ?? '0.00'} ₺',
          Icons.trending_up_rounded,
          AppTheme.successColor,
        ),
        _statTile(
          'Alım Sayısı',
          '${_stats['count'] ?? 0}',
          Icons.receipt_long_rounded,
          AppTheme.insurColor,
        ),
        _statTile(
          'Toplam Maliyet',
          '${(_stats['totalCost'] as num?)?.toStringAsFixed(0) ?? '0'} ₺',
          Icons.account_balance_wallet_rounded,
          AppTheme.accent,
        ),
        _statTile(
          'Toplam Miktar',
          '${(_stats['totalLiters'] as num?)?.toStringAsFixed(1) ?? '0.0'} L',
          Icons.local_gas_station_rounded,
          AppTheme.maintColor,
        ),
      ],
    );
  }

  Widget _statTile(
      String label, String value, IconData icon, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 40) / 2,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: color, size: 16),
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
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
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
                const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
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
                if (value.toInt() >= _records.length)
                  return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('dd/MM')
                        .format(_records[value.toInt()].date),
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
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(
                    color: AppTheme.textHint, fontSize: 10),
              ),
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
          getDrawingHorizontalLine: (value) =>
              FlLine(color: AppTheme.dividerColor, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(_records.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: _records[index].liters,
                color: AppTheme.accent,
                width: _records.length > 10 ? 10 : 18,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5)),
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

    final maxY =
        points.map((p) => p.y).reduce((a, b) => a > b ? a : b) * 1.3;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: AppTheme.dividerColor, strokeWidth: 1),
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
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                    color: AppTheme.textHint, fontSize: 10),
              ),
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
            color: AppTheme.accent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3.5,
                  color: AppTheme.accent,
                  strokeWidth: 2,
                  strokeColor: AppTheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.accent.withValues(alpha: 0.08),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toStringAsFixed(1)} L/100km',
                  const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
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
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Son Kayıtlar',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...List.generate(_records.length, (index) {
          final record = _records[_records.length - 1 - index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_gas_station_rounded,
                      size: 16, color: AppTheme.accent),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${record.liters.toStringAsFixed(1)} L  ·  ${record.pricePerLiter.toStringAsFixed(2)} ₺/L',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
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
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${record.km.toStringAsFixed(0)} km',
                      style: const TextStyle(
                          color: AppTheme.textHint, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _confirmDeleteRecord(record),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppTheme.textHint),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _scanReceipt() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.camera);
    if (xFile == null) return;

    if (!mounted) return;
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final ocrService = OcrService();
    final result = await ocrService.processImage(xFile.path);
    ocrService.dispose();

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (!result.isAccurate && result.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage!),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
    
    _showAddFuelDialog(prefilledData: result);
  }

  void _showAddFuelDialog({OcrResult? prefilledData}) {
    DateTime selectedDate = prefilledData?.date ?? DateTime.now();
    
    final dateController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(selectedDate));
    final kmController = TextEditingController();
    final litersController = TextEditingController(
        text: prefilledData?.liters?.toStringAsFixed(2) ?? '');
    final totalController = TextEditingController(
        text: prefilledData?.totalCost?.toStringAsFixed(2) ?? '');
    
    double? initialPrice;
    if (prefilledData?.totalCost != null && prefilledData?.liters != null) {
      initialPrice = prefilledData!.totalCost! / prefilledData.liters!;
    }
    final priceController = TextEditingController(
        text: initialPrice?.toStringAsFixed(2) ?? '');
    
    bool fullTank = true;

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
      backgroundColor: AppTheme.surface,
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
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Yeni Yakıt Alımı',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Date
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
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
                        style:
                            const TextStyle(color: AppTheme.textPrimary),
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
                        style:
                            const TextStyle(color: AppTheme.textPrimary),
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_gas_station_rounded,
                          color: AppTheme.textHint, size: 18),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Depo doldu mu?',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Switch(
                        value: fullTank,
                        onChanged: (val) =>
                            setModalState(() => fullTank = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final km = double.tryParse(kmController.text);
                    final liters =
                        double.tryParse(litersController.text);
                    final price = double.tryParse(priceController.text);
                    final total =
                        double.tryParse(totalController.text);

                    if (km == null ||
                        liters == null ||
                        price == null ||
                        total == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Lütfen tüm alanları doldurun')),
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
        title: const Text('Kaydı Sil'),
        content: const Text(
            'Bu yakıt kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dangerColor),
            onPressed: () async {
              await DatabaseHelper.instance
                  .deleteFuelRecord(record.id!);
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
