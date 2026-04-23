import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:educore/src/features/monthly_tests/models/test_subject.dart';
import 'package:educore/src/features/monthly_tests/models/test_question.dart';

class McqImportService {
  /// Generates a CSV template and allows the user to save it.
  static Future<void> downloadTemplate() async {
    final List<List<String>> rows = [
      ['Question', 'Option A', 'Option B', 'Option C', 'Option D', 'Correct Option', 'Marks', 'Subject'],
      ['What is the capital of France?', 'Berlin', 'Madrid', 'Paris', 'Rome', 'C', '1', 'General Knowledge'],
      ['Which planet is known as the Red Planet?', 'Venus', 'Mars', 'Jupiter', 'Saturn', 'B', '1', 'Science'],
    ];

    String csv = const ListToCsvConverter().convert(rows);
    
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Save MCQ Template',
      fileName: 'mcq_import_template.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      final file = File(result);
      await file.writeAsString(csv);
    }
  }

  /// Picks a CSV file and parses it into TestQuestions with validation.
  /// If [availableSubjects] is provided, it tries to match the 8th column with subject names.
  static Future<List<TestQuestion>?> pickAndParseCsv(
    String testId, 
    String defaultSubjectId, 
    {List<TestSubject>? availableSubjects}
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      
      String content;
      try {
        content = utf8.decode(bytes);
      } catch (_) {
        content = latin1.decode(bytes);
      }

      final fields = const CsvToListConverter().convert(content);

      if (fields.isEmpty) return [];

      final List<TestQuestion> questions = [];
      final List<String> errors = [];
      
      // Skip header row if it looks like one
      int startIndex = 0;
      if (fields[0][0].toString().toLowerCase().contains('question')) {
        startIndex = 1;
      }

      for (int i = startIndex; i < fields.length; i++) {
        final row = fields[i];
        final rowNum = i + 1;

        if (row.length < 7) {
          if (row.isNotEmpty && row[0].toString().trim().isNotEmpty) {
             errors.add('Row $rowNum: Incomplete data. Expected at least 7 columns.');
          }
          continue;
        }

        final qText = row[0].toString().trim();
        final optA = row[1].toString().trim();
        final optB = row[2].toString().trim();
        final optC = row[3].toString().trim();
        final optD = row[4].toString().trim();
        final correct = row[5].toString().toUpperCase().trim();
        final marksStr = row[6].toString().trim();
        
        // Subject Mapping
        String finalSubjectId = defaultSubjectId;
        if (availableSubjects != null && row.length >= 8) {
           final subName = row[7].toString().trim().toLowerCase();
           if (subName.isNotEmpty) {
              final matchedSub = availableSubjects.firstWhere(
                (s) => s.name.toLowerCase() == subName,
                orElse: () => availableSubjects.firstWhere((s) => s.id == defaultSubjectId, orElse: () => availableSubjects.first),
              );
              finalSubjectId = matchedSub.id;
           }
        }

        if (qText.isEmpty) errors.add('Row $rowNum: Question text is missing.');
        if (optA.isEmpty || optB.isEmpty || optC.isEmpty || optD.isEmpty) {
          errors.add('Row $rowNum: One or more options are missing.');
        }
        if (!['A', 'B', 'C', 'D'].contains(correct)) {
          errors.add('Row $rowNum: Correct option must be A, B, C, or D.');
        }
        
        final marks = double.tryParse(marksStr);
        if (marks == null || marks <= 0) {
          errors.add('Row $rowNum: Marks must be a positive number.');
        }

        if (errors.isEmpty) {
          questions.add(TestQuestion(
            id: '',
            testId: testId,
            subjectId: finalSubjectId,
            questionText: qText,
            optionA: optA,
            optionB: optB,
            optionC: optC,
            optionD: optD,
            correctOption: correct,
            marks: marks ?? 1.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
        }
      }

      if (errors.isNotEmpty) {
        throw Exception('Validation Errors:\n${errors.take(5).join('\n')}${errors.length > 5 ? '\n...and ${errors.length - 5} more' : ''}');
      }

      return questions;
    } catch (e) {
      rethrow;
    }
  }
}
