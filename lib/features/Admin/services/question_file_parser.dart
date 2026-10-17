import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:prep_mate/features/Admin/model/exam_model.dart';

class QuestionFileParser {
  /// Pick and parse a JSON or CSV file containing questions.
  static Future<List<QuestionModel>> pickAndParseQuestions() async {
    final List<PlatformFile> files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json', 'csv'],
    );

    if (files.isEmpty) {
      return [];
    }

    final PlatformFile pickedFile = files.first;

    final bytes = await pickedFile.readAsBytes();
    String content = utf8.decode(bytes);

    // Remove UTF-8 BOM if present
    if (content.startsWith('\uFEFF')) {
      content = content.substring(1);
    }

    final String extension =
        (pickedFile.extension ?? pickedFile.name.split('.').last).toLowerCase();

    switch (extension) {
      case 'json':
        return _parseJson(content);
      case 'csv':
        return _parseCsv(content);
      default:
        throw const FormatException('Only JSON and CSV files are supported.');
    }
  }

  /// Parse questions from a JSON array.
  static List<QuestionModel> _parseJson(String rawJson) {
    final dynamic decoded = jsonDecode(rawJson);

    if (decoded is! List) {
      throw const FormatException('JSON must contain a list of questions.');
    }

    return decoded.map<QuestionModel>((dynamic item) {
      if (item is! Map) {
        throw const FormatException('Each question must be a JSON object.');
      }

      final Map<String, dynamic> map = Map<String, dynamic>.from(item);
      final dynamic optionsData = map['options'];

      final List<dynamic> rawOptions = optionsData is List
          ? List<dynamic>.from(optionsData)
          : <dynamic>[];

      final int correctIndex =
          (map['correctOptionIndex'] as num?)?.toInt() ?? 0;

      final List<QuestionOption> options = _normalizeOptions(rawOptions);

      final String correctOptionId = _resolveCorrectOption(
        options,
        correctIndex: correctIndex,
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

  /// Parse questions from CSV.
  static List<QuestionModel> _parseCsv(String rawCsv) {
    final List<List<dynamic>> rows = _decodeCsvRows(rawCsv);

    if (rows.length <= 1) {
      return [];
    }

    final List<QuestionModel> parsed = [];

    // Skip the header row
    for (int i = 1; i < rows.length; i++) {
      final List<dynamic> row = rows[i];

      // Skip empty or blank lines
      if (row.isEmpty ||
          row.every((value) => value.toString().trim().isEmpty)) {
        continue;
      }

      if (row.length < 9) {
        throw FormatException(
          'CSV row ${i + 1} must contain at least 9 columns.',
        );
      }

      final String questionText = row[0].toString().trim();
      if (questionText.isEmpty) {
        throw FormatException('Question text is missing in CSV row ${i + 1}.');
      }

      final String category = row[1].toString().trim();
      final String difficulty = row[2].toString().trim();
      final double marks = double.tryParse(row[3].toString().trim()) ?? 1.0;

      final List<dynamic> rawOptions = [row[4], row[5], row[6], row[7]];
      final int correctIndex = int.tryParse(row[8].toString().trim()) ?? 0;

      final List<QuestionOption> options = _normalizeOptions(rawOptions);
      final String correctOptionId = _resolveCorrectOption(
        options,
        correctIndex: correctIndex,
      );

      parsed.add(
        QuestionModel(
          id: '',
          questionText: questionText,
          marks: marks,
          options: options,
          correctOptionId: correctOptionId,
          type: 'multiple_choice',
          category: category.isEmpty ? 'General' : category,
          difficulty: difficulty.isEmpty ? 'Medium' : difficulty,
          views: 0,
          estimatedTimeMinutes: 2,
          createdAt: DateTime.now(),
        ),
      );
    }

    return parsed;
  }

  /// Convert JSON or CSV option values into QuestionOption instances.
  static List<QuestionOption> _normalizeOptions(List<dynamic> rawOptions) {
    final List<QuestionOption> normalized = [];

    for (int i = 0; i < rawOptions.length; i++) {
      final dynamic option = rawOptions[i];
      String optionText = '';
      String optionId = 'opt_${i + 1}';

      if (option is Map) {
        optionId = option['id']?.toString() ?? optionId;
        final dynamic text = option['text'];
        final dynamic optionTextValue = option['optionText'];
        final dynamic value = option['value'];

        optionText =
            text?.toString() ??
            optionTextValue?.toString() ??
            value?.toString() ??
            '';
      } else {
        optionText = option?.toString() ?? '';
      }

      normalized.add(QuestionOption(id: optionId, text: optionText.trim()));
    }

    return normalized;
  }

  /// Return the correct option ID matching the provided index.
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

  /// Decode CSV, supporting quoted commas and escaped quotes.
  static List<List<dynamic>> _decodeCsvRows(String csv) {
    final List<List<dynamic>> rows = [];
    List<dynamic> row = [];
    final StringBuffer field = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < csv.length; i++) {
      final String char = csv[i];

      if (char == '"') {
        if (inQuotes && i + 1 < csv.length && csv[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        row.add(field.toString());
        field.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < csv.length && csv[i + 1] == '\n') {
          i++;
        }

        row.add(field.toString());
        field.clear();
        rows.add(row);
        row = [];
      } else {
        field.write(char);
      }
    }

    if (inQuotes) {
      throw const FormatException('CSV contains an unclosed quoted field.');
    }

    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }

    return rows;
  }
}
