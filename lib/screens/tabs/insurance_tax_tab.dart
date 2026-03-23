import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../database/database_helper.dart';
import '../../models/insurance_tax_record.dart';
import '../../theme/app_theme.dart';

class InsuranceTaxTab extends StatefulWidget {
  final int vehicleId;
  final VoidCallback onDataChanged;
  const InsuranceTaxTab({super.key, required this.vehicleId, required this.onDataChanged});

  @override
  State<InsuranceTaxTab> createState() => _InsuranceTaxTabState();
}

class _InsuranceTaxTabState extends State<InsuranceTaxTab> {
  List<InsuranceTaxRecord> _records = [];
  bool _loading = true;

  final List<String> _types = [
    'Trafik Sigortası', 'Kasko', 'MTV', 'Muayene', 'Diğer',
  ];
  final Map<String, Color> _typeColors = {
    'Trafik Sigortası': AppTheme.accentOrange,
    'Kasko': AppTheme.accentBlue,
    'MTV': AppTheme.accentRed,
    'Muayene': AppTheme.accentGreen,
    'Diğer': AppTheme.accentPurple,
  };
  final Map<String, IconData> _typeIcons = {
    'Trafik Sigortası': Icons.shield_rounded,
    'Kasko': Icons.security_rounded,
    'MTV': Icons.receipt_long_rounded,
    'Muayene': Icons.verified_rounded,
    'Diğer': Icons.more_horiz_rounded,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final records = await DatabaseHelper.instance.getInsuranceTaxRecords(widget.vehicleId);
    setState(() { _records = records; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accentBlue));

    return Stack(
      children: [
        _records.isEmpty ? _buildEmptyState() : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _buildSummaryRow(),
            const SizedBox(height: 16),
            _buildChartCard('Tür Dağılımı', _buildPieChart()),
            const SizedBox(height: 16),
            _buildChartCard('Yıllık Maliyet Trendi', _buildYearlyCostChart()),
            const SizedBox(height: 16),
            _buildRecordsList(),
          ]),
        ),
        Positioned(
          bottom: 16, right: 16,
          child: FloatingActionButton.extended(
            heroTag: 'insurance_fab',
            onPressed: _showAddDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Kayıt Ekle'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.security_rounded, size: 56, color: AppTheme.accentPurple.withValues(alpha: 0.4)),
      const SizedBox(height: 16),
      const Text('Henüz sigorta/vergi kaydı yok', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w500)),
      const SizedBox(height: 24),
      ElevatedButton.icon(onPressed: _showAddDialog, icon: const Icon(Icons.add_rounded), label: const Text('Kayıt Ekle')),
    ]));
  }

  Widget _buildSummaryRow() {
    final totalCost = _records.fold(0.0, (s, r) => s + r.cost);
    return Row(children: [
      Expanded(child: _tile('Toplam Maliyet', '${totalCost.toStringAsFixed(0)} ₺', Icons.account_balance_wallet_rounded, AppTheme.accentOrange)),
      const SizedBox(width: 10),
      Expanded(child: _tile('Kayıt Sayısı', '${_records.length}', Icons.receipt_long_rounded, AppTheme.accentBlue)),
    ]);
  }

  Widget _tile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Column(children: [
        Icon(icon, color: color, size: 20), const SizedBox(height: 6),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Container(
      decoration: AppTheme.glassDecoration, padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        SizedBox(height: 200, child: chart),
      ]),
    );
  }

  Widget _buildPieChart() {
    if (_records.isEmpty) return const Center(child: Text('Veri yok', style: TextStyle(color: AppTheme.textHint)));
    final typeSum = <String, double>{};
    for (var r in _records) { typeSum[r.type] = (typeSum[r.type] ?? 0) + r.cost; }
    final total = typeSum.values.fold(0.0, (a, b) => a + b);

    return Row(children: [
      Expanded(child: PieChart(PieChartData(
        sections: typeSum.entries.map((e) {
          final color = _typeColors[e.key] ?? AppTheme.accentPurple;
          return PieChartSectionData(color: color, value: e.value, title: '${(e.value / total * 100).toStringAsFixed(0)}%', radius: 50,
            titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold));
        }).toList(),
        sectionsSpace: 2, centerSpaceRadius: 32,
      ))),
      const SizedBox(width: 12),
      Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
        children: typeSum.entries.map((e) {
          final color = _typeColors[e.key] ?? AppTheme.accentPurple;
          return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(e.key, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ]));
        }).toList(),
      ),
    ]);
  }

  Widget _buildYearlyCostChart() {
    if (_records.isEmpty) return const Center(child: Text('Veri yok', style: TextStyle(color: AppTheme.textHint)));
    final yearlySum = <String, double>{};
    for (var r in _records) { final key = r.date.year.toString(); yearlySum[key] = (yearlySum[key] ?? 0) + r.cost; }
    final sortedKeys = yearlySum.keys.toList()..sort();
    if (sortedKeys.isEmpty) return const SizedBox();
    final maxY = yearlySum.values.reduce((a, b) => a > b ? a : b) * 1.3;

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround, maxY: maxY,
      titlesData: FlTitlesData(show: true,
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
          final i = v.toInt(); if (i >= sortedKeys.length) return const SizedBox();
          return Text(sortedKeys[i], style: const TextStyle(color: AppTheme.textHint, fontSize: 10));
        }, reservedSize: 24)),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, m) => Text('${v.toInt()}₺', style: const TextStyle(color: AppTheme.textHint, fontSize: 9)))),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.dividerColor.withValues(alpha: 0.3), strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(sortedKeys.length, (i) => BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: yearlySum[sortedKeys[i]]!, gradient: const LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [AppTheme.accentPurple, AppTheme.accentBlue]),
          width: sortedKeys.length > 6 ? 14 : 24, borderRadius: const BorderRadius.vertical(top: Radius.circular(6))),
      ])),
    ));
  }

  Widget _buildRecordsList() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Kayıt Geçmişi', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
      ..._records.map((r) {
        final color = _typeColors[r.type] ?? AppTheme.accentPurple;
        final icon = _typeIcons[r.type] ?? Icons.receipt_long_rounded;
        return Container(
          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppTheme.surfaceOverlay, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 18, color: color)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.type, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text('${DateFormat('dd MMM yyyy').format(r.date)}${r.provider != null ? ' • ${r.provider}' : ''}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ])),
            Text('${r.cost.toStringAsFixed(0)} ₺', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(width: 4),
            GestureDetector(onTap: () => _confirmDelete(r), child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textHint)),
          ]),
        );
      }),
    ]);
  }

  void _showAddDialog() {
    final dateCtrl = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
    final costCtrl = TextEditingController();
    final providerCtrl = TextEditingController();
    final policyCtrl = TextEditingController();
    String selectedType = _types.first;
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.dividerColor, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Yeni Sigorta/Vergi Kaydı', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(value: selectedType,
              decoration: const InputDecoration(labelText: 'Tür', prefixIcon: Icon(Icons.category_rounded, color: AppTheme.textHint, size: 20)),
              dropdownColor: AppTheme.surfaceOverlay, style: const TextStyle(color: AppTheme.textPrimary),
              items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) { if (v != null) setModalState(() => selectedType = v); }),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100),
                  builder: (c, child) => Theme(data: Theme.of(c).copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.accentBlue, surface: AppTheme.surfaceCard)), child: child!));
                if (date != null) { selectedDate = date; dateCtrl.text = DateFormat('dd/MM/yyyy').format(date); }
              },
              child: AbsorbPointer(child: TextField(controller: dateCtrl, style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Tarih', prefixIcon: Icon(Icons.calendar_today_rounded, color: AppTheme.textHint, size: 20)))),
            ),
            const SizedBox(height: 12),
            TextField(controller: costCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Tutar', prefixIcon: Icon(Icons.payments_rounded, color: AppTheme.textHint, size: 20), suffixText: '₺')),
            const SizedBox(height: 12),
            TextField(controller: providerCtrl, style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Kurum/Şirket (Opsiyonel)', prefixIcon: Icon(Icons.business_rounded, color: AppTheme.textHint, size: 20))),
            const SizedBox(height: 12),
            TextField(controller: policyCtrl, style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Poliçe No (Opsiyonel)', prefixIcon: Icon(Icons.tag_rounded, color: AppTheme.textHint, size: 20))),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: () async {
              final cost = double.tryParse(costCtrl.text);
              if (cost == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tutar gerekli'))); return; }
              final record = InsuranceTaxRecord(vehicleId: widget.vehicleId, date: selectedDate, type: selectedType, cost: cost,
                provider: providerCtrl.text.trim().isEmpty ? null : providerCtrl.text.trim(),
                policyNumber: policyCtrl.text.trim().isEmpty ? null : policyCtrl.text.trim());
              await DatabaseHelper.instance.insertInsuranceTaxRecord(record);
              await _loadData();
              widget.onDataChanged();
              if (mounted) Navigator.pop(context);
            }, child: const Text('Kaydet')),
          ])),
        ),
      ),
    );
  }

  void _confirmDelete(InsuranceTaxRecord record) {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: AppTheme.surfaceCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Kaydı Sil', style: TextStyle(color: AppTheme.textPrimary)),
      content: const Text('Bu kaydı silmek istediğinize emin misiniz?', style: TextStyle(color: AppTheme.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal', style: TextStyle(color: AppTheme.textSecondary))),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentRed),
          onPressed: () async { await DatabaseHelper.instance.deleteInsuranceTaxRecord(record.id!); await _loadData(); widget.onDataChanged(); if (mounted) Navigator.pop(context); },
          child: const Text('Sil', style: TextStyle(color: Colors.white))),
      ],
    ));
  }
}

