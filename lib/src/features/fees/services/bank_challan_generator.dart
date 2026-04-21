import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'dart:typed_data';


/// Data class specifically for professional Bank Challans.
class BankChallanData {
  const BankChallanData({
    required this.challanNumber,
    required this.studentName,
    required this.fatherName,
    required this.rollNo,
    required this.grNo,
    required this.className,
    required this.section,
    required this.academyName,
    required this.academyAddress,
    required this.academyPhone,
    required this.bankName,
    required this.bankBranch,
    required this.accountNumber,
    required this.feeMonth,
    required this.dueDate,
    required this.validUpto,
    required this.feeBreakdown, // Map of description -> amount
    required this.finePerDay,
    this.totalFine = 0.0,
  });

  final String challanNumber;
  final String studentName;
  final String fatherName;
  final String rollNo;
  final String grNo;
  final String className;
  final String section;
  final String academyName;
  final String academyAddress;
  final String academyPhone;
  final String bankName;
  final String bankBranch;
  final String accountNumber;
  final String feeMonth;
  final DateTime dueDate;
  final DateTime validUpto;
  final Map<String, double> feeBreakdown;
  final double finePerDay;
  final double totalFine;

  double get totalOriginal => feeBreakdown.values.fold(0, (sum, amt) => sum + amt);
  double get totalWithFine => totalOriginal + totalFine;
}

/// Generates a professional 3-copy A4 Landscape Bank Challan.
class BankChallanPdfGenerator {
  static final _currencyFmt = NumberFormat('#,##0', 'en_US');
  static final _dateFmt = DateFormat('dd-MM-yyyy');

  // Styles
  static const _thinBorder = pw.BorderSide(width: 0.5, color: PdfColors.black);

  static Future<void> generateAndPrint(BankChallanData data) async {
    final bytes = await generateBytes(data);
    await Printing.layoutPdf(
        onLayout: (format) async => bytes,
        name: 'Challan_${data.challanNumber}');
  }

  static Future<void> shareDocument(BankChallanData data) async {
    final bytes = await generateBytes(data);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Challan_${data.challanNumber}.pdf',
    );
  }

  static Future<Uint8List> generateBytes(BankChallanData data) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        build: (context) {
          return pw.Row(
            children: [
              _buildSingleCopy(data, 'School Copy', font, fontBold),
              _buildDivider(),
              _buildSingleCopy(data, 'Bank Copy', font, fontBold),
              _buildDivider(),
              _buildSingleCopy(data, 'Student Copy', font, fontBold),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildDivider() {
    return pw.Container(
      height: double.infinity,
      margin: const pw.EdgeInsets.symmetric(horizontal: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          right: pw.BorderSide(width: 0.5, color: PdfColors.black, style: pw.BorderStyle.dashed),
        ),
      ),
    );
  }

  static pw.Widget _buildSingleCopy(
    BankChallanData data,
    String copyLabel,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Header: Copy Label
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                copyLabel.toUpperCase(),
                style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.grey700),
              ),
            ),
            pw.SizedBox(height: 5),

            // School Header
            pw.Row(
              children: [
                // Logo placeholder
                pw.Container(
                  width: 35,
                  height: 35,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 0.5),
                  ),
                  child: pw.Center(child: pw.Text('LOGO', style: const pw.TextStyle(fontSize: 6))),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        data.academyName.toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: fontBold, fontSize: 11),
                      ),
                      pw.Text(
                        data.academyAddress,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: font, fontSize: 7),
                      ),
                      pw.Text(
                        'Ph: ${data.academyPhone}',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(font: font, fontSize: 7),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 10),

            // Bank Info Section
            pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    data.bankName,
                    style: pw.TextStyle(font: fontBold, fontSize: 10),
                  ),
                  pw.Text(
                    'Branch: ${data.bankBranch}',
                    style: pw.TextStyle(font: font, fontSize: 8),
                  ),
                  pw.Text(
                    'A/C No: ${data.accountNumber}',
                    style: pw.TextStyle(font: fontBold, fontSize: 9),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 12),

            // Student Info Block
            _infoLine('Challan No.', data.challanNumber, fontBold, font),
            _infoLine('Fee Month', data.feeMonth, fontBold, font),
            _infoLine('Due Date', _dateFmt.format(data.dueDate), fontBold, font),
            pw.SizedBox(height: 8),
            _infoLine('Student Name', data.studentName, fontBold, font),
            _infoLine('Father Name', data.fatherName, fontBold, font),

            pw.Row(
              children: [
                pw.Expanded(child: _infoLine('Class', data.className, fontBold, font)),
                pw.Expanded(child: _infoLine('Section', data.section, fontBold, font)),
              ],
            ),

            pw.SizedBox(height: 12),

            // Fee Table
            pw.Table(
              border: pw.TableBorder.all(width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _tableCell('Fee Description', fontBold, isHeader: true),
                    _tableCell('Amount', fontBold, isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                ...data.feeBreakdown.entries.map((e) => pw.TableRow(
                      children: [
                        _tableCell(e.key, font),
                        _tableCell(_currencyFmt.format(e.value), font, align: pw.TextAlign.right),
                      ],
                    )),
                // Fill remaining rows to maintain consistent height
                for (var i = data.feeBreakdown.length; i < 6; i++)
                  pw.TableRow(
                    children: [
                      _tableCell('', font),
                      _tableCell('', font),
                    ],
                  ),
              ],
            ),

            // Totals section - Professional Structured Layout
            pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
              ),
              child: pw.Column(
                children: [
                  _summaryRow('Total Payable (Within Due Date)', data.totalOriginal, fontBold),
                  pw.Divider(height: 0, thickness: 0.2),
                  _summaryRow('Late Fee Fine (After Due Date)', data.totalFine, font),
                  pw.Container(
                    color: PdfColors.grey200,
                    child: _summaryRow('Total Payable (After Due Date)', data.totalWithFine, fontBold, isTotal: true),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 10),

            // Note Section
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Note:', style: pw.TextStyle(font: fontBold, fontSize: 7)),
                pw.Container(
                  height: 25,
                  width: double.infinity,
                  decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                ),
              ],
            ),

            pw.SizedBox(height: 10),

            // Signature Box
            pw.Container(
              height: 45,
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Divider(thickness: 0.5, color: PdfColors.black),
                  pw.Text('Bank Stamp and Signature', style: pw.TextStyle(font: font, fontSize: 7)),
                ],
              ),
            ),

            pw.SizedBox(height: 8),

            // Footer / Terms
            pw.Container(
              padding: const pw.EdgeInsets.all(3),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.5),
                color: PdfColors.grey50,
              ),
              child: pw.Column(
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(2),
                    margin: const pw.EdgeInsets.only(bottom: 2),
                    decoration: const pw.BoxDecoration(color: PdfColors.black),
                    child: pw.Text(
                      'ANY CORRECTION / OVERWRITING IS INVALID',
                      style: pw.TextStyle(font: fontBold, fontSize: 6, color: PdfColors.white),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Text(
                    '1. Fees non-refundable.  2. Duplicate voucher charges apply.  3. Valid upto ${_dateFmt.format(data.validUpto)}.',
                    style: pw.TextStyle(font: font, fontSize: 6),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _infoLine(String label, String value, pw.Font labelFont, pw.Font valueFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        children: [
          pw.Text('$label: ', style: pw.TextStyle(font: labelFont, fontSize: 8)),
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
              ),
              child: pw.Text(value, style: pw.TextStyle(font: valueFont, fontSize: 8)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableCell(String text, pw.Font font,
      {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      height: 18, // Enforces uniform row height
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      alignment: align == pw.TextAlign.right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        maxLines: 1,
        style: pw.TextStyle(
          font: font,
          fontSize: 8, // Uniform font size for fee section
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, double amount, pw.Font font, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: isTotal ? 8 : 7)),
          pw.Text(
            'Rs. ${_currencyFmt.format(amount)}',
            style: pw.TextStyle(font: font, fontSize: isTotal ? 8.5 : 7),
          ),
        ],
      ),
    );
  }
}
