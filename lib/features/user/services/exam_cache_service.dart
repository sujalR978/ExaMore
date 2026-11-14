import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ExamCacheService {
  static const String _prefix = 'active_exam_';

  /// Saves the student's active exam progress locally
  static Future<void> saveExamState({
    required String examId,
    required int remainingSeconds,
    required Map<String, String> selectedAnswers,
    int switchCount = 0,
  }) async {
    if (examId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('$_prefix${examId}_seconds', remainingSeconds);
      await prefs.setString(
        '$_prefix${examId}_answers',
        jsonEncode(selectedAnswers),
      );
      await prefs.setInt('$_prefix${examId}_switches', switchCount);
      await prefs.setInt(
        '$_prefix${examId}_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  /// Retrieves cached exam progress if valid and not expired
  static Future<Map<String, dynamic>?> getExamState(String examId) async {
    if (examId.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final seconds = prefs.getInt('$_prefix${examId}_seconds');
      final answersJson = prefs.getString('$_prefix${examId}_answers');
      final switches = prefs.getInt('$_prefix${examId}_switches') ?? 0;
      final savedTimestamp = prefs.getInt('$_prefix${examId}_timestamp');

      if (seconds == null || answersJson == null || savedTimestamp == null) {
        return null;
      }

      // Elapsed time calculation: subtract real-world elapsed seconds while app was closed
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedSeconds = ((now - savedTimestamp) / 1000).floor();
      final adjustedSeconds = seconds - elapsedSeconds;

      final Map<String, dynamic> decoded = jsonDecode(answersJson);
      final Map<String, String> selectedAnswers = decoded.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      return {
        'remainingSeconds': adjustedSeconds > 0 ? adjustedSeconds : 0,
        'selectedAnswers': selectedAnswers,
        'switchCount': switches,
        'isExpired': adjustedSeconds <= 0,
      };
    } catch (_) {
      return null;
    }
  }

  /// Clears active exam cache upon submission or cancellation
  static Future<void> clearExamState(String examId) async {
    if (examId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix${examId}_seconds');
      await prefs.remove('$_prefix${examId}_answers');
      await prefs.remove('$_prefix${examId}_switches');
      await prefs.remove('$_prefix${examId}_timestamp');
    } catch (_) {}
  }
}
