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
        fuelStats[v.id!] =
            await DatabaseHelper.instance.getVehicleFuelStats(v.id!);
        maintenanceCosts[v.id!] =
            await DatabaseHelper.instance.getTotalMaintenanceCost(v.id!);
        insuranceCosts[v.id!] =
            await DatabaseHelper.instance.getTotalInsuranceTaxCost(v.id!);
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
      backgroundColor: AppTheme.bgMain,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: AppTheme.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Genel İstatistikler',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: AppTheme.dividerColor),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent))
                  : _vehicles.isEmpty
                      ? Center(
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
                                child: const Icon(Icons.bar_chart_rounded,
                                    size: 36, color: AppTheme.accent),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Henüz araç eklenmemiş',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildOverallSummary(),
                              const SizedBox(height: 16),
                              _buildCostComparisonChart(),
                              const SizedBox(height: 16),
                              _buildCategoryDistributionChart(),
                              const SizedBox(height: 16),
                              _buildVehicleTable(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallSummary() {
    double totalFuel = 0, totalMaint = 0, totalIns = 0;
    for (var v in _vehicles) {
      if (v.id != null) {
        totalFuel +=
            (_fuelStats[v.id!]?['totalCost'] as num?)?.toDouble() ?? 0;
        totalMaint += _maintenanceCosts[v.id!] ?? 0;
        totalIns += _insuranceCosts[v.id!] ?? 0;
      }
    }
    final grandTotal = totalFuel + totalMaint + totalIns;

    return Column(
      children: [
        // Grand total — hero card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 28),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${grandTotal.toStringAsFixed(0)} ₺',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'Toplam Gider',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Category breakdown
        Row(
          children: [
            Expanded(
              child: _summaryTile('Yakıt', totalFuel,
                  Icons.local_gas_station_rounded, AppTheme.fuelColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _summaryTile('Bakım', totalMaint,
                  Icons.build_rounded, AppTheme.maintColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _summaryTile('Sigorta / Vergi', totalIns,
                  Icons.shield_rounded, AppTheme.insurColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryTile(
      String label, double value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(0)} ₺',
            style: TextStyle(
              color: color,
              fontSize: 14,
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
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCostComparisonChart() {
    if (_vehicles.isEmpty) return const SizedBox();

    return Container(
      decoration: AppTheme.glassDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Araçlar Arası Maliyet Kıyası',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        final i = v.toInt();
                        if (i >= _vehicles.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _vehicles[i].name,
                            style: const TextStyle(
                                color: AppTheme.textHint, fontSize: 9),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}₺',
                        style: const TextStyle(
                            color: AppTheme.textHint, fontSize: 9),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: AppTheme.dividerColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_vehicles.length, (i) {
                  final v = _vehicles[i];
                  final fuel =
                      (_fuelStats[v.id!]?['totalCost'] as num?)?.toDouble() ??
                          0;
                  final maint = _maintenanceCosts[v.id!] ?? 0;
                  final ins = _insuranceCosts[v.id!] ?? 0;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: fuel,
                        color: AppTheme.fuelColor,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: maint,
                        color: AppTheme.maintColor,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: ins,
                        color: AppTheme.insurColor,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend('Yakıt', AppTheme.fuelColor),
              const SizedBox(width: 16),
              _legend('Bakım', AppTheme.maintColor),
              const SizedBox(width: 16),
              _legend('Sigorta/Vergi', AppTheme.insurColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildCategoryDistributionChart() {
    double totalFuel = 0, totalMaint = 0, totalIns = 0;
    for (var v in _vehicles) {
      if (v.id != null) {
        totalFuel +=
            (_fuelStats[v.id!]?['totalCost'] as num?)?.toDouble() ?? 0;
        totalMaint += _maintenanceCosts[v.id!] ?? 0;
        totalIns += _insuranceCosts[v.id!] ?? 0;
      }
    }
    final total = totalFuel + totalMaint + totalIns;
    if (total == 0) return const SizedBox();

    return Container(
      decoration: AppTheme.glassDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori Dağılımı',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: [
                        PieChartSectionData(
                          color: AppTheme.fuelColor,
                          value: totalFuel,
                          title:
                              '${(totalFuel / total * 100).toStringAsFixed(0)}%',
                          radius: 55,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        PieChartSectionData(
                          color: AppTheme.maintColor,
                          value: totalMaint,
                          title:
                              '${(totalMaint / total * 100).toStringAsFixed(0)}%',
                          radius: 55,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        PieChartSectionData(
                          color: AppTheme.insurColor,
                          value: totalIns,
                          title:
                              '${(totalIns / total * 100).toStringAsFixed(0)}%',
                          radius: 55,
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      sectionsSpace: 3,
                      centerSpaceRadius: 35,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legend('Yakıt', AppTheme.fuelColor),
                    const SizedBox(height: 8),
                    _legend('Bakım', AppTheme.maintColor),
                    const SizedBox(height: 8),
                    _legend('Sigorta/Vergi', AppTheme.insurColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTable() {
    return Container(
      decoration: AppTheme.glassDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Araç Detay Tablosu',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(AppTheme.surfaceAlt),
              dataRowColor: WidgetStateProperty.all(AppTheme.surface),
              columnSpacing: 16,
              headingTextStyle: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              columns: const [
                DataColumn(label: Text('Araç')),
                DataColumn(label: Text('Yakıt')),
                DataColumn(label: Text('Bakım')),
                DataColumn(label: Text('Sigorta')),
                DataColumn(label: Text('Toplam')),
              ],
              rows: _vehicles.map((v) {
                final fuel =
                    (_fuelStats[v.id!]?['totalCost'] as num?)?.toDouble() ??
                        0;
                final maint = _maintenanceCosts[v.id!] ?? 0;
                final ins = _insuranceCosts[v.id!] ?? 0;
                return DataRow(
                  cells: [
                    DataCell(Text(v.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ))),
                    DataCell(Text('${fuel.toStringAsFixed(0)} ₺',
                        style: const TextStyle(
                            color: AppTheme.fuelColor, fontSize: 12))),
                    DataCell(Text('${maint.toStringAsFixed(0)} ₺',
                        style: const TextStyle(
                            color: AppTheme.maintColor, fontSize: 12))),
                    DataCell(Text('${ins.toStringAsFixed(0)} ₺',
                        style: const TextStyle(
                            color: AppTheme.insurColor, fontSize: 12))),
                    DataCell(Text(
                      '${(fuel + maint + ins).toStringAsFixed(0)} ₺',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
