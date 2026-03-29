import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../database/database_helper.dart';
import '../../models/maintenance_record.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';

class MaintenanceTab extends StatefulWidget {
  final int vehicleId;
  final VoidCallback onDataChanged;

  const MaintenanceTab(
      {super.key, required this.vehicleId, required this.onDataChanged});

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
    final records = await DatabaseHelper.instance
        .getMaintenanceRecords(widget.vehicleId);
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.accent));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _records.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              child: Column(
                children: [
                  _buildStatsSummary(),
                  const SizedBox(height: 12),
                  _buildCostChart(),
                  const SizedBox(height: 12),
                  _buildRecordsList(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMaintenanceSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kayıt Ekle'),
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
              color: AppTheme.maintColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.build_rounded,
                size: 36, color: AppTheme.maintColor),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz bakım kaydı yok',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'İlk bakım kaydınızı ekleyin',
            style: TextStyle(color: AppTheme.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    final total = _records.fold(0.0, (sum, r) => sum + r.cost);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecorationFor(context),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.maintColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.build_rounded,
                color: AppTheme.maintColor, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toplam Bakım Gideri',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 3),
              Text(
                '${total.toStringAsFixed(0)} ₺',
                style: const TextStyle(
                  color: AppTheme.maintColor,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_records.length}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'kayıt',
                style: TextStyle(
                    color: AppTheme.textHint, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCostChart() {
    final Map<String, double> categoryCosts = {};
    for (var r in _records) {
      categoryCosts[r.category] =
          (categoryCosts[r.category] ?? 0) + r.cost;
    }

    // Use a curated warm palette instead of random Material colors
    const chartColors = [
      AppTheme.accent,
      AppTheme.maintColor,
      AppTheme.successColor,
      AppTheme.insurColor,
      Color(0xFFB45309),
      Color(0xFF0891B2),
    ];

    final sections = <PieChartSectionData>[];
    int i = 0;
    categoryCosts.forEach((cat, cost) {
      sections.add(PieChartSectionData(
        value: cost,
        title: '',
        radius: 30,
        color: chartColors[i % chartColors.length],
      ));
      i++;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecorationFor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Dağılımı',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 28,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (() {
                    int idx = 0;
                    return categoryCosts.keys.map((cat) {
                      final color =
                          chartColors[idx++ % chartColors.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Text(
                              cat,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  })(),
                ),
              ],
            ),
          ),
        ],
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
            'Bakım Kayıtları',
            style: TextStyle(
              color: AppTheme.maintColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _records.length,
          itemBuilder: (context, index) {
            final r = _records[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceFor(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderFor(context)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.maintColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.handyman_rounded,
                        color: AppTheme.maintColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          r.category,
                          style: const TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${DateFormat('dd.MM.yyyy').format(r.date)}  ·  ${r.km.toStringAsFixed(0)} km',
                          style: const TextStyle(
                              color: AppTheme.textHint, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${r.cost.toStringAsFixed(0)} ₺',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _confirmDelete(MaintenanceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kaydı Sil'),
        content: const Text(
            'Bu bakım kaydını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance
                  .deleteMaintenanceRecord(record.id!);
              Navigator.pop(context);
              _loadRecords();
              widget.onDataChanged();
            },
            child: const Text('Sil',
                style: TextStyle(color: AppTheme.dangerColor)),
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

    bool setReminder = false;
    DateTime reminderDate = DateTime.now().add(const Duration(days: 365));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceFor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
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
                      color: AppTheme.borderFor(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Yeni Bakım Kaydı',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Bakım Başlığı (örn: Yağ Değişimi)',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: kmController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        decoration:
                            const InputDecoration(labelText: 'KM'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: costController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        decoration: const InputDecoration(
                            labelText: 'Tutar (₺)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  items: [
                    'Periyodik Bakım',
                    'Motor',
                    'Fren',
                    'Lastik',
                    'Elektrik',
                    'Diğer'
                  ]
                      .map((v) => DropdownMenuItem(
                          value: v,
                          child: Text(v,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface))))
                      .toList(),
                  onChanged: (val) =>
                      setModalState(() => category = val!),
                  decoration:
                      const InputDecoration(labelText: 'Kategori'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setModalState(() => date = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today_rounded,
                      size: 16),
                  label: Text(DateFormat('dd.MM.yyyy').format(date)),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceAltFor(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderFor(context)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded,
                              color: AppTheme.textHint, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sonraki Bakım İçin Hatırlat',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Switch(
                            value: setReminder,
                            onChanged: (val) =>
                                setModalState(() => setReminder = val),
                          ),
                        ],
                      ),
                      if (setReminder) ...[
                        const Divider(height: 16),
                        GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: reminderDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setModalState(() => reminderDate = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceFor(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderFor(context)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_available_rounded, size: 16, color: AppTheme.accent),
                                const SizedBox(width: 8),
                                Text(
                                  'Hatırlatma Tarihi: ${DateFormat('dd.MM.yyyy').format(reminderDate)}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty &&
                        costController.text.isNotEmpty &&
                        kmController.text.isNotEmpty) {
                      final record = MaintenanceRecord(
                        vehicleId: widget.vehicleId,
                        date: date,
                        km: double.parse(kmController.text),
                        title: titleController.text,
                        cost: double.parse(costController.text),
                        category: category,
                      );
                      final id = await DatabaseHelper.instance
                          .insertMaintenanceRecord(record);
                          
                      if (setReminder) {
                         // Multiply by 1000 or similar to avoid ID collisions with insurance tax tab, 
                         // or handle better in DB. For now simple shift:
                         await NotificationService().scheduleNotification(
                           id: id + 100000, 
                           title: 'Bakım Hatırlatıcısı',
                           body: '${titleController.text} bakımı için zaman geldi.',
                           scheduledDate: reminderDate.add(const Duration(hours: 10)), // Sabah 10
                         );
                      }
                          
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadRecords();
                        widget.onDataChanged();
                      }
                    }
                  },
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
