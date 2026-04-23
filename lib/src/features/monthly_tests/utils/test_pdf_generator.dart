import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:educore/src/features/monthly_tests/models/monthly_test.dart';
import 'package:educore/src/features/monthly_tests/models/test_question.dart';
import 'package:educore/src/features/monthly_tests/models/test_result.dart';

class TestPdfGenerator {
  static final _df = DateFormat('MMM d, yyyy');

  static Future<void> printQuestionPaper(MonthlyTest test, List<TestQuestion> questions) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(test, 'QUESTION PAPER'),
          pw.SizedBox(height: 24),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Student Name: __________________________', style: pw.TextStyle(fontSize: 10)),
              pw.Text('Roll No: __________', style: pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          
          if (test.subjects.length > 1) ...[
             ...test.subjects.expand((sub) {
                final subQs = questions.where((q) => q.subjectId == sub.id).toList();
                if (subQs.isEmpty) return [];
                return [
                  pw.SizedBox(height: 20),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(color: PdfColors.grey200),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Section: ${sub.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                        pw.Text('Marks: ${sub.totalMarks.toInt()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 16),
                  ...subQs.asMap().entries.map((entry) => _buildQuestion(entry.key + 1, entry.value)),
                ];
             }),
          ] else ...[
             pw.SizedBox(height: 20),
             ...questions.asMap().entries.map((entry) => _buildQuestion(entry.key + 1, entry.value)),
          ],

          pw.SizedBox(height: 40),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text('*** End of Question Paper ***', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save(), name: '${test.title}_Paper.pdf');
  }

  static Future<void> printResultSheet(MonthlyTest test, List<TestResult> results) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape, // Switch to landscape for multiple subjects
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(test, 'CONSOLIDATED RESULT SHEET'),
          pw.SizedBox(height: 24),
          _buildResultsTable(test, results),
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSignBox('Class Teacher'),
              _buildSignBox('Principal'),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save(), name: '${test.title}_Results.pdf');
  }

  static pw.Widget _buildHeader(MonthlyTest test, String title) {
    final isMultiSubject = test.subjects.length > 1;
    final subjectDisplay = isMultiSubject ? 'Multiple (${test.subjects.length})' : test.subject;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('EDUCORE ACADEMY ERP', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E3A8A'))),
        pw.SizedBox(height: 4),
        pw.Text('Innovation in Education Management', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic)),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F3F4F6'),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#374151'))),
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _headerInfo('Test', test.title),
                _headerInfo('Subject', subjectDisplay),
                _headerInfo('Class', test.className ?? 'N/A'),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _headerInfo('Date', _df.format(test.testDate)),
                _headerInfo('Max Marks', '${test.totalMarks.toInt()}'),
                _headerInfo('Time', '${test.durationMinutes} Mins'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _headerInfo(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildQuestion(int index, TestQuestion q) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('$index. ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.Expanded(child: pw.Text(q.questionText, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
              pw.SizedBox(width: 10),
              pw.Text('(${q.marks.toInt()} Marks)', style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20),
            child: pw.Column(
              children: [
                pw.Row(children: [
                  pw.Expanded(child: pw.Text('A) ${q.optionA}', style: const pw.TextStyle(fontSize: 10))),
                  pw.Expanded(child: pw.Text('B) ${q.optionB}', style: const pw.TextStyle(fontSize: 10))),
                ]),
                pw.SizedBox(height: 6),
                pw.Row(children: [
                  pw.Expanded(child: pw.Text('C) ${q.optionC}', style: const pw.TextStyle(fontSize: 10))),
                  pw.Expanded(child: pw.Text('D) ${q.optionD}', style: const pw.TextStyle(fontSize: 10))),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildResultsTable(MonthlyTest test, List<TestResult> results) {
    final hasMultipleSubjects = test.subjects.length > 1;
    
    final List<String> headers = ['Rank', 'Student Name', 'Roll No'];
    if (hasMultipleSubjects) {
      for (var sub in test.subjects) {
        headers.add(sub.name);
      }
    }
    headers.addAll(['Total', 'Perc (%)', 'Grade', 'Status']);

    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E3A8A')),
      cellHeight: 22,
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignments: {
        0: pw.Alignment.center,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.center,
        for (int i = 3; i < headers.length; i++) i: pw.Alignment.center,
      },
      headers: headers,
      data: results.map((r) {
        final List<String> row = [
          '${r.rank}',
          r.studentName,
          r.studentRollNo,
        ];
        
        if (hasMultipleSubjects) {
          for (var sub in test.subjects) {
            final marks = r.subjectObtained[sub.id] ?? 0;
            row.add('${marks.toInt()}');
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

  static pw.Widget _buildSignBox(String title) {
    return pw.Column(
      children: [
        pw.SizedBox(height: 40),
        pw.Container(width: 120, height: 1, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
