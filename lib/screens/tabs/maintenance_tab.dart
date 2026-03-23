import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../database/database_helper.dart';
import '../../models/maintenance_record.dart';
import '../../theme/app_theme.dart';

class MaintenanceTab extends StatefulWidget {
  final int vehicleId;
  final VoidCallback onDataChanged;

  const MaintenanceTab({super.key, required this.vehicleId, required this.onDataChanged});

  @override
  State<MaintenanceTab> createState() => _MaintenanceTabState();
}

class _MaintenanceTabState extends State<MaintenanceTab> {
  List<MaintenanceRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    final records = await DatabaseHelper.instance.getMaintenanceRecords(widget.vehicleId);
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accentGreen));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _records.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildStatsSummary(),
                  const SizedBox(height: 16),
                  _buildCostChart(),
                  const SizedBox(height: 16),
                  _buildRecordsList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMaintenanceSheet,
        backgroundColor: AppTheme.accentGreen,
        child: const Icon(Icons.add_rounded, color: AppTheme.primaryDark),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.build_circle_rounded, size: 64, color: AppTheme.accentGreen.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('Henüz bakım kaydı yok', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    double total = _records.fold(0, (sum, r) => sum + r.cost);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Toplam Bakım Gideri', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              const SizedBox(height: 4),
              Text('${total.toStringAsFixed(0)} ₺', style: const TextStyle(color: AppTheme.accentGreen, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.accentGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.build_rounded, color: AppTheme.accentGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildCostChart() {
    // Basic category pie chart
    Map<String, double> categoryCosts = {};
    for (var r in _records) {
      categoryCosts[r.category] = (categoryCosts[r.category] ?? 0) + r.cost;
    }

    List<PieChartSectionData> sections = [];
    int i = 0;
    categoryCosts.forEach((cat, cost) {
      Color color = Colors.primaries[i % Colors.primaries.length];
      sections.add(PieChartSectionData(
        value: cost,
        title: '',
        radius: 30,
        color: color,
      ));
      i++;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kategori Dağılımı', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: Row(
              children: [
                Expanded(child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 30, sectionsSpace: 2))),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categoryCosts.keys.map((cat) {
                    int index = categoryCosts.keys.toList().indexOf(cat);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, color: Colors.primaries[index % Colors.primaries.length]),
                          const SizedBox(width: 8),
                          Text(cat, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final r = _records[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: AppTheme.cardDecoration,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppTheme.accentGreen.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.handyman_rounded, color: AppTheme.accentGreen, size: 20),
            ),
            title: Text(r.title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.category, style: const TextStyle(color: AppTheme.accentGreen, fontSize: 12)),
                Text('${DateFormat('dd.MM.yyyy').format(r.date)} • ${r.km.toStringAsFixed(0)} km', style: const TextStyle(color: AppTheme.textHint, fontSize: 11)),
              ],
            ),
            trailing: Text('${r.cost.toStringAsFixed(0)} ₺', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            onLongPress: () => _confirmDelete(r),
          ),
        );
      },
    );
  }

  void _confirmDelete(MaintenanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('Kaydı Sil', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Bu bakım kaydını silmek istediğinize emin misiniz?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteMaintenanceRecord(record.id!);
              Navigator.pop(context);
              _loadRecords();
              widget.onDataChanged();
            },
            child: const Text('Sil', style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );
  }

  void _showAddMaintenanceSheet() {
    final titleController = TextEditingController();
    final costController = TextEditingController();
    final kmController = TextEditingController();
    String category = 'Periyodik Bakım';
    DateTime date = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Yeni Bakım Kaydı', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Bakım Başlığı (örn: Yağ Değişimi)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: kmController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'KM', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: costController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tutar (₺)', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  dropdownColor: AppTheme.surfaceCard,
                  items: ['Periyodik Bakım', 'Motor', 'Fren', 'Lastik', 'Elektrik', 'Diğer'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(color: AppTheme.textPrimary)));
                  }).toList(),
                  onChanged: (val) => setModalState(() => category = val!),
                  decoration: const InputDecoration(labelText: 'Kategori', labelStyle: TextStyle(color: AppTheme.textSecondary)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime.now());
                    if (picked != null) setModalState(() => date = picked);
                  },
                  icon: const Icon(Icons.calendar_today_rounded, size: 18),
                  label: Text(DateFormat('dd.MM.yyyy').format(date)),
                  style: OutlinedButton.styleFrom(foregroundColor: AppTheme.accentGreen),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty && costController.text.isNotEmpty && kmController.text.isNotEmpty) {
                      final record = MaintenanceRecord(
                        vehicleId: widget.vehicleId,
                        date: date,
                        km: double.parse(kmController.text),
                        title: titleController.text,
                        cost: double.parse(costController.text),
                        category: category,
                      );
                      await DatabaseHelper.instance.insertMaintenanceRecord(record);
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadRecords();
                        widget.onDataChanged();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentGreen),
                  child: const Text('Kaydet'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
