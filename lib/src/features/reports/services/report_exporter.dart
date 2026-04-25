import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xl;
import 'package:educore/src/features/reports/models/report_config.dart';
import 'package:educore/src/features/settings/models/global_settings.dart';
import 'package:educore/src/core/services/institute_service.dart';

/// Centralizes PDF and Excel export for all report types.
class ReportExporter {
  ReportExporter._();

  static Future<void> exportPdf({
    required String title,
    required List<String> headers,
    required List<ReportRow> rows,
    required Academy? academy,
    GlobalSettings? settings,
    ReportFilters? filters,
  }) async {
    final pdf = _buildPdf(
      title: title,
      headers: headers,
      rows: rows,
      academy: academy,
      settings: settings,
      filters: filters,
    );
    final bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: '${title.replaceAll(' ', '_')}_${_dateStamp()}.pdf',
    );
  }

  static Future<void> printReport({
    required String title,
    required List<String> headers,
    required List<ReportRow> rows,
    required Academy? academy,
    GlobalSettings? settings,
    ReportFilters? filters,
  }) async {
    final pdf = _buildPdf(
      title: title,
      headers: headers,
      rows: rows,
      academy: academy,
      settings: settings,
      filters: filters,
    );
    final bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: '${title.replaceAll(' ', '_')}_${_dateStamp()}.pdf',
    );
  }

  static pw.Document _buildPdf({
    required String title,
    required List<String> headers,
    required List<ReportRow> rows,
    required Academy? academy,
    GlobalSettings? settings,
    ReportFilters? filters,
  }) {
    final pdf = pw.Document();
    final now = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    
    // Theme Colors
    final primaryColor = PdfColor.fromHex('#1565C0');
    final headerBg = PdfColor.fromHex('#F8FAFF');
    final borderColor = PdfColor.fromHex('#E2E8F0');
    final textDark = PdfColor.fromHex('#1E293B');
    final textMuted = PdfColor.fromHex('#64748B');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildPdfHeader(
          academy: academy,
          settings: settings,
          title: title,
          primaryColor: primaryColor,
          textMuted: textMuted,
          pageNumber: context.pageNumber,
          pagesCount: context.pagesCount,
        ),
        footer: (context) => _buildPdfFooter(
          font: pw.Font.helvetica(),
          textMuted: textMuted,
          borderColor: borderColor,
        ),
        build: (context) {
          return [
            // Filter summary section
            if (filters != null) _buildFilterSummary(filters, textMuted, borderColor),
            pw.SizedBox(height: 12),
            
            // Statistics Bar
            _buildStatsBar(rows.length, primaryColor, headerBg, borderColor),
            pw.SizedBox(height: 16),

            // Main Table
            pw.TableHelper.fromTextArray(
              headers: headers.map((h) => h.toUpperCase()).toList(),
              data: rows.map((r) => headers.map((h) => r[h]?.toString() ?? '').toList()).toList(),
              border: pw.TableBorder.all(color: borderColor, width: 0.5),
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: primaryColor),
              cellStyle: pw.TextStyle(fontSize: 8.5, color: textDark),
              rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
              oddRowDecoration: pw.BoxDecoration(color: headerBg),
              headerHeight: 30,
              cellHeight: 26,
              cellAlignments: {
                for (int i = 0; i < headers.length; i++) i: pw.Alignment.centerLeft,
              },
            ),
          ];
        },
      ),
    );
    return pdf;
  }

  static pw.Widget _buildPdfHeader({
    required Academy? academy,
    required GlobalSettings? settings,
    required String title,
    required PdfColor primaryColor,
    required PdfColor textMuted,
    required int pageNumber,
    required int pagesCount,
  }) {
    final name = settings?.appName.isNotEmpty == true ? settings!.appName : (academy?.name ?? 'EDUCORE ERP');
    final address = settings?.address.isNotEmpty == true ? settings!.address : (academy?.address ?? '');
    final email = settings?.supportEmail.isNotEmpty == true ? settings!.supportEmail : (academy?.email ?? '');
    final phone = settings?.supportPhone.isNotEmpty == true ? settings!.supportPhone : (academy?.phone ?? '');

    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primaryColor, width: 2)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Logo / Initials
          pw.Container(
            width: 60,
            height: 60,
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Text(
                name.isNotEmpty == true ? name[0].toUpperCase() : 'E',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 16),
          // Academy Details
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  name.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
                pw.SizedBox(height: 4),
                if (address.isNotEmpty)
                  pw.Text(
                    address,
                    style: pw.TextStyle(fontSize: 9, color: textMuted),
                  ),
                pw.Row(
                  children: [
                    if (phone.isNotEmpty)
                      pw.Text('Phone: $phone', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                    if (phone.isNotEmpty && email.isNotEmpty)
                      pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 8), child: pw.Text('|', style: pw.TextStyle(fontSize: 8, color: textMuted))),
                    if (email.isNotEmpty)
                      pw.Text('Email: $email', style: pw.TextStyle(fontSize: 8, color: textMuted)),
                  ],
                ),
              ],
            ),
          ),
          // Report Info
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  title.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Page $pageNumber of $pagesCount', style: pw.TextStyle(fontSize: 8, color: textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFilterSummary(ReportFilters filters, PdfColor textMuted, PdfColor borderColor) {
    final items = <String>[];
    if (filters.className != null) items.add('Class: ${filters.className}');
    if (filters.studentName != null) items.add('Student: ${filters.studentName}');
    if (filters.status != null) items.add('Status: ${filters.status}');
    if (filters.startDate != null && filters.endDate != null) {
      items.add('Range: ${DateFormat('dd/MM/yy').format(filters.startDate!)} - ${DateFormat('dd/MM/yy').format(filters.endDate!)}');
    } else if (filters.month != null) {
      items.add('Month: ${filters.month}');
    }

    if (items.isEmpty) return pw.SizedBox.shrink();

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: borderColor, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Text('FILTERS APPLIED: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textMuted)),
          pw.Text(items.join('  |  '), style: pw.TextStyle(fontSize: 8, color: textMuted)),
        ],
      ),
    );
  }

  static pw.Widget _buildStatsBar(int count, PdfColor primaryColor, PdfColor bg, PdfColor border) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        color: bg,
        border: pw.Border.all(color: border, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        children: [
          pw.Text('TOTAL RECORDS: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
          pw.Text('$count', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: primaryColor)),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFooter({
    required pw.Font font,
    required PdfColor textMuted,
    required PdfColor borderColor,
  }) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 20),
        pw.Divider(color: borderColor, thickness: 0.5),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'EduCore Powered By TryUnity Solutions',
                  style: pw.TextStyle(fontSize: 8, font: font, fontWeight: pw.FontWeight.bold, color: textMuted),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Phone: +92-302-3476605  |  Email: dev-alee@outlook.com',
                  style: pw.TextStyle(fontSize: 7, font: font, color: textMuted),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'System Generated Report',
                  style: pw.TextStyle(fontSize: 6, font: font, fontStyle: pw.FontStyle.italic, color: textMuted),
                ),
                pw.Text(
                  'Generated on: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 7, font: font, color: textMuted),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ─── Excel ────────────────────────────────────────────────────────────────

  static Future<void> exportExcel({
    required String title,
    required List<String> headers,
    required List<ReportRow> rows,
    String academyName = 'EduCore ERP',
  }) async {
    final workbook = xl.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = title.substring(0, title.length.clamp(0, 31));

    // Header row styling
    final headerStyle = workbook.styles.add('HeaderStyle');
    headerStyle.bold = true;
    headerStyle.backColor = '#2563EB';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.fontSize = 11;
    headerStyle.wrapText = false;

    // Title
    sheet.getRangeByName('A1').setText('$academyName — $title');
    sheet.getRangeByName('A1').cellStyle.bold = true;
    sheet.getRangeByName('A1').cellStyle.fontSize = 13;
    sheet.getRangeByName('A2').setText(
        'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}');
    sheet.getRangeByName('A2').cellStyle.fontColor = '#64748B';

    // Column headers (row 4)
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(4, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle = headerStyle;
      sheet.setColumnWidthInPixels(i + 1, 140);
    }

    // Data rows
    for (int r = 0; r < rows.length; r++) {
      for (int c = 0; c < headers.length; c++) {
        final val = rows[r][headers[c]]?.toString() ?? '';
        final cell = sheet.getRangeByIndex(r + 5, c + 1);
        // Try numeric
        final numeric = double.tryParse(val);
        if (numeric != null) {
          cell.setNumber(numeric);
        } else {
          cell.setText(val);
        }
        // Alternate row colour
        if (r % 2 == 1) {
          cell.cellStyle.backColor = '#F1F5F9';
        }
      }
    }

    // Save
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final data = Uint8List.fromList(bytes);
    await Printing.layoutPdf(
      onLayout: (_) async => data,
      name: '${title.replaceAll(' ', '_')}_${_dateStamp()}.xlsx',
    );
  }

  static String _dateStamp() =>
      DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
}
