import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class FeeDocumentPreviewPage extends StatelessWidget {
  const FeeDocumentPreviewPage({
    super.key,
    required this.title,
    required this.buildPdf,
    this.initialFormat = PdfPageFormat.a4,
  });

  final String title;
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;
  final PdfPageFormat initialFormat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: PdfPreview(
        build: buildPdf,
        initialPageFormat: initialFormat,
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: '${title.replaceAll(' ', '_')}.pdf',
      ),
    );
  }
}
