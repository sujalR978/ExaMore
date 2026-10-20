import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';

class QuestionFileParser {
  static Future<List<QuestionModel>> pickAndParseQuestions() async {
    final List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
    );

    if (files.isEmpty) return [];

    final PlatformFile pickedFile = files.first;
    final bytes = await pickedFile.readAsBytes();
    String content = utf8.decode(bytes);

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
      final int correctIndex =
          (map['correctOptionIndex'] as num?)?.toInt() ?? 0;

      final List<QuestionOption> options = _normalizeOptions(rawOptions);

      return QuestionModel(
        id: '',
        questionText: map['questionText']?.toString() ?? '',
        marks: (map['marks'] as num?)?.toDouble() ?? 1.0,
        options: options,
        correctOptionId: _resolveCorrectOption(
          options,
          correctIndex: correctIndex,
        ),
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

    // Skip the header row (index 0)
    for (int i = 1; i < rows.length; i++) {
      final List<String> row = rows[i];

      // Skip blank rows
      if (row.isEmpty || row.every((val) => val.trim().isEmpty)) {
        continue;
      }

      // If the row was wrapped in outer quotes and didn't split, handle it
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

      // Extract options (indices 4, 5, 6, 7 if available)
      final List<String> rawOptions = [];
      if (columns.length >= 9) {
        for (int c = 4; c <= 7; c++) {
          if (columns[c].trim().isNotEmpty) {
            rawOptions.add(columns[c].trim());
          }
        }
      } else {
        // Fallback for variable-length rows
        for (int c = 4; c < columns.length - 1; c++) {
          if (columns[c].trim().isNotEmpty) {
            rawOptions.add(columns[c].trim());
          }
        }
      }

      // The last column is always the zero-based correct index
      final int correctIndex = int.tryParse(columns.last.trim()) ?? 0;

      final List<QuestionOption> options = _normalizeOptions(rawOptions);

      parsed.add(
        QuestionModel(
          id: '',
          questionText: questionText,
          marks: marks,
          options: options,
          correctOptionId: _resolveCorrectOption(
            options,
            correctIndex: correctIndex,
          ),
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
      String id = 'opt_${i + 1}';

      if (option is Map) {
        id = option['id']?.toString() ?? id;
        text =
            option['text']?.toString() ??
            option['optionText']?.toString() ??
            option['value']?.toString() ??
            '';
      } else {
        text = option?.toString() ?? '';
      }

      normalized.add(QuestionOption(id: id, text: text.trim()));
    }

    return normalized;
  }

  static String _resolveCorrectOption(
    List<QuestionOption> options, {
    required int correctIndex,
  }) {
    if (options.isEmpty) return '';
    if (correctIndex >= 0 && correctIndex < options.length) {
      return options[correctIndex].id;
    }
    return options.first.id;
  }

  /// Parses an entire CSV string into rows and columns correctly handling quotes
  static List<List<String>> _parseCsvString(String input) {
    final List<List<String>> rows = [];
    final lines = const LineSplitter().convert(input);

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      rows.add(_parseCsvLine(line));
    }
    return rows;
  }

  /// Splits a single line by delimiter while respecting double-quoted values
  static List<String> _parseCsvLine(String line) {
    final List<String> fields = [];
    final StringBuffer currentField = StringBuffer();
    bool insideQuotes = false;
    final String delimiter = line.contains(';') && !line.contains(',')
        ? ';'
        : ',';

    for (int i = 0; i < line.length; i++) {
      final String char = line[i];

      if (char == '"') {
        // Escaped quote ("")
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
