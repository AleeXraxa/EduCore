import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/fees/models/document_settings.dart';
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
    this.iban,
    this.accountTitle = '',
    required this.feeMonth,
    required this.dueDate,
    required this.validUpto,
    required this.feeBreakdown, // Map of description -> amount
    required this.finePerDay,
    this.totalFine = 0.0,
    this.settings = const DocumentSettings(),
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
  final String? iban;
  final String accountTitle;
  final String feeMonth;
  final DateTime dueDate;
  final DateTime validUpto;
  final Map<String, double> feeBreakdown;
  final double finePerDay;
  final double totalFine;
  final DocumentSettings settings;

  double get totalOriginal =>
      feeBreakdown.values.fold(0, (sum, amt) => sum + amt);
  double get totalWithFine => totalOriginal + totalFine;

  BankChallanData copyWith({DocumentSettings? settings}) {
    return BankChallanData(
      challanNumber: challanNumber,
      studentName: studentName,
      fatherName: fatherName,
      rollNo: rollNo,
      grNo: grNo,
      className: className,
      section: section,
      academyName: academyName,
      academyAddress: academyAddress,
      academyPhone: academyPhone,
      bankName: bankName,
      bankBranch: bankBranch,
      accountNumber: accountNumber,
      iban: iban,
      accountTitle: accountTitle,
      feeMonth: feeMonth,
      dueDate: dueDate,
      validUpto: validUpto,
      feeBreakdown: feeBreakdown,
      finePerDay: finePerDay,
      totalFine: totalFine,
      settings: settings ?? this.settings,
    );
  }
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
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

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

  static pw.Widget _buildHeader(BankChallanData data, String copyName, pw.Font fontBold, pw.Font font) {
    return pw.Column(
      children: [
        if (data.settings.challanSettings.showLogo) ...[
          pw.Container(
            width: 45,
            height: 45,
            decoration: const pw.BoxDecoration(
              color: PdfColors.grey100,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                data.academyName.isNotEmpty
                    ? data.academyName[0].toUpperCase()
                    : '?',
                style: pw.TextStyle(font: fontBold, fontSize: 18),
              ),
            ),
          ),
          pw.SizedBox(height: 8),
        ],
        if (data.settings.challanSettings.showInstituteName)
          pw.Text(
            data.academyName.toUpperCase(),
            style: pw.TextStyle(font: fontBold, fontSize: 13),
            textAlign: pw.TextAlign.center,
          ),
        if (data.settings.challanSettings.showAddress)
          pw.Text(
            data.academyAddress,
            style: pw.TextStyle(font: font, fontSize: 7),
            textAlign: pw.TextAlign.center,
          ),
        pw.SizedBox(height: 10),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          child: pw.Text(
            copyName.toUpperCase(),
            style: pw.TextStyle(font: fontBold, fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildBankSection(BankChallanData data, pw.Font fontBold, pw.Font font) {
    final b = data.settings.bankDetails;
    final bankName = b.bankName.isNotEmpty ? b.bankName : data.bankName;
    final branch = b.branchName.isNotEmpty ? b.branchName : data.bankBranch;
    final accNo = b.accountNumber.isNotEmpty ? b.accountNumber : data.accountNumber;
    final title = b.accountTitle.isNotEmpty ? b.accountTitle : data.academyName;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(bankName, style: pw.TextStyle(font: fontBold, fontSize: 10)),
          pw.Text(branch, style: pw.TextStyle(font: font, fontSize: 8)),
          pw.SizedBox(height: 4),
          _bankRow('Title', title, fontBold, font),
          _bankRow('A/C #', accNo, fontBold, font),
          if (b.iban != null && b.iban!.isNotEmpty)
            _bankRow('IBAN', b.iban!, fontBold, font),
        ],
      ),
    );
  }

  static pw.Widget _buildStudentSection(BankChallanData data, pw.Font fontBold, pw.Font font) {
    final s = data.settings.challanSettings;
    if (!s.showStudentInfo) return pw.SizedBox.shrink();

    return pw.Column(
      children: [
        _infoRow('Challan No', data.challanNumber, fontBold, font),
        _infoRow('Student Name', data.studentName, fontBold, font),
        if (s.showFatherName)
          _infoRow('Father Name', data.fatherName, fontBold, font),
        if (s.showClassSection) ...[
          _infoRow('Class', data.className, fontBold, font),
          _infoRow('Section', data.section, fontBold, font),
        ],
        _infoRow('Roll No / GR', '${data.rollNo} / ${data.grNo}', fontBold, font),
        _infoRow('Fee Month', data.feeMonth, fontBold, font),
      ],
    );
  }

  static pw.Widget _buildDatesSection(BankChallanData data, pw.Font fontBold, pw.Font font) {
    if (!data.settings.challanSettings.showDueDates) return pw.SizedBox.shrink();

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _dateField('Issue Date', DateTime.now(), fontBold, font),
        _dateField('Due Date', data.dueDate, fontBold, font, isImportant: true),
      ],
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
            _buildHeader(data, copyLabel, fontBold, font),
            pw.SizedBox(height: 10),
            _buildBankSection(data, fontBold, font),
            pw.SizedBox(height: 10),
            _buildStudentSection(data, fontBold, font),
            _buildDatesSection(data, fontBold, font),
            pw.SizedBox(height: 10),

            // Fee Table
            if (data.settings.challanSettings.showFeeTable)
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
                ],
              ),
            pw.SizedBox(height: 10),

            // Totals section - Professional Structured Layout
            if (data.settings.challanSettings.showFeeTable)
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                ),
                child: pw.Column(
                  children: [
                    _summaryRow('Total Current Fee', data.totalOriginal, font),
                    if (data.settings.challanSettings.showFineDetails)
                      _summaryRow('Fine after Due Date', data.totalFine, font),
                    pw.Container(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      child: _summaryRow('TOTAL PAYABLE', data.totalWithFine, fontBold, isTotal: true),
                    ),
                  ],
                ),
              ),
            pw.SizedBox(height: 12),

            // Footer Note
            if (data.settings.challanSettings.footerNote.isNotEmpty)
              pw.Text(
                data.settings.challanSettings.footerNote,
                style: pw.TextStyle(font: font, fontSize: 6, color: PdfColors.grey700),
                textAlign: pw.TextAlign.justify,
              ),

            pw.Spacer(),

            // Signatures
            if (data.settings.challanSettings.showSignatureBox)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _sigLine('Cashier', font),
                  _sigLine('Authorized Sig', font),
                ],
              ),

            pw.Spacer(),

            // Stamp Box
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

  static pw.Widget _infoRow(String label, String value, pw.Font labelFont, pw.Font valueFont) {
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

  static pw.Widget _bankRow(String label, String value, pw.Font fontBold, pw.Font font) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('$label: ', style: pw.TextStyle(font: fontBold, fontSize: 8)),
        pw.Expanded(
          child: pw.Text(value, style: pw.TextStyle(font: font, fontSize: 8)),
        ),
      ],
    );
  }

  static pw.Widget _dateField(String label, DateTime date, pw.Font fontBold, pw.Font font,
      {bool isImportant = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 7)),
        pw.Text(
          _dateFmt.format(date),
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 8,
            color: isImportant ? PdfColors.red : PdfColors.black,
          ),
        ),
      ],
    );
  }

  static pw.Widget _sigLine(String label, pw.Font font) {
    return pw.Column(
      children: [
        pw.Container(
          width: 70,
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 7)),
      ],
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
