// ignore_for_file: file_names

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';

class QuestionFileParser {
  static Future<List<QuestionModel>> pickAndParseQuestions() async {
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
      return _parseCsv(content);
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

  static List<QuestionModel> _parseCsv(String rawCsv) {
    final List<List<String>> rows = _parseCsvString(rawCsv);

    if (rows.length <= 1) return [];

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

      if (columns.length < 5) continue;

      final String questionText = columns[0].trim();
      final String category = columns.length > 1 && columns[1].trim().isNotEmpty
          ? columns[1].trim()
          : 'General';
      final String difficulty =
          columns.length > 2 && columns[2].trim().isNotEmpty
              ? columns[2].trim()
              : 'Medium';
      final double marks = columns.length > 3
          ? (double.tryParse(columns[3].trim()) ?? 1.0)
          : 1.0;

      final List<String> rawOptions = [];
      if (columns.length >= 9) {
        for (int c = 4; c <= 7; c++) {
          if (columns[c].trim().isNotEmpty) {
            rawOptions.add(columns[c].trim());
          }
        }
      } else {
        for (int c = 4; c < columns.length - 1; c++) {
          if (columns[c].trim().isNotEmpty) {
            rawOptions.add(columns[c].trim());
          }
        }
      }

      final List<QuestionOption> options = _normalizeOptions(rawOptions);

      final dynamic rawCorrect = columns.last.trim();
      final String correctOptionId = _resolveCorrectOption(
        options,
        rawCorrectValue: rawCorrect,
      );

      parsed.add(
        QuestionModel(
          id: '',
          questionText: questionText,
          marks: marks,
          options: options,
          correctOptionId: correctOptionId,
          type: 'multiple_choice',
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