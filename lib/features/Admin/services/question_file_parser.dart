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
    final List<List<dynamic>> rows = _decodeCsvRows(rawCsv);

    if (rows.length <= 1) return [];

    final List<QuestionModel> parsed = [];

    // Skip header row
    for (int i = 1; i < rows.length; i++) {
      final List<dynamic> row = rows[i];

      // Skip blank rows
      if (row.isEmpty || row.every((val) => val.toString().trim().isEmpty)) {
        continue;
      }

      final String questionText = row.isNotEmpty
          ? row[0].toString().trim()
          : '';
      if (questionText.isEmpty) continue;

      final String category =
          row.length > 1 && row[1].toString().trim().isNotEmpty
          ? row[1].toString().trim()
          : 'General';

      final String difficulty =
          row.length > 2 && row[2].toString().trim().isNotEmpty
          ? row[2].toString().trim()
          : 'Medium';

      final double marks = row.length > 3
          ? (double.tryParse(row[3].toString().trim()) ?? 1.0)
          : 1.0;

      // Extract options (columns 4 through second to last)
      final List<dynamic> rawOptions = [];
      if (row.length >= 6) {
        for (int j = 4; j < row.length - 1; j++) {
          final opt = row[j].toString().trim();
          if (opt.isNotEmpty) rawOptions.add(opt);
        }
      }

      final int correctIndex = row.isNotEmpty
          ? (int.tryParse(row.last.toString().trim()) ?? 0)
          : 0;

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

  /// Robust CSV parser supporting commas, semicolons, quotes, and escaped quotes
  static List<List<dynamic>> _decodeCsvRows(String csv) {
    final String delimiter =
        csv.contains(';') && !csv.split('\n').first.contains(',') ? ';' : ',';

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
      } else if (char == delimiter && !inQuotes) {
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

    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }

    return rows;
  }
}
