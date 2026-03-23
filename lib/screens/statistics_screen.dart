import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Vehicle> _vehicles = [];
  Map<int, Map<String, dynamic>> _fuelStats = {};
  Map<int, double> _maintenanceCosts = {};
  Map<int, double> _insuranceCosts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final vehicles = await DatabaseHelper.instance.getAllVehicles();
    final fuelStats = <int, Map<String, dynamic>>{};
    final maintenanceCosts = <int, double>{};
    final insuranceCosts = <int, double>{};

    for (var v in vehicles) {
      if (v.id != null) {
        fuelStats[v.id!] = await DatabaseHelper.instance.getVehicleFuelStats(v.id!);
        maintenanceCosts[v.id!] = await DatabaseHelper.instance.getTotalMaintenanceCost(v.id!);
        insuranceCosts[v.id!] = await DatabaseHelper.instance.getTotalInsuranceTaxCost(v.id!);
      }
    }

    setState(() {
      _vehicles = vehicles;
      _fuelStats = fuelStats;
      _maintenanceCosts = maintenanceCosts;
      _insuranceCosts = insuranceCosts;
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(children: [
                  IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
                  const Text('Genel İstatistikler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                ]),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.accentBlue))
                    : _vehicles.isEmpty
                        ? const Center(child: Text('Henüz araç eklenmemiş', style: TextStyle(color: AppTheme.textSecondary)))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              _buildOverallSummary(),
                              const SizedBox(height: 16),
                              _buildCostComparisonChart(),
                              const SizedBox(height: 16),
                              _buildCategoryDistributionChart(),
                              const SizedBox(height: 16),
                              _buildVehicleTable(),
                            ]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallSummary() {
    double totalFuel = 0, totalMaint = 0, totalIns = 0;
    for (var v in _vehicles) {
      if (v.id != null) {
        totalFuel += (_fuelStats[v.id!]?['totalCost'] as num?)?.toDouble() ?? 0;
        totalMaint += _maintenanceCosts[v.id!] ?? 0;
        totalIns += _insuranceCosts[v.id!] ?? 0;
      }
    }
    final grandTotal = totalFuel + totalMaint + totalIns;

    return Wrap(spacing: 10, runSpacing: 10, children: [
      _summaryTile('Toplam Gider', '${grandTotal.toStringAsFixed(0)} ₺', Icons.account_balance_wallet_rounded, AppTheme.accentBlue),
      _summaryTile('Yakıt Gideri', '${totalFuel.toStringAsFixed(0)} ₺', Icons.local_gas_station_rounded, AppTheme.accentOrange),
      _summaryTile('Bakım Gideri', '${totalMaint.toStringAsFixed(0)} ₺', Icons.build_rounded, AppTheme.accentGreen),
      _summaryTile('Sigorta/Vergi', '${totalIns.toStringAsFixed(0)} ₺', Icons.security_rounded, AppTheme.accentPurple),
    ]);
  }

  Widget _summaryTile(String label, String value, IconData icon, Color color) {
    return Container(
      width: (MediaQuery.of(context).size.width - 42) / 2,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  Widget _buildCostComparisonChart() {
    if (_vehicles.isEmpty) return const SizedBox();

    return Container(
      decoration: AppTheme.glassDecoration, padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Araçlar Arası Maliyet Kıyası', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        SizedBox(height: 200, child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(show: true,
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
              final i = v.toInt(); if (i >= _vehicles.length) return const SizedBox();
              return Padding(padding: const EdgeInsets.only(top: 4), child: Text(_vehicles[i].name, style: const TextStyle(color: AppTheme.textHint, fontSize: 9), overflow: TextOverflow.ellipsis));
            }, reservedSize: 24)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 44, getTitlesWidget: (v, m) => Text('${v.toInt()}₺', style: const TextStyle(color: AppTheme.textHint, fontSize: 9)))),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppTheme.dividerColor.withValues(alpha: 0.3), strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(_vehicles.length, (i) {
            final v = _vehicles[i];
            final fuel = (_fuelStats[v.id!]?['totalCost'] as num?)?.toDouble() ?? 0;
            final maint = _maintenanceCosts[v.id!] ?? 0;
            final ins = _insuranceCosts[v.id!] ?? 0;
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: fuel, color: AppTheme.accentOrange, width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
              BarChartRodData(toY: maint, color: AppTheme.accentGreen, width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
              BarChartRodData(toY: ins, color: AppTheme.accentPurple, width: 8, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
            ]);
          }),
        ))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _legend('Yakıt', AppTheme.accentOrange),
          const SizedBox(width: 16),
          _legend('Bakım', AppTheme.accentGreen),
          const SizedBox(width: 16),
          _legend('Sigorta/Vergi', AppTheme.accentPurple),
        ]),
      ]),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
    ]);
  }

  Widget _buildCategoryDistributionChart() {
    double totalFuel = 0, totalMaint = 0, totalIns = 0;
    for (var v in _vehicles) {
      if (v.id != null) {
        totalFuel += (_fuelStats[v.id!]?['totalCost'] as num?)?.toDouble() ?? 0;
        totalMaint += _maintenanceCosts[v.id!] ?? 0;
        totalIns += _insuranceCosts[v.id!] ?? 0;
      }
    }
    final total = totalFuel + totalMaint + totalIns;
    if (total == 0) return const SizedBox();

    return Container(
      decoration: AppTheme.glassDecoration, padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Kategori Dağılımı', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        SizedBox(height: 200, child: Row(children: [
          Expanded(child: PieChart(PieChartData(
            sections: [
              PieChartSectionData(color: AppTheme.accentOrange, value: totalFuel, title: '${(totalFuel / total * 100).toStringAsFixed(0)}%', radius: 55, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              PieChartSectionData(color: AppTheme.accentGreen, value: totalMaint, title: '${(totalMaint / total * 100).toStringAsFixed(0)}%', radius: 55, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              PieChartSectionData(color: AppTheme.accentPurple, value: totalIns, title: '${(totalIns / total * 100).toStringAsFixed(0)}%', radius: 55, titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
            sectionsSpace: 3, centerSpaceRadius: 35,
          ))),
          const SizedBox(width: 16),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _legend('Yakıt', AppTheme.accentOrange),
            const SizedBox(height: 8),
            _legend('Bakım', AppTheme.accentGreen),
            const SizedBox(height: 8),
            _legend('Sigorta/Vergi', AppTheme.accentPurple),
          ]),
        ])),
      ]),
    );
  }

  Widget _buildVehicleTable() {
    return Container(
      decoration: AppTheme.glassDecoration, padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Araç Detay Tablosu', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppTheme.surfaceOverlay),
            columnSpacing: 16,
            columns: const [
              DataColumn(label: Text('Araç', style: TextStyle(color: AppTheme.accentBlue, fontSize: 12, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Yakıt', style: TextStyle(color: AppTheme.accentOrange, fontSize: 12, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Bakım', style: TextStyle(color: AppTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Sigorta', style: TextStyle(color: AppTheme.accentPurple, fontSize: 12, fontWeight: FontWeight.w600))),
              DataColumn(label: Text('Toplam', style: TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600))),
            ],
            rows: _vehicles.map((v) {
              final fuel = (_fuelStats[v.id!]?['totalCost'] as num?)?.toDouble() ?? 0;
              final maint = _maintenanceCosts[v.id!] ?? 0;
              final ins = _insuranceCosts[v.id!] ?? 0;
              return DataRow(cells: [
                DataCell(Text(v.name, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12))),
                DataCell(Text('${fuel.toStringAsFixed(0)} ₺', style: const TextStyle(color: AppTheme.accentOrange, fontSize: 12))),
                DataCell(Text('${maint.toStringAsFixed(0)} ₺', style: const TextStyle(color: AppTheme.accentGreen, fontSize: 12))),
                DataCell(Text('${ins.toStringAsFixed(0)} ₺', style: const TextStyle(color: AppTheme.accentPurple, fontSize: 12))),
                DataCell(Text('${(fuel + maint + ins).toStringAsFixed(0)} ₺', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold))),
              ]);
            }).toList(),
          ),
        ),
      ]),
    );
  }
}
