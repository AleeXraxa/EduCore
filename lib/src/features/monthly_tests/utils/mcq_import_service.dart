import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:educore/src/features/monthly_tests/models/test_question.dart';

class McqImportService {
  /// Simulates parsing a mock list for quick testing.
  static Future<List<TestQuestion>> parseMockImport(String testId) async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      TestQuestion(
        id: '',
        testId: testId,
        questionText: 'What is the capital of France?',
        optionA: 'Berlin',
        optionB: 'Madrid',
        optionC: 'Paris',
        optionD: 'Rome',
        correctOption: 'C',
        marks: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  /// Picks a CSV file and parses it into TestQuestions.
  /// CSV Format: Question,Option A,Option B,Option C,Option D,Correct Option,Marks
  static Future<List<TestQuestion>?> pickAndParseCsv(String testId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.single.path!);
      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(const CsvToListConverter())
          .toList();

      if (fields.isEmpty) return [];

      final List<TestQuestion> questions = [];
      
      // Skip header row if it looks like one
      int startIndex = 0;
      if (fields[0][0].toString().toLowerCase().contains('question')) {
        startIndex = 1;
      }

      for (int i = startIndex; i < fields.length; i++) {
        final row = fields[i];
        if (row.length < 6) continue;

        questions.add(TestQuestion(
          id: '',
          testId: testId,
          questionText: row[0].toString(),
          optionA: row[1].toString(),
          optionB: row[2].toString(),
          optionC: row[3].toString(),
          optionD: row[4].toString(),
          correctOption: row[5].toString().toUpperCase().trim(),
          marks: double.tryParse(row[6].toString()) ?? 1.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }

      return questions;
    } catch (e) {
      rethrow;
    }
  }
}
