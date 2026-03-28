import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import '../database/database_helper.dart';
import '../models/vehicle.dart';
import '../models/fuel_record.dart';
import '../models/maintenance_record.dart';
import '../models/insurance_tax_record.dart';

// ── Data container ────────────────────────────────────────────────────────────

class ReportData {
  final Vehicle vehicle;
  final List<FuelRecord> fuelRecords;
  final List<MaintenanceRecord> maintenanceRecords;
  final List<InsuranceTaxRecord> insuranceRecords;
  final Map<String, dynamic> fuelStats;
  final double maintenanceCost;
  final double insuranceCost;

  const ReportData({
    required this.vehicle,
    required this.fuelRecords,
    required this.maintenanceRecords,
    required this.insuranceRecords,
    required this.fuelStats,
    required this.maintenanceCost,
    required this.insuranceCost,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class ReportService {
  static final DateFormat _dateFmt = DateFormat('dd.MM.yyyy', 'tr_TR');
  static final NumberFormat _numFmt = NumberFormat('#,##0', 'tr_TR');

  // ── Data loader ─────────────────────────────────────────────────────────────

  static Future<List<ReportData>> loadData(List<Vehicle> vehicles) async {
    final result = <ReportData>[];
    for (final v in vehicles) {
      if (v.id == null) continue;
      final fuel =
          await DatabaseHelper.instance.getFuelRecords(v.id!);
      final maint =
          await DatabaseHelper.instance.getMaintenanceRecords(v.id!);
      final ins =
          await DatabaseHelper.instance.getInsuranceTaxRecords(v.id!);
      final stats =
          await DatabaseHelper.instance.getVehicleFuelStats(v.id!);
      final maintCost =
          await DatabaseHelper.instance.getTotalMaintenanceCost(v.id!);
      final insCost =
          await DatabaseHelper.instance.getTotalInsuranceTaxCost(v.id!);
      result.add(ReportData(
        vehicle: v,
        fuelRecords: fuel,
        maintenanceRecords: maint,
        insuranceRecords: ins,
        fuelStats: stats,
        maintenanceCost: maintCost,
        insuranceCost: insCost,
      ));
    }
    return result;
  }

  // ── EXCEL ────────────────────────────────────────────────────────────────────

  static Future<File> generateExcel(
    List<ReportData> data, {
    bool includeFuel = true,
    bool includeMaint = true,
    bool includeIns = true,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _buildSummarySheet(excel, data);

    for (final rd in data) {
      // Limit prefix to avoid long sheet names (max 31 chars)
      final raw = rd.vehicle.name.replaceAll(RegExp(r'[/\\*\[\]:\?]'), '');
      final prefix = raw.length > 14 ? raw.substring(0, 14) : raw;

      if (includeFuel) _buildFuelSheet(excel, rd, prefix);
      if (includeMaint) _buildMaintenanceSheet(excel, rd, prefix);
      if (includeIns) _buildInsuranceSheet(excel, rd, prefix);
    }

    final dir = await getApplicationDocumentsDirectory();
    final now = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/yakit_rapor_$now.xlsx');
    await file.writeAsBytes(excel.encode()!);
    return file;
  }

  static CellStyle _headerStyle() => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#D97706'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: HorizontalAlign.Center,
      );

  static void _h(Sheet s, int col, int row, String v) {
    final c = s.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
    c.value = TextCellValue(v);
    c.cellStyle = _headerStyle();
  }

  static void _d(Sheet s, int col, int row, String v) {
    s.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row)).value =
        TextCellValue(v);
  }

  static void _buildSummarySheet(Excel excel, List<ReportData> data) {
    final sheet = excel['Ozet'];
    final headers = [
      'Arac Adi', 'Yakit Turu', 'Son KM',
      'Yakit Gideri (TL)', 'Bakim Gideri (TL)',
      'Sigorta-Vergi (TL)', 'Toplam Gider (TL)',
      'L-100km', 'TL-km',
    ];
    for (int i = 0; i < headers.length; i++) {
      _h(sheet, i, 0, headers[i]);
      sheet.setColumnWidth(i, 22);
    }
    for (int i = 0; i < data.length; i++) {
      final rd = data[i];
      final fuelCost =
          (rd.fuelStats['totalCost'] as num?)?.toDouble() ?? 0;
      final total = fuelCost + rd.maintenanceCost + rd.insuranceCost;
      _d(sheet, 0, i + 1, rd.vehicle.name);
      _d(sheet, 1, i + 1, rd.vehicle.fuelType);
      _d(sheet, 2, i + 1, rd.vehicle.currentKm.toStringAsFixed(0));
      _d(sheet, 3, i + 1, fuelCost.toStringAsFixed(2));
      _d(sheet, 4, i + 1, rd.maintenanceCost.toStringAsFixed(2));
      _d(sheet, 5, i + 1, rd.insuranceCost.toStringAsFixed(2));
      _d(sheet, 6, i + 1, total.toStringAsFixed(2));
      _d(sheet, 7, i + 1,
          ((rd.fuelStats['litersPer100Km'] as num?)?.toDouble() ?? 0)
              .toStringAsFixed(2));
      _d(sheet, 8, i + 1,
          ((rd.fuelStats['costPerKm'] as num?)?.toDouble() ?? 0)
              .toStringAsFixed(2));
    }
  }

  static void _buildFuelSheet(Excel excel, ReportData rd, String prefix) {
    if (rd.fuelRecords.isEmpty) return;
    final sheet = excel['${prefix}_Yakit'];
    final headers = [
      'Tarih', 'Kilometre', 'Litre', 'TL-Litre', 'Toplam (TL)', 'Depo Dolu'
    ];
    for (int i = 0; i < headers.length; i++) {
      _h(sheet, i, 0, headers[i]);
      sheet.setColumnWidth(i, 18);
    }
    for (int i = 0; i < rd.fuelRecords.length; i++) {
      final r = rd.fuelRecords[i];
      _d(sheet, 0, i + 1, _dateFmt.format(r.date));
      _d(sheet, 1, i + 1, r.km.toStringAsFixed(0));
      _d(sheet, 2, i + 1, r.liters.toStringAsFixed(2));
      _d(sheet, 3, i + 1, r.pricePerLiter.toStringAsFixed(2));
      _d(sheet, 4, i + 1, r.totalCost.toStringAsFixed(2));
      _d(sheet, 5, i + 1, r.fullTank ? 'Evet' : 'Hayir');
    }
  }

  static void _buildMaintenanceSheet(
      Excel excel, ReportData rd, String prefix) {
    if (rd.maintenanceRecords.isEmpty) return;
    final sheet = excel['${prefix}_Bakim'];
    final headers = ['Tarih', 'Kilometre', 'Baslik', 'Kategori', 'Tutar (TL)'];
    for (int i = 0; i < headers.length; i++) {
      _h(sheet, i, 0, headers[i]);
      sheet.setColumnWidth(i, 22);
    }
    for (int i = 0; i < rd.maintenanceRecords.length; i++) {
      final r = rd.maintenanceRecords[i];
      _d(sheet, 0, i + 1, _dateFmt.format(r.date));
      _d(sheet, 1, i + 1, r.km.toStringAsFixed(0));
      _d(sheet, 2, i + 1, r.title);
      _d(sheet, 3, i + 1, r.category);
      _d(sheet, 4, i + 1, r.cost.toStringAsFixed(2));
    }
  }

  static void _buildInsuranceSheet(
      Excel excel, ReportData rd, String prefix) {
    if (rd.insuranceRecords.isEmpty) return;
    final sheet = excel['${prefix}_Sigorta'];
    final headers = [
      'Tarih', 'Tur', 'Kurum', 'Police No', 'Tutar (TL)'
    ];
    for (int i = 0; i < headers.length; i++) {
      _h(sheet, i, 0, headers[i]);
      sheet.setColumnWidth(i, 20);
    }
    for (int i = 0; i < rd.insuranceRecords.length; i++) {
      final r = rd.insuranceRecords[i];
      _d(sheet, 0, i + 1, _dateFmt.format(r.date));
      _d(sheet, 1, i + 1, r.type);
      _d(sheet, 2, i + 1, r.provider ?? '-');
      _d(sheet, 3, i + 1, r.policyNumber ?? '-');
      _d(sheet, 4, i + 1, r.cost.toStringAsFixed(2));
    }
  }

  // ── PDF ──────────────────────────────────────────────────────────────────────

  static Future<File> generatePdf(
    List<ReportData> data, {
    bool includeFuel = true,
    bool includeMaint = true,
    bool includeIns = true,
  }) async {
    pw.Font fontRegular;
    pw.Font fontBold;
    pw.MemoryImage? appLogo;

    try {
      final logoBytes = await rootBundle.load('assets/images/app_icon.png');
      appLogo = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}
    try {
      fontRegular = await PdfGoogleFonts.notoSansRegular();
      fontBold = await PdfGoogleFonts.notoSansBold();
    } catch (_) {
      fontRegular = pw.Font.helvetica();
      fontBold = pw.Font.helveticaBold();
    }

    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);
    final pdf = pw.Document(title: 'Yakit Yonet Raporu', theme: theme);
    final dateStr =
        DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now());

    // Cover page
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: const pw.EdgeInsets.all(40),
      build: (_) => _buildCoverPage(data, dateStr, appLogo),
    ));

    // Vehicle pages
    for (final rd in data) {
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.fromLTRB(40, 50, 40, 50),
        header: (_) => _pageHeader(rd.vehicle.name),
        footer: _pageFooter,
        build: (_) => _buildVehicleContent(rd, includeFuel, includeMaint, includeIns),
      ));
    }

    final dir = await getApplicationDocumentsDirectory();
    final now = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${dir.path}/yakit_rapor_$now.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ── PDF – cover page ─────────────────────────────────────────────────────────

  static pw.Widget _buildCoverPage(
      List<ReportData> data, String dateStr, pw.MemoryImage? appLogo) {
    final totalFuel = data.fold(
        0.0, (s, r) => s + ((r.fuelStats['totalCost'] as num?)?.toDouble() ?? 0));
    final totalMaint = data.fold(0.0, (s, r) => s + r.maintenanceCost);
    final totalIns = data.fold(0.0, (s, r) => s + r.insuranceCost);
    final grand = totalFuel + totalMaint + totalIns;

    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Spacer(),
        // Brand box
        if (appLogo != null)
          pw.Container(
            width: 96,
            height: 96,
            child: pw.Image(appLogo),
          )
        else
          pw.Container(
            width: 96,
            height: 96,
            decoration: pw.BoxDecoration(
              color: PdfColors.orange700,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(24)),
            ),
            child: pw.Center(
              child: pw.Text('YY',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 40,
                      fontWeight: pw.FontWeight.bold)),
            ),
          ),
        pw.SizedBox(height: 28),
        pw.Text('Yakit Yonet',
            style: pw.TextStyle(
                fontSize: 34,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.orange700)),
        pw.SizedBox(height: 8),
        pw.Text('Arac Gider Raporu',
            style: pw.TextStyle(fontSize: 20, color: PdfColors.grey700)),
        pw.SizedBox(height: 6),
        pw.Text(dateStr,
            style: pw.TextStyle(fontSize: 13, color: PdfColors.grey500)),
        pw.SizedBox(height: 36),
        // Summary box
        pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            border: pw.Border.all(color: PdfColors.grey200),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _cStat('Araç Sayısı', '${data.length}'),
                  _cDiv(),
                  _cStat('Yakıt Gideri', '${_numFmt.format(totalFuel)} TL'),
                  _cDiv(),
                  _cStat('Bakım Gideri', '${_numFmt.format(totalMaint)} TL'),
                  _cDiv(),
                  _cStat('Sigorta/Vergi', '${_numFmt.format(totalIns)} TL'),
                ],
              ),
              pw.SizedBox(height: 14),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange700,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  'Toplam Gider: ${_numFmt.format(grand)} TL',
                  style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        pw.Spacer(),
        pw.Text(
          'Bu rapor Yakit Yonet uygulamasi tarafindan olusturulmustur.',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey400),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _cStat(String label, String value) => pw.Column(
        children: [
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900)),
          pw.SizedBox(height: 3),
          pw.Text(label,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
        ],
      );

  static pw.Widget _cDiv() =>
      pw.Container(width: 1, height: 32, color: PdfColors.grey300);

  // ── PDF – page header / footer ───────────────────────────────────────────────

  static pw.Widget _pageHeader(String vehicleName) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.orange700, width: 2)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(children: [
            pw.Container(
              width: 12,
              height: 12,
              decoration: const pw.BoxDecoration(
                  color: PdfColors.orange700,
                  borderRadius:
                      pw.BorderRadius.all(pw.Radius.circular(3))),
            ),
            pw.SizedBox(width: 8),
            pw.Text(vehicleName,
                style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange700)),
          ]),
          pw.Text('Yakit Yonet',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey400)),
        ],
      ),
    );
  }

  static pw.Widget _pageFooter(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            top: pw.BorderSide(color: PdfColors.grey200, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Gizli – Kisisel Arac Kayitlari',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
          pw.Text('Sayfa ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
        ],
      ),
    );
  }

  // ── PDF – vehicle content ─────────────────────────────────────────────────────

  static List<pw.Widget> _buildVehicleContent(
    ReportData rd,
    bool includeFuel,
    bool includeMaint,
    bool includeIns,
  ) {
    final widgets = <pw.Widget>[];

    final fuelCost = (rd.fuelStats['totalCost'] as num?)?.toDouble() ?? 0;
    final total =
        fuelCost + rd.maintenanceCost + rd.insuranceCost;
    final l100 =
        (rd.fuelStats['litersPer100Km'] as num?)?.toDouble() ?? 0;
    final tlKm =
        (rd.fuelStats['costPerKm'] as num?)?.toDouble() ?? 0;

    // Summary card
    widgets.add(pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.orange200, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(children: [
            pw.Container(
                width: 7,
                height: 7,
                decoration: const pw.BoxDecoration(
                    color: PdfColors.orange700,
                    shape: pw.BoxShape.circle)),
            pw.SizedBox(width: 7),
            pw.Text('Arac Ozeti',
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange700)),
          ]),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            _sPdf('Yakit Turu', rd.vehicle.fuelType),
            _sPdf('Son KM',
                '${rd.vehicle.currentKm.toStringAsFixed(0)} km'),
            _sPdf(
                'L/100km', l100 > 0 ? l100.toStringAsFixed(1) : '-'),
            _sPdf(
                'TL/km', tlKm > 0 ? tlKm.toStringAsFixed(2) : '-'),
          ]),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            _cPdf('Yakıt Gideri', fuelCost, PdfColors.orange700),
            _cPdf(
                'Bakım Gideri', rd.maintenanceCost, PdfColors.blueGrey700),
            _cPdf(
                'Sigorta/Vergi', rd.insuranceCost, PdfColors.blueGrey600),
            _cPdf('TOPLAM', total, PdfColors.red700),
          ]),
        ],
      ),
    ));

    widgets.add(pw.SizedBox(height: 14));

    if (includeFuel && rd.fuelRecords.isNotEmpty) {
      widgets.add(_secHead('Yakıt Kayıtları', PdfColors.orange700));
      widgets.add(pw.SizedBox(height: 6));
      widgets.add(_pdfTable(
        ['Tarih', 'KM', 'Litre', 'TL/L', 'Toplam', 'Depo'],
        rd.fuelRecords
            .map((r) => [
                  _dateFmt.format(r.date),
                  r.km.toStringAsFixed(0),
                  r.liters.toStringAsFixed(2),
                  r.pricePerLiter.toStringAsFixed(2),
                  '${_numFmt.format(r.totalCost)} TL',
                  r.fullTank ? 'Dolu' : 'Kismi',
                ])
            .toList(),
        PdfColors.orange50,
        PdfColors.orange700,
      ));
      widgets.add(pw.SizedBox(height: 14));
    }

    if (includeMaint && rd.maintenanceRecords.isNotEmpty) {
      widgets.add(_secHead('Bakım Kayıtları', PdfColors.blueGrey700));
      widgets.add(pw.SizedBox(height: 6));
      widgets.add(_pdfTable(
        ['Tarih', 'KM', 'Başlık', 'Kategori', 'Tutar'],
        rd.maintenanceRecords
            .map((r) => [
                  _dateFmt.format(r.date),
                  r.km.toStringAsFixed(0),
                  r.title,
                  r.category,
                  '${_numFmt.format(r.cost)} TL',
                ])
            .toList(),
        PdfColors.blueGrey50,
        PdfColors.blueGrey700,
      ));
      widgets.add(pw.SizedBox(height: 14));
    }

    if (includeIns && rd.insuranceRecords.isNotEmpty) {
      widgets.add(_secHead('Sigorta / Vergi Kayıtları', PdfColors.blueGrey600));
      widgets.add(pw.SizedBox(height: 6));
      widgets.add(_pdfTable(
        ['Tarih', 'Tür', 'Kurum', 'Poliçe No', 'Tutar'],
        rd.insuranceRecords
            .map((r) => [
                  _dateFmt.format(r.date),
                  r.type,
                  r.provider ?? '-',
                  r.policyNumber ?? '-',
                  '${_numFmt.format(r.cost)} TL',
                ])
            .toList(),
        PdfColors.blueGrey50,
        PdfColors.blueGrey600,
      ));
    }

    return widgets;
  }

  static pw.Widget _sPdf(String label, String value) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 6),
          padding: const pw.EdgeInsets.all(7),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(value,
                  style: pw.TextStyle(
                      fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ),
      );

  static pw.Widget _cPdf(String label, double amount, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 6),
          padding: const pw.EdgeInsets.all(7),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            border: pw.Border.all(color: color, width: 0.5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('${_numFmt.format(amount)} TL',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: color)),
              pw.Text(label,
                  style: pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ),
      );

  static pw.Widget _secHead(String title, PdfColor color) => pw.Container(
        padding:
            const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        ),
        child: pw.Text(title,
            style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 10,
                fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _pdfTable(
    List<String> headers,
    List<List<String>> rows,
    PdfColor headerBg,
    PdfColor accent,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerBg),
          children: headers
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 5, vertical: 5),
                    child: pw.Text(h,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 8.5,
                            color: accent)),
                  ))
              .toList(),
        ),
        ...rows.asMap().entries.map((e) => pw.TableRow(
              decoration: pw.BoxDecoration(
                  color: e.key.isEven ? PdfColors.white : PdfColors.grey50),
              children: e.value
                  .map((cell) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 5, vertical: 4),
                        child: pw.Text(cell,
                            style: const pw.TextStyle(fontSize: 8.5)),
                      ))
                  .toList(),
            )),
      ],
    );
  }
}
