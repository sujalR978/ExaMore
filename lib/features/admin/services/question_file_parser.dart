
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:prep_mate/features/admin/models/exam_model.dart';
import 'package:share_plus/share_plus.dart';

class QuestionFileParser {
  /// Generates streamlined CSV sample template content for instructors.
  /// Shows exam title and total marks target from previous screens.
  /// Columns: Question | Marks | Option A(Correct) | Option B | Option C | Option D ...
  static String generateSampleCsvTemplate({
    String? examTitle,
    double? totalMarks,
    String? defaultCategory,
  }) {
    final buffer = StringBuffer();
    final String cleanTitle =
        (examTitle ?? '').trim().isEmpty ? 'Exam Assessment' : examTitle!.trim();
    final int marksInt =
        (totalMarks != null && totalMarks > 0) ? totalMarks.toInt() : 50;

    // Header comment showing the Exam Title and Total Marks entered in the previous screen
    buffer.writeln(
      '# EXAM: $cleanTitle | TOTAL MARKS: $marksInt pts (Sum of question marks should equal $marksInt)',
    );
    // Columns specified by instructor: Question, Marks, Option A(Correct), Option B, Option C, Option D...
    buffer.writeln(
      'Question,Marks,Option A(Correct),Option B,Option C,Option D',
    );
    buffer.writeln(
      '"What is the SI unit of electric current?","1","Ampere","Volt","Ohm","Watt"',
    );
    buffer.writeln(
      '"Which gas do plants absorb during photosynthesis?","1","Carbon Dioxide","Oxygen","Nitrogen","Hydrogen"',
    );
    buffer.writeln(
      '"Solve for x: 2x + 6 = 14","2","4","3","5","6"',
    );
    buffer.writeln(
      '"What is the capital city of Japan?","1","Tokyo","Seoul","Beijing","Bangkok"',
    );
    buffer.writeln(
      '"Which data structure follows the First-In-First-Out (FIFO) principle?","2","Queue","Stack","Tree","Graph"',
    );
    return buffer.toString();
  }

  /// Downloads / shares the sample template so users can fill it in Excel or Google Sheets.
  static Future<void> downloadOrShareTemplate(
    BuildContext context, {
    String? examTitle,
    double? totalMarks,
    String? defaultCategory,
  }) async {
    try {
      final templateCsv = generateSampleCsvTemplate(
        examTitle: examTitle,
        totalMarks: totalMarks,
        defaultCategory: defaultCategory,
      );
      final bytes = utf8.encode(templateCsv);
      final filename = examTitle != null && examTitle.trim().isNotEmpty
          ? '${examTitle.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}_Template.csv'
          : 'ExaMore_Question_Bank_Template.csv';

      final xFile = XFile.fromData(
        bytes,
        name: filename,
        mimeType: 'text/csv',
      );

      await Share.shareXFiles(
        [xFile],
        subject: '$examTitle Question Bank Template',
        text:
            'ExaMore Question Bank Template. Total marks: ${(totalMarks ?? 50).toInt()} pts. Fill in your questions and upload it directly into the exam.',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share template: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  static Future<List<QuestionModel>> pickAndParseQuestions({
    String defaultCategory = 'General',
  }) async {
    // Official public API entry point
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return [];

    final PlatformFile pickedFile = result.files.first;
    String content = '';

    // Safely retrieve bytes from memory or disk
    if (pickedFile.bytes != null) {
      content = utf8.decode(pickedFile.bytes!);
    } else if (pickedFile.path != null && pickedFile.path!.isNotEmpty) {
      final file = File(pickedFile.path!);
      final bytes = await file.readAsBytes();
      content = utf8.decode(bytes);
    } else {
      throw const FormatException('Unable to read selected file contents.');
    }

    // Strip BOM character if present
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }

    final String extension =
        (pickedFile.extension ?? pickedFile.name.split('.').last).toLowerCase();

    if (extension == 'json') {
      return _parseJson(content);
    } else if (extension == 'csv') {
      return _parseCsv(content, defaultCategory: defaultCategory);
    }

    throw const FormatException('Only JSON and CSV files are supported.');
  }

  static List<QuestionModel> _parseJson(String rawJson) {
    final dynamic decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      throw const FormatException('JSON must contain a list of questions.');
    }

    return decoded.map<QuestionModel>((dynamic item) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(item as Map);
      final rawOptions = map['options'] is List
          ? List<dynamic>.from(map['options'])
          : <dynamic>[];

      final List<QuestionOption> options = _normalizeOptions(rawOptions);

      final dynamic rawCorrect =
          map['correctOptionIndex'] ??
          map['correctAnswer'] ??
          map['correctOptionId'] ??
          map['answer'];

      final String correctOptionId = _resolveCorrectOption(
        options,
        rawCorrectValue: rawCorrect,
      );

      return QuestionModel(
        id: '',
        questionText: map['questionText']?.toString() ?? '',
        marks: (map['marks'] as num?)?.toDouble() ?? 1.0,
        options: options,
        correctOptionId: correctOptionId,
        type: map['type']?.toString() ?? 'multiple_choice',
        category: map['category']?.toString() ?? 'General',
        difficulty: map['difficulty']?.toString() ?? 'Medium',
        views: 0,
        estimatedTimeMinutes:
            (map['estimatedTimeMinutes'] as num?)?.toInt() ?? 2,
        createdAt: DateTime.now(),
      );
    }).toList();
  }

  static List<QuestionModel> _parseCsv(
    String rawCsv, {
    String defaultCategory = 'General',
  }) {
    final List<List<String>> rawRows = _parseCsvString(rawCsv);
    if (rawRows.isEmpty) return [];

    // Filter out comment or metadata rows starting with '#' or '//'
    final List<List<String>> rows = [];
    for (final r in rawRows) {
      if (r.isEmpty) continue;
      final firstCell = r[0].trim();
      if (firstCell.startsWith('#') || firstCell.startsWith('//')) {
        continue;
      }
      rows.add(r);
    }

    if (rows.length <= 1) return [];

    // Header detection on row 0
    final List<String> header =
        rows[0].map((h) => h.trim().toLowerCase()).toList();

    int questionCol = -1;
    int marksCol = -1;
    int categoryCol = -1;
    int difficultyCol = -1;
    int correctCol = -1;
    final List<int> optionCols = [];

    for (int i = 0; i < header.length; i++) {
      final h = header[i];
      if (h.contains('question')) {
        questionCol = i;
      } else if (h.contains('mark') || h.contains('point')) {
        marksCol = i;
      } else if (h.contains('category') || h.contains('subject')) {
        categoryCol = i;
      } else if (h.contains('difficulty') || h.contains('level')) {
        difficultyCol = i;
      } else if (h.contains('correct option') ||
          h == 'correct' ||
          h == 'answer') {
        correctCol = i;
      } else if (h.contains('option') ||
          h.contains('choice') ||
          h.startsWith('opt')) {
        optionCols.add(i);
      }
    }

    // Check if Option A header explicitly designates it as correct: e.g. "Option A(Correct)"
    final bool optionAIsDefaultCorrect = optionCols.isNotEmpty &&
        header[optionCols[0]].contains('correct');

    final bool hasValidHeaderMap = questionCol != -1 && optionCols.isNotEmpty;
    final List<QuestionModel> parsed = [];

    for (int i = 1; i < rows.length; i++) {
      final List<String> row = rows[i];

      if (row.isEmpty || row.every((val) => val.trim().isEmpty)) {
        continue;
      }

      List<String> columns = row;
      if (columns.length == 1 && columns[0].contains(',')) {
        columns = _parseCsvLine(columns[0]);
      }

      if (columns.length < 3) continue;

      String questionText = '';
      String category = defaultCategory;
      String difficulty = 'Medium';
      double marks = 1.0;
      final List<String> rawOptions = [];
      dynamic rawCorrect = 'A';

      if (hasValidHeaderMap) {
        questionText = questionCol < columns.length
            ? columns[questionCol].trim()
            : '';
        if (marksCol != -1 && marksCol < columns.length) {
          marks = double.tryParse(columns[marksCol].trim()) ?? 1.0;
        }
        if (categoryCol != -1 &&
            categoryCol < columns.length &&
            columns[categoryCol].trim().isNotEmpty) {
          category = columns[categoryCol].trim();
        }
        if (difficultyCol != -1 &&
            difficultyCol < columns.length &&
            columns[difficultyCol].trim().isNotEmpty) {
          difficulty = columns[difficultyCol].trim();
        }
        for (final optIdx in optionCols) {
          if (optIdx < columns.length && columns[optIdx].trim().isNotEmpty) {
            rawOptions.add(columns[optIdx].trim());
          }
        }
        if (correctCol != -1 && correctCol < columns.length) {
          rawCorrect = columns[correctCol].trim();
        } else if (optionAIsDefaultCorrect) {
          rawCorrect = 'A'; // Option A is the correct answer
        }
      } else {
        // Fallback positional mapping: Question, Marks, Option A, Option B...
        questionText = columns[0].trim();
        marks = columns.length > 1
            ? (double.tryParse(columns[1].trim()) ?? 1.0)
            : 1.0;
        for (int c = 2; c < columns.length; c++) {
          if (columns[c].trim().isNotEmpty) {
            rawOptions.add(columns[c].trim());
          }
        }
        rawCorrect = 'A';
      }

      if (questionText.isEmpty || rawOptions.isEmpty) continue;

      final List<QuestionOption> options = _normalizeOptions(rawOptions);
      final String correctOptionId = _resolveCorrectOption(
        options,
        rawCorrectValue: rawCorrect,
      );

      parsed.add(
        QuestionModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_$i',
          questionText: questionText,
          marks: marks,
          options: options,
          correctOptionId: correctOptionId,
          type: 'Multiple Choice',
          category: category,
          difficulty: difficulty,
          views: 0,
          estimatedTimeMinutes: 2,
          createdAt: DateTime.now(),
        ),
      );
    }

    return parsed;
  }

  static List<QuestionOption> _normalizeOptions(List<dynamic> rawOptions) {
    final List<QuestionOption> normalized = [];

    for (int i = 0; i < rawOptions.length; i++) {
      final dynamic option = rawOptions[i];
      String text = '';

      final String letterId = String.fromCharCode(65 + i);

      if (option is Map) {
        text =
            option['text']?.toString() ??
            option['optionText']?.toString() ??
            option['value']?.toString() ??
            '';
      } else {
        text = option?.toString() ?? '';
      }

      normalized.add(QuestionOption(id: letterId, text: text.trim()));
    }

    return normalized;
  }

  static String _resolveCorrectOption(
    List<QuestionOption> options, {
    required dynamic rawCorrectValue,
  }) {
    if (options.isEmpty) return 'A';

    final String valStr =
        (rawCorrectValue?.toString() ?? '').trim().toUpperCase();

    // Letter matching ('A', 'B', 'C', 'D'...)
    if (valStr.length == 1 &&
        valStr.codeUnitAt(0) >= 65 &&
        valStr.codeUnitAt(0) <= 90) {
      final match = options.where((o) => o.id == valStr);
      if (match.isNotEmpty) return match.first.id;
    }

    // Number matching
    final int? parsedNum = int.tryParse(valStr);
    if (parsedNum != null) {
      if (parsedNum >= 0 && parsedNum < options.length) {
        return options[parsedNum].id;
      }
      if (parsedNum >= 1 && parsedNum <= options.length) {
        return options[parsedNum - 1].id;
      }
    }

    final RegExp digitRegex = RegExp(r'\d+');
    final match = digitRegex.firstMatch(valStr);
    if (match != null) {
      final int idx = (int.tryParse(match.group(0)!) ?? 1) - 1;
      if (idx >= 0 && idx < options.length) {
        return options[idx].id;
      }
    }

    return options.first.id;
  }

  static List<List<String>> _parseCsvString(String input) {
    final List<List<String>> rows = [];
    final lines = const LineSplitter().convert(input);

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      rows.add(_parseCsvLine(line));
    }
    return rows;
  }

  static List<String> _parseCsvLine(String line) {
    final List<String> fields = [];
    final StringBuffer currentField = StringBuffer();
    bool insideQuotes = false;
    final String delimiter =
        line.contains(';') && !line.contains(',') ? ';' : ',';

    for (int i = 0; i < line.length; i++) {
      final String char = line[i];

      if (char == '"') {
        if (insideQuotes && i + 1 < line.length && line[i + 1] == '"') {
          currentField.write('"');
          i++;
        } else {
          insideQuotes = !insideQuotes;
        }
      } else if (char == delimiter && !insideQuotes) {
        fields.add(currentField.toString().trim());
        currentField.clear();
      } else {
        currentField.write(char);
      }
    }
    fields.add(currentField.toString().trim());
    return fields;
  }
}