import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:educore/src/core/services/app_services.dart';
import 'package:educore/src/core/services/fee_document_service.dart';
import 'package:educore/src/features/monthly_tests/models/monthly_test.dart';
import 'package:educore/src/features/monthly_tests/models/test_question.dart';
import 'package:educore/src/features/monthly_tests/models/test_result.dart';

class TestPdfGenerator {
  static final _df = DateFormat('MMMM d, yyyy');

  // ─── Public API ────────────────────────────────────────────────────────────

  static Future<void> printQuestionPaper(
    MonthlyTest test,
    List<TestQuestion> questions, {
    String? teacherName,
  }) async {
    // Fetch institute info before building the PDF
    final academyId = FeeDocumentService.currentAcademyId;
    final info = await FeeDocumentService().getAcademyInfo(academyId);
    final effectiveTeacherName = teacherName ?? AppServices.instance.authService?.session?.user.name;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 44, vertical: 40),
        build: (context) => [
          _buildInstituteHeader(info, 'QUESTION PAPER'),
          pw.SizedBox(height: 14),
          _buildTestDetailsBar(test, teacherName: effectiveTeacherName),
          pw.SizedBox(height: 14),
          _buildStudentDetailsSection(),
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 0.8, color: PdfColors.grey500),
          pw.SizedBox(height: 16),

          // ── Questions ──────────────────────────────────────────────────────
          if (test.subjects.length > 1)
            ...test.subjects.expand((sub) {
              final subQs =
                  questions.where((q) => q.subjectId == sub.id).toList();
              if (subQs.isEmpty) return <pw.Widget>[];
              return [
                pw.SizedBox(height: 12),
                _buildSectionBanner(sub.name, sub.totalMarks.toInt()),
                pw.SizedBox(height: 14),
                ...subQs.asMap().entries
                    .map((e) => _buildQuestion(e.key + 1, e.value)),
              ];
            })
          else ...[
            pw.SizedBox(height: 8),
            ...questions.asMap().entries
                .map((e) => _buildQuestion(e.key + 1, e.value)),
          ],

          pw.SizedBox(height: 32),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          pw.Center(
            child: pw.Text(
              '— End of Question Paper —',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: '${test.title}_QuestionPaper.pdf',
    );
  }

  static Future<void> printResultSheet(
    MonthlyTest test,
    List<TestResult> results, {
    String? teacherName,
  }) async {
    final academyId = FeeDocumentService.currentAcademyId;
    final info = await FeeDocumentService().getAcademyInfo(academyId);
    final effectiveTeacherName = teacherName ?? AppServices.instance.authService?.session?.user.name;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        build: (context) => [
          _buildInstituteHeader(info, 'CONSOLIDATED RESULT SHEET'),
          pw.SizedBox(height: 14),
          _buildTestDetailsBar(test, teacherName: effectiveTeacherName),
          pw.SizedBox(height: 20),
          _buildResultsTable(test, results),
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSignBox('Class Teacher'),
              _buildSignBox('Checked By'),
              _buildSignBox('Principal'),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: '${test.title}_Results.pdf',
    );
  }

  // ─── Header Widgets ────────────────────────────────────────────────────────

  /// Top section: Institute name + contact/address, then document type banner.
  static pw.Widget _buildInstituteHeader(
    Map<String, String> info,
    String docTitle,
  ) {
    final name = info['name'] ?? 'Institute';
    final address = info['address'] ?? '';
    final phone = info['phone'] ?? '';
    final email = info['email'] ?? '';

    // Build contact line (phone • email — only non-empty parts)
    final contactParts = [
      if (phone.isNotEmpty) 'Tel: $phone',
      if (email.isNotEmpty) email,
    ];
    final contactLine = contactParts.join('   •   ');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        // ── Institute title block ───────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#1E3A8A'),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                name.toUpperCase(),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: 1.5,
                ),
              ),
              if (address.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  address,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColor(1, 1, 1, 0.7),
                  ),
                ),
              ],
              if (contactLine.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  contactLine,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColor(1, 1, 1, 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),

        pw.SizedBox(height: 10),

        // ── Document type banner ────────────────────────────────────────────
        pw.Center(
          child: pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: PdfColor.fromHex('#1E3A8A'),
                width: 1.2,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              docTitle,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1E3A8A'),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Two-column test details row: left (Test Name, Class, Teacher) · right (Date, Marks, Duration)
  static pw.Widget _buildTestDetailsBar(
    MonthlyTest test, {
    String? teacherName,
  }) {
    final isMultiSubject = test.subjects.length > 1;
    final subjectDisplay =
        isMultiSubject ? 'Multiple (${test.subjects.length})' : test.subject;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F0F4FF'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('#C7D2FE'), width: 0.8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left column
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _detailRow('Test Name', test.title),
                _detailRow('Subject', subjectDisplay),
                _detailRow('Class', test.className ?? 'N/A'),
                if (teacherName != null && teacherName.isNotEmpty)
                  _detailRow('Teacher', teacherName),
              ],
            ),
          ),

          // Vertical divider
          pw.Container(
            width: 0.8,
            height: 64,
            color: PdfColor.fromHex('#C7D2FE'),
            margin: const pw.EdgeInsets.symmetric(horizontal: 16),
          ),

          // Right column
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _detailRow('Held On', _df.format(test.testDate)),
                _detailRow('Total Marks', '${test.totalMarks.toInt()}'),
                _detailRow('Pass Marks', '${test.passingMarks.toInt()}'),
                _detailRow('Duration', '${test.durationMinutes} Minutes'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _detailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#374151'),
              ),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColor.fromHex('#111827'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Student details to fill in — Question Paper only.
  static pw.Widget _buildStudentDetailsSection() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        children: [
          _blankField('Student Name', flex: 3),
          pw.SizedBox(width: 24),
          _blankField("Father's Name", flex: 3),
          pw.SizedBox(width: 24),
          _blankField('Signature', flex: 2),
        ],
      ),
    );
  }

  static pw.Widget _blankField(String label, {int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#374151'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            height: 1,
            color: PdfColors.grey500,
          ),
        ],
      ),
    );
  }

  // ─── Question Widgets ──────────────────────────────────────────────────────

  static pw.Widget _buildSectionBanner(String name, int marks) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EFF6FF'),
        border: pw.Border(
          left: pw.BorderSide(
              color: PdfColor.fromHex('#1E3A8A'), width: 3),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Section: $name',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: PdfColor.fromHex('#1E3A8A'),
            ),
          ),
          pw.Text(
            'Total Marks: $marks',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#374151'),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildQuestion(int index, TestQuestion q) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 18),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$index. ',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  q.questionText,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: pw.BoxDecoration(
                  border:
                      pw.Border.all(color: PdfColors.grey400, width: 0.6),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text(
                  '${q.marks.toInt()} Marks',
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColor.fromHex('#374151'),
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 18),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text('A)  ${q.optionA}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Expanded(
                      child: pw.Text('B)  ${q.optionB}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text('C)  ${q.optionC}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ),
                    pw.Expanded(
                      child: pw.Text('D)  ${q.optionD}',
                          style: const pw.TextStyle(fontSize: 10)),
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

  // ─── Result Table ──────────────────────────────────────────────────────────

  static pw.Widget _buildResultsTable(
      MonthlyTest test, List<TestResult> results) {
    final hasMulti = test.subjects.length > 1;

    final List<String> headers = ['#', 'Student Name', 'Roll No'];
    if (hasMulti) {
      for (final sub in test.subjects) {
        headers.add(sub.name);
      }
    }
    headers.addAll(['Total', '%', 'Grade', 'Status']);

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
        fontSize: 9,
      ),
      headerDecoration:
          pw.BoxDecoration(color: PdfColor.fromHex('#1E3A8A')),
      cellHeight: 22,
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        for (int i = 3; i < headers.length; i++) i: pw.Alignment.center,
      },
      oddRowDecoration:
          pw.BoxDecoration(color: PdfColor.fromHex('#F8FAFF')),
      headers: headers,
      data: results.map((r) {
        final row = ['${r.rank}', r.studentName, r.studentRollNo];
        if (hasMulti) {
          for (final sub in test.subjects) {
            row.add('${(r.subjectObtained[sub.id] ?? 0).toInt()}');
          }
        }
        row.addAll([
          '${r.obtainedMarks.toInt()}',
          '${r.percentage.toStringAsFixed(1)}%',
          r.grade,
          r.status,
        ]);
        return row;
      }).toList(),
    );
  }

  // ─── Sign Boxes ────────────────────────────────────────────────────────────

  static pw.Widget _buildSignBox(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.SizedBox(height: 36),
        pw.Container(width: 130, height: 0.8, color: PdfColors.black),
        pw.SizedBox(height: 5),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#374151'),
          ),
        ),
      ],
    );
  }
}
