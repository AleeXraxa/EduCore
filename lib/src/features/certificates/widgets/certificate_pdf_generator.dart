import 'dart:typed_data';
import 'package:educore/src/features/certificates/models/certificate.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CertificatePdfGenerator {
  static Future<Uint8List> generate({
    required Certificate certificate,
    required String instituteName,
    String? instituteLogoUrl,
    String? backgroundUrl,
  }) async {
    final pdf = pw.Document();

    const primaryColor = PdfColor.fromInt(0xFF4A5568); // Slate blue-gray
    const secondaryColor = PdfColor.fromInt(0xFF718096);
    const bgColor = PdfColor.fromInt(0xFFF7FAFC);

    final fontSansRegular = await PdfGoogleFonts.interRegular();
    final fontSansBold = await PdfGoogleFonts.interBold();
    final fontSignature = await PdfGoogleFonts.dancingScriptRegular();

    pw.ImageProvider? background;
    if (backgroundUrl != null && backgroundUrl.isNotEmpty) {
      try {
        background = await networkImage(backgroundUrl);
      } catch (_) {}
    }

    pw.ImageProvider? logoImage;
    if (instituteLogoUrl != null && instituteLogoUrl.isNotEmpty) {
      try {
        logoImage = await networkImage(instituteLogoUrl);
      } catch (_) {}
    }

    // Create jagged seal (starburst)
    pw.Widget buildSeal() {
      return pw.Container(
        width: 80,
        height: 80,
        child: pw.Stack(
          alignment: pw.Alignment.center,
          children: [
            // Rotated squares to make a star/jagged edge
            for (double angle in [0, 15, 30, 45, 60, 75])
              pw.Transform.rotate(
                angle: angle * 3.14159 / 180,
                child: pw.Container(
                  width: 76,
                  height: 76,
                  decoration: pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                ),
              ),
            // Inner dotted/dashed circle
            pw.Container(
              width: 64,
              height: 64,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                border: pw.Border.all(
                  color: PdfColors.white,
                  width: 1,
                  style: pw.BorderStyle.dashed,
                ),
              ),
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    '★ ★ ★',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 6),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Awarded',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                      font: fontSansRegular,
                    ),
                  ),
                  pw.Text(
                    '${certificate.issueDate.year}',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                      font: fontSansBold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '★ ★ ★',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 6),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Border corner decorations
    pw.Widget cornerDeco({bool top = true, bool left = true}) {
      return pw.Container(
        width: 30,
        height: 30,
        child: pw.Stack(
          children: [
            pw.Positioned(
              top: top ? 0 : null,
              bottom: top ? null : 0,
              left: left ? 0 : null,
              right: left ? null : 0,
              child: pw.Container(
                width: 20,
                height: 20,
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    top: top
                        ? pw.BorderSide(color: primaryColor, width: 1)
                        : pw.BorderSide.none,
                    bottom: !top
                        ? pw.BorderSide(color: primaryColor, width: 1)
                        : pw.BorderSide.none,
                    left: left
                        ? pw.BorderSide(color: primaryColor, width: 1)
                        : pw.BorderSide.none,
                    right: !left
                        ? pw.BorderSide(color: primaryColor, width: 1)
                        : pw.BorderSide.none,
                  ),
                ),
              ),
            ),
            pw.Positioned(
              top: top ? 18 : null,
              bottom: top ? null : 18,
              left: left ? 18 : null,
              right: left ? null : 18,
              child: pw.Container(
                width: 4,
                height: 4,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (pw.Context ctx) {
          return pw.FullPage(
            ignoreMargins: true,
            child: pw.Stack(
              children: [
                // Background
                pw.Positioned.fill(child: pw.Container(color: bgColor)),
                if (background != null) ...[
                  pw.Positioned.fill(
                    child: pw.Image(background!, fit: pw.BoxFit.cover),
                  ),
                  pw.Positioned.fill(
                    child: pw.Container(color: const PdfColor(1, 1, 1, 0.9)),
                  ),
                ],

                // Outer thick patterned border (simulated with multiple nested borders)
                pw.Positioned(
                  top: 15,
                  bottom: 15,
                  left: 15,
                  right: 15,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: primaryColor, width: 12),
                    ),
                  ),
                ),
                pw.Positioned(
                  top: 17,
                  bottom: 17,
                  left: 17,
                  right: 17,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.white, width: 2),
                    ),
                  ),
                ),
                pw.Positioned(
                  top: 25,
                  bottom: 25,
                  left: 25,
                  right: 25,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: primaryColor, width: 1),
                    ),
                  ),
                ),
                // Inner border
                pw.Positioned(
                  top: 35,
                  bottom: 35,
                  left: 35,
                  right: 35,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: primaryColor, width: 0.5),
                    ),
                  ),
                ),

                // Corner ornaments for inner border
                pw.Positioned(
                  top: 35,
                  left: 35,
                  child: cornerDeco(top: true, left: true),
                ),
                pw.Positioned(
                  top: 35,
                  right: 35,
                  child: cornerDeco(top: true, left: false),
                ),
                pw.Positioned(
                  bottom: 35,
                  left: 35,
                  child: cornerDeco(top: false, left: true),
                ),
                pw.Positioned(
                  bottom: 35,
                  right: 35,
                  child: cornerDeco(top: false, left: false),
                ),

                // Content
                pw.Positioned.fill(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(60),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.SizedBox(height: 10),

                        // Title
                        pw.Text(
                          'CERTIFICATE OF ${certificate.type.name.toUpperCase()}',
                          style: pw.TextStyle(
                            font: fontSansBold,
                            fontSize: 36,
                            color: primaryColor,
                            letterSpacing: 2,
                          ),
                        ),

                        pw.SizedBox(height: 15),

                        // Ornate Divider
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Container(
                              width: 80,
                              height: 0.5,
                              color: primaryColor,
                            ),
                            pw.SizedBox(width: 5),
                            pw.Container(
                              width: 4,
                              height: 4,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                border: pw.Border.all(
                                  color: primaryColor,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 5),
                            pw.Container(
                              width: 6,
                              height: 6,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                border: pw.Border.all(
                                  color: primaryColor,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 5),
                            pw.Container(
                              width: 4,
                              height: 4,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                border: pw.Border.all(
                                  color: primaryColor,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            pw.SizedBox(width: 5),
                            pw.Container(
                              width: 80,
                              height: 0.5,
                              color: primaryColor,
                            ),
                          ],
                        ),

                        pw.SizedBox(height: 35),

                        pw.Text(
                          'This is to certify that',
                          style: pw.TextStyle(
                            font: fontSansRegular,
                            fontSize: 16,
                            color: primaryColor,
                          ),
                        ),

                        pw.SizedBox(height: 15),

                        pw.Text(
                          certificate.studentName,
                          style: pw.TextStyle(
                            font: fontSignature,
                            fontSize: 64,
                            color: primaryColor,
                          ),
                        ),

                        pw.SizedBox(height: 20),

                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 80,
                          ),
                          child: pw.Text(
                            _processBody(certificate),
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              font: fontSansRegular,
                              fontSize: 14,
                              color: primaryColor,
                              lineSpacing: 5,
                            ),
                          ),
                        ),

                        pw.Spacer(),

                        // 3-Column Footer
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            // Left Signature
                            pw.Expanded(
                              child: pw.Column(
                                children: [
                                  pw.Text(
                                    certificate.authorizedSignatory,
                                    style: pw.TextStyle(
                                      font: fontSansBold,
                                      fontSize: 14,
                                      color: primaryColor,
                                    ),
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    'Authorized Signatory',
                                    style: pw.TextStyle(
                                      font: fontSansRegular,
                                      fontSize: 12,
                                      color: secondaryColor,
                                    ),
                                  ),
                                  pw.SizedBox(height: 20),
                                  pw.Text(
                                    'Certificate ID: ${certificate.id.length > 8 ? certificate.id.substring(0, 8) : certificate.id}',
                                    style: pw.TextStyle(
                                      font: fontSansBold,
                                      fontSize: 11,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Center Seal / Logo
                            pw.Expanded(
                              child: pw.Column(
                                children: [
                                  logoImage != null
                                      ? pw.Container(
                                          width: 80,
                                          height: 80,
                                          child: pw.Image(
                                            logoImage!,
                                            fit: pw.BoxFit.contain,
                                          ),
                                        )
                                      : buildSeal(),
                                  pw.SizedBox(height: 10),
                                  pw.Text(
                                    instituteName,
                                    style: pw.TextStyle(
                                      font: fontSansBold,
                                      fontSize: 12,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right Date
                            pw.Expanded(
                              child: pw.Column(
                                children: [
                                  pw.Text(
                                    DateFormat(
                                      'dd.MM.yyyy',
                                    ).format(certificate.issueDate),
                                    style: pw.TextStyle(
                                      font: fontSansBold,
                                      fontSize: 14,
                                      color: primaryColor,
                                    ),
                                  ),
                                  pw.SizedBox(height: 4),
                                  pw.Text(
                                    'Date of Issue',
                                    style: pw.TextStyle(
                                      font: fontSansRegular,
                                      fontSize: 12,
                                      color: secondaryColor,
                                    ),
                                  ),
                                  pw.SizedBox(height: 20),
                                  pw.Text(
                                    'Awarded on: ${DateFormat('dd.MM.yyyy').format(certificate.issueDate)}',
                                    style: pw.TextStyle(
                                      font: fontSansBold,
                                      fontSize: 11,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static String _processBody(Certificate cert) {
    String body = cert.body;
    body = body.replaceAll('{student_name}', cert.studentName);
    body = body.replaceAll('{class_name}', cert.className ?? 'N/A');
    body = body.replaceAll('{roll_no}', cert.studentRollNo ?? 'N/A');
    body = body.replaceAll(
      '{issue_date}',
      DateFormat('dd/MM/yyyy').format(cert.issueDate),
    );
    return body;
  }

  static Future<void> download(
    Certificate cert,
    String instituteName, {
    String? instituteLogoUrl,
    String? backgroundUrl,
  }) async {
    final bytes = await generate(
      certificate: cert,
      instituteName: instituteName,
      instituteLogoUrl: instituteLogoUrl,
      backgroundUrl: backgroundUrl,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${cert.studentName}_${cert.type.name}_Certificate.pdf',
    );
  }

  static Future<void> printPdf(
    Certificate cert,
    String instituteName, {
    String? instituteLogoUrl,
    String? backgroundUrl,
  }) async {
    final bytes = await generate(
      certificate: cert,
      instituteName: instituteName,
      instituteLogoUrl: instituteLogoUrl,
      backgroundUrl: backgroundUrl,
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: '${cert.studentName} Certificate',
    );
  }
}
