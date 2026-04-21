import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:educore/src/features/fees/models/fee.dart';
import 'package:educore/src/features/fees/models/fee_transaction.dart';
import 'package:educore/src/features/fees/models/document_settings.dart';

/// Data bag passed to the PDF generator (avoids passing raw models).
class FeeDocumentData {
  const FeeDocumentData({
    required this.fee,
    required this.transactions,
    required this.academyName,
    required this.academyAddress,
    required this.academyPhone,
    required this.academyEmail,
    required this.documentMode, // 'challan' | 'receipt'
    this.challanNumber,
    this.receiptNumber,
    this.fatherName,
    this.generatedAt,
    this.settings = const DocumentSettings(),
  });

  final Fee fee;
  final List<FeeTransaction> transactions;
  final String academyName;
  final String academyAddress;
  final String academyPhone;
  final String academyEmail;
  final String documentMode;
  final String? challanNumber;
  final String? receiptNumber;
  final String? fatherName;
  final DateTime? generatedAt;
  final DocumentSettings settings;
}

/// Generates professional A4 PDF documents for fee challans and receipts.
class FeePdfGenerator {
  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF1565C0);
  static const PdfColor _accentColor = PdfColor.fromInt(0xFF0D47A1);
  static const PdfColor _successColor = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor _warningColor = PdfColor.fromInt(0xFFE65100);
  static const PdfColor _lightBg = PdfColor.fromInt(0xFFF5F8FF);
  static const PdfColor _tableBg = PdfColor.fromInt(0xFFF8FAFF);
  static const PdfColor _borderColor = PdfColor.fromInt(0xFFBBDEFB);
  static const PdfColor _textDark = PdfColor.fromInt(0xFF1A237E);
  static const PdfColor _textMuted = PdfColor.fromInt(0xFF546E7A);
  static const PdfColor _white = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor _whiteMuted = PdfColor.fromInt(0xE6FFFFFF);

  static final _currencyFmt = NumberFormat('#,##0.00', 'en_US');
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');

  // ── Public API ────────────────────────────────────────────────────────────

  static Future<void> printDocument(FeeDocumentData data) async {
    final bytes = await generateBytes(data);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<Uint8List> generateBytes(FeeDocumentData data) async {
    final doc = await _buildDocument(data);
    return doc.save();
  }

  static Future<void> shareDocument(FeeDocumentData data) async {
    final bytes = await generateBytes(data);
    final docNumber = data.documentMode == 'challan'
        ? (data.challanNumber ?? 'CHALLAN')
        : (data.receiptNumber ?? 'RECEIPT');
    await Printing.sharePdf(bytes: bytes, filename: '$docNumber.pdf');
  }

  // ── Builder ───────────────────────────────────────────────────────────────

  static Future<pw.Document> _buildDocument(FeeDocumentData data) async {
    final doc = pw.Document(
      title: data.documentMode == 'challan' ? 'Fee Challan' : 'Fee Receipt',
      author: data.academyName,
    );

    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontBlack = await PdfGoogleFonts.nunitoExtraBold();

    final theme = pw.ThemeData.withFont(base: font, bold: fontBold);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        theme: theme,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _buildHeader(data, fontBlack, fontBold, font),
            pw.SizedBox(height: 24),
            _buildDocumentBanner(data, fontBlack, fontBold),
            pw.SizedBox(height: 20),
            _buildStudentInfoSection(data, fontBold, font),
            pw.SizedBox(height: 14),
            _buildFeeDetailsTable(data, fontBold, font),
            if (data.documentMode == 'receipt' && data.transactions.isNotEmpty)
              pw.Column(
                children: [
                  pw.SizedBox(height: 14),
                  _buildTransactionSection(data, fontBold, font),
                ],
              ),
            pw.SizedBox(height: 14),
            _buildAmountSummary(data, fontBlack, fontBold, font),
            pw.SizedBox(height: 14),
            _buildNoteSection(data, font),
            pw.Spacer(),
            _buildFooterBranding(data, font, fontBold),
          ],
        ),
      ),
    );

    return doc;
  }

  // ── Header ────────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader(
    FeeDocumentData data,
    pw.Font fontBlack,
    pw.Font fontBold,
    pw.Font font,
  ) {
    final dynamic s = data.documentMode == 'challan'
        ? data.settings.challanSettings
        : data.settings.receiptSettings;

    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: const pw.BoxDecoration(
        color: _primaryColor,
        borderRadius: pw.BorderRadius.only(
          topLeft: pw.Radius.circular(12),
          topRight: pw.Radius.circular(12),
        ),
      ),
      child: pw.Row(
        children: [
          if (s.showLogo) ...[
            pw.Container(
              width: 70,
              height: 70,
              decoration: const pw.BoxDecoration(
                color: _white,
                shape: pw.BoxShape.circle,
              ),
              child: pw.Center(
                child: pw.Text(
                  data.academyName.substring(0, 1).toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 32,
                    font: fontBlack,
                    color: _primaryColor,
                  ),
                ),
              ),
            ),
            pw.SizedBox(width: 24),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (s.showInstituteName)
                  pw.Text(
                    data.academyName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 22,
                      font: fontBlack,
                      color: _white,
                      letterSpacing: 1.2,
                    ),
                  ),
                pw.SizedBox(height: 4),
                if (s.showAddress && data.academyAddress.isNotEmpty)
                  pw.Text(
                    data.academyAddress,
                    style: pw.TextStyle(
                      fontSize: 10,
                      font: font,
                      color: _whiteMuted,
                    ),
                  ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    if (s.showPhone && data.academyPhone.isNotEmpty)
                      pw.Text(
                        'Phone: ${data.academyPhone}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: font,
                          color: _whiteMuted,
                        ),
                      ),
                    if (s.showPhone &&
                        data.academyPhone.isNotEmpty &&
                        data.academyEmail.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8),
                        child: pw.Text(
                          '|',
                          style: pw.TextStyle(color: _white, fontSize: 10),
                        ),
                      ),
                    if (data.academyEmail.isNotEmpty)
                      pw.Text(
                        'Email: ${data.academyEmail}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          font: font,
                          color: _whiteMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Document Banner ───────────────────────────────────────────────────────

  static pw.Widget _buildDocumentBanner(
    FeeDocumentData data,
    pw.Font fontBlack,
    pw.Font fontBold,
  ) {
    final isChallan = data.documentMode == 'challan';
    final bannerColor = isChallan ? _warningColor : _successColor;
    final title = isChallan ? 'FEE CHALLAN' : 'PAYMENT RECEIPT';
    final docNum = isChallan
        ? (data.challanNumber ?? '---')
        : (data.receiptNumber ?? '---');
    final label = isChallan ? 'Challan No.' : 'Receipt No.';

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _lightBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _borderColor, width: 1),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 4,
                  height: 40,
                  decoration: pw.BoxDecoration(
                    color: bannerColor,
                    borderRadius: pw.BorderRadius.circular(2),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      title,
                      style: pw.TextStyle(
                        font: fontBlack,
                        fontSize: 20,
                        color: bannerColor,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.Text(
                      isChallan
                          ? 'Payment Request — Please pay by due date'
                          : 'Official Payment Confirmation',
                      style: pw.TextStyle(fontSize: 10, color: _textMuted),
                    ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  label,
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 9,
                    color: _textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.Text(
                  docNum,
                  style: pw.TextStyle(
                    font: fontBlack,
                    fontSize: 16,
                    color: bannerColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _dateTimeFmt.format(data.generatedAt ?? DateTime.now()),
                  style: pw.TextStyle(fontSize: 8, color: _textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Student Info ──────────────────────────────────────────────────────────

  static pw.Widget _buildStudentInfoSection(
    FeeDocumentData data,
    pw.Font fontBold,
    pw.Font font,
  ) {
    final dynamic s = data.documentMode == 'challan'
        ? data.settings.challanSettings
        : data.settings.receiptSettings;

    if (!s.showStudentInfo) return pw.SizedBox.shrink();

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _borderColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: _infoField(
                  'Student Name',
                  data.fee.studentName ?? '',
                  fontBold,
                  font,
                ),
              ),
              if (s.showFatherName)
                pw.Expanded(
                  child: _infoField(
                    'Father Name',
                    data.fatherName ?? '',
                    fontBold,
                    font,
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              if (s.showClassSection)
                pw.Expanded(
                  child: _infoField(
                    'Class',
                    data.fee.className ?? '',
                    fontBold,
                    font,
                  ),
                ),
              pw.Expanded(
                child: _infoField('Fee Type', data.fee.title, fontBold, font),
              ),
              pw.Expanded(
                child: _infoField(
                  'Student ID',
                  data.fee.studentId,
                  fontBold,
                  font,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Fee Details Table ─────────────────────────────────────────────────────

  static pw.Widget _buildFeeDetailsTable(
    FeeDocumentData data,
    pw.Font fontBold,
    pw.Font font,
  ) {
    final fee = data.fee;
    final hasDiscount = fee.discountType != DiscountType.none;

    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _borderColor),
      ),
      child: pw.Table(
        border: pw.TableBorder(
          horizontalInside: pw.BorderSide(color: _borderColor, width: 0.5),
        ),
        columnWidths: {
          0: const pw.FlexColumnWidth(3),
          1: const pw.FlexColumnWidth(2),
        },
        children: [
          // Header
          pw.TableRow(
            decoration: pw.BoxDecoration(color: _primaryColor),
            children: [
              _tableCell('Description', fontBold, isHeader: true),
              _tableCell(
                'Amount',
                fontBold,
                isHeader: true,
                align: pw.TextAlign.right,
              ),
            ],
          ),
          // Fee row
          pw.TableRow(
            children: [
              _tableCell(fee.title, font),
              _tableCell(
                'Rs. ${_currencyFmt.format(fee.originalAmount)}',
                font,
                align: pw.TextAlign.right,
              ),
            ],
          ),
          // Discount row
          if (hasDiscount)
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _tableBg),
              children: [
                _tableCell(
                  'Discount (${fee.discountType == DiscountType.percent ? "${fee.discountValue.toStringAsFixed(0)}%" : "Flat"})',
                  font,
                  color: _successColor,
                ),
                _tableCell(
                  '- Rs. ${_currencyFmt.format(fee.discountAmount)}',
                  font,
                  align: pw.TextAlign.right,
                  color: _successColor,
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Transactions ──────────────────────────────────────────────────────────

  static pw.Widget _buildTransactionSection(
    FeeDocumentData data,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _borderColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: _lightBg,
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: pw.Text(
              'PAYMENT HISTORY',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 9,
                color: _primaryColor,
                letterSpacing: 1.2,
              ),
            ),
          ),
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: _borderColor, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _lightBg),
                children: [
                  _tableCell('Date & Time', fontBold, fontSize: 9),
                  _tableCell('Method', fontBold, fontSize: 9),
                  _tableCell(
                    'Amount',
                    fontBold,
                    fontSize: 9,
                    align: pw.TextAlign.right,
                  ),
                  _tableCell(
                    'Receipt No.',
                    fontBold,
                    fontSize: 9,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
              ...data.transactions.map(
                (txn) => pw.TableRow(
                  children: [
                    _tableCell(
                      _dateTimeFmt.format(txn.collectedAt),
                      font,
                      fontSize: 9,
                    ),
                    _tableCell(txn.methodLabel, font, fontSize: 9),
                    _tableCell(
                      'Rs. ${_currencyFmt.format(txn.amount)}',
                      font,
                      fontSize: 9,
                      align: pw.TextAlign.right,
                    ),
                    _tableCell(
                      txn.receiptNumber ?? '---',
                      font,
                      fontSize: 8,
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Amount Summary ────────────────────────────────────────────────────────

  static pw.Widget _buildAmountSummary(
    FeeDocumentData data,
    pw.Font fontBlack,
    pw.Font fontBold,
    pw.Font font,
  ) {
    final fee = data.fee;
    final isChallan = data.documentMode == 'challan';
    final dynamic s = isChallan
        ? data.settings.challanSettings
        : data.settings.receiptSettings;
    final totalColor = isChallan ? _warningColor : _successColor;

    if (isChallan && !s.showFeeTable) return pw.SizedBox.shrink();
    if (!isChallan && !s.showFeeBreakdown) return pw.SizedBox.shrink();

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 260,
          decoration: pw.BoxDecoration(
            color: _lightBg,
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: _borderColor),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              children: [
                _summaryRow(
                  'Original Amount',
                  'Rs. ${_currencyFmt.format(fee.originalAmount)}',
                  fontBold,
                  font,
                ),
                if (fee.discountAmount > 0)
                  _summaryRow(
                    'Discount Applied',
                    '- Rs. ${_currencyFmt.format(fee.discountAmount)}',
                    fontBold,
                    font,
                    valueColor: _successColor,
                  ),
                if (fee.paidAmount > 0 && !isChallan && s.showPaymentDetails)
                  _summaryRow(
                    'Amount Paid',
                    'Rs. ${_currencyFmt.format(fee.paidAmount)}',
                    fontBold,
                    font,
                    valueColor: _successColor,
                  ),
                pw.Divider(color: _borderColor, height: 16),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      isChallan ? 'TOTAL DUE' : 'BALANCE DUE',
                      style: pw.TextStyle(
                        font: fontBlack,
                        fontSize: 12,
                        color: totalColor,
                      ),
                    ),
                    pw.Text(
                      'Rs. ${_currencyFmt.format(fee.remainingAmount)}',
                      style: pw.TextStyle(
                        font: fontBlack,
                        fontSize: 16,
                        color: totalColor,
                      ),
                    ),
                  ],
                ),
                if (fee.status == FeeStatus.paid)
                  pw.Container(
                    margin: const pw.EdgeInsets.only(top: 8),
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _successColor,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text(
                      'FULLY PAID',
                      style: pw.TextStyle(
                        font: fontBlack,
                        fontSize: 11,
                        color: _white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Note Section ──────────────────────────────────────────────────────────

  static pw.Widget _buildNoteSection(FeeDocumentData data, pw.Font font) {
    final dynamic s = data.documentMode == 'challan'
        ? data.settings.challanSettings
        : data.settings.receiptSettings;
    final String note = data.documentMode == 'challan'
        ? data.settings.challanSettings.footerNote
        : data.settings.receiptSettings.footerNote;

    if (note.isEmpty) {
      if (data.documentMode == 'receipt') return pw.SizedBox.shrink();

      return pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFFFFF3E0),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'PAYMENT INSTRUCTIONS',
              style: pw.TextStyle(
                fontSize: 9,
                font: font,
                fontWeight: pw.FontWeight.bold,
                color: const PdfColor.fromInt(0xFFE65100),
              ),
            ),
            pw.SizedBox(height: 6),
            _noteBullet(
              'Please pay the exact amount mentioned above before the due date.',
              font,
            ),
            _noteBullet('Retain this challan as your payment reference.', font),
            _noteBullet(
              'Payment can be made in Cash, Bank Transfer, or Online.',
              font,
            ),
            _noteBullet(
              'Contact the institute office for any discrepancies.',
              font,
            ),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _lightBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _borderColor, width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'NOTE',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            note,
            style: pw.TextStyle(fontSize: 9, font: font, color: _textDark),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  static pw.Widget _buildFooterBranding(
    FeeDocumentData data,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final dynamic s = data.documentMode == 'challan'
        ? data.settings.challanSettings
        : data.settings.receiptSettings;

    return pw.Column(
      children: [
        if (s.showSignature) ...[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                children: [
                  pw.Container(
                    width: 150,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    data.documentMode == 'challan'
                        ? 'Authorized Signature'
                        : 'Collected By',
                    style: pw.TextStyle(
                      fontSize: 8,
                      font: font,
                      color: _textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
        ],
        pw.Divider(color: _borderColor, thickness: 0.5),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated: ${_dateTimeFmt.format(data.generatedAt ?? DateTime.now())}',
              style: pw.TextStyle(fontSize: 7, font: font, color: _textMuted),
            ),
            pw.Column(
              children: [
                pw.Text(
                  'System generated document — No signature required',
                  style: pw.TextStyle(
                    fontSize: 7,
                    font: font,
                    color: _textMuted,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'EduCore — Powered by TryUnity Solutions',
                  style: pw.TextStyle(
                    fontSize: 7,
                    font: font,
                    fontWeight: pw.FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                pw.Text(
                  'Email: infotryunity@gmail.com | Phone: +92-302-3476605',
                  style: pw.TextStyle(
                    fontSize: 7,
                    font: font,
                    color: _textMuted,
                  ),
                ),
              ],
            ),
            pw.Text(
              data.academyName,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 8,
                color: _textMuted,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'EduCore — Powered by TryUnity Solutions',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 7,
                color: _primaryColor,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Email: infotryunity@gmail.com   |   Phone: +92-302-3476605',
              style: pw.TextStyle(font: font, fontSize: 7, color: _textMuted),
            ),
          ],
        ),
      ],
    );
  }

  // ── Reusable Cells ────────────────────────────────────────────────────────

  static pw.Widget _tableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
    double fontSize = 10,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          font: font,
          fontSize: fontSize,
          color: color ?? (isHeader ? _white : _textDark),
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _infoField(
    String label,
    String value,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: pw.TextStyle(
            font: font,
            fontSize: 7,
            color: _textMuted,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(font: fontBold, fontSize: 10, color: _textDark),
        ),
      ],
    );
  }

  static pw.Widget _noteBullet(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '• ',
            style: pw.TextStyle(font: font, fontSize: 9, color: _primaryColor),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(
                font: font,
                fontSize: 8.5,
                color: _textDark,
                lineSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoRow(
    String label,
    String value,
    pw.Font fontBold,
    pw.Font font,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 9,
                color: _textMuted,
              ),
            ),
          ),
          pw.Text(': ', style: pw.TextStyle(fontSize: 9, color: _textMuted)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 9,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(
    String label,
    String value,
    pw.Font fontBold,
    pw.Font font, {
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(font: font, fontSize: 10, color: _textMuted),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 10,
              color: valueColor ?? _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty) return 'I';
    if (words.length == 1) return words[0][0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  static String _feeTypeLabel(FeeType type) {
    return switch (type) {
      FeeType.admission => 'Admission Fee',
      FeeType.monthly => 'Monthly Fee',
      FeeType.package => 'Package Fee',
      FeeType.other => 'Miscellaneous Fee',
    };
  }
}
