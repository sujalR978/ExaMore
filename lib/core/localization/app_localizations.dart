import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'selected_language';
  String _currentLanguage = 'English';
  Locale _locale = const Locale('en', 'US');

  String get currentLanguage => _currentLanguage;
  Locale get locale => _locale;

  AppLanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey) ?? 'English';
    _currentLanguage = saved;
    _locale = _toLocale(saved);
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    _locale = _toLocale(language);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, language);
    notifyListeners();
  }

  static Locale _toLocale(String language) {
    switch (language.toLowerCase()) {
      case 'spanish':
        return const Locale('es', 'ES');
      case 'french':
        return const Locale('fr', 'FR');
      case 'hindi':
        return const Locale('hi', 'IN');
      case 'german':
        return const Locale('de', 'DE');
      case 'english':
      default:
        return const Locale('en', 'US');
    }
  }

  /// Format date using the selected locale (COM-ACC-007)
  String formatDate(DateTime date, {String format = 'yMMMd'}) {
    try {
      return DateFormat(format, _locale.languageCode).format(date);
    } catch (_) {
      return DateFormat.yMMMd().format(date);
    }
  }

  /// Format time using the selected locale (COM-ACC-007)
  String formatTime(DateTime time) {
    try {
      return DateFormat.jm(_locale.languageCode).format(time);
    } catch (_) {
      return DateFormat.jm().format(time);
    }
  }

  /// Format currency with symbol for the selected locale (COM-ACC-007)
  String formatCurrency(double amount) {
    switch (_locale.languageCode) {
      case 'es':
      case 'fr':
      case 'de':
        return '€${amount.toStringAsFixed(2)}';
      case 'hi':
        return '₹${amount.toStringAsFixed(2)}';
      case 'en':
      default:
        return '\$${amount.toStringAsFixed(2)}';
    }
  }
}

class AppLocalizations {
  final String language;

  AppLocalizations(this.language);

  static final Map<String, Map<String, String>> _localizedValues = {
    'English': {
      'app_title': 'ExaMore',
      'login': 'Login',
      'register': 'Register',
      'forgot_password': 'Forgot Password?',
      'home': 'Home',
      'exams': 'Exams',
      'profile': 'Profile',
      'settings': 'Settings',
      'classrooms': 'Classrooms',
      'exams_taken': 'Exams Taken',
      'avg_score': 'Avg. Score',
      'save': 'Save Changes',
      'cancel': 'Cancel',
      'discard': 'Discard',
      'email': 'Email Address',
      'password': 'Password',
      'phone': 'Phone Number',
      'search': 'Search assessments...',
      'no_data': 'No assessments available at this time',
      'offline_msg': 'You are currently offline. Showing cached assessments.',
      'retry': 'Retry',
    },
    'Spanish': {
      'app_title': 'ExaMore',
      'login': 'Iniciar Sesión',
      'register': 'Registrarse',
      'forgot_password': '¿Olvidó su contraseña?',
      'home': 'Inicio',
      'exams': 'Exámenes',
      'profile': 'Perfil',
      'settings': 'Ajustes',
      'classrooms': 'Aulas',
      'exams_taken': 'Exámenes Realizados',
      'avg_score': 'Puntuación Media',
      'save': 'Guardar Cambios',
      'cancel': 'Cancelar',
      'discard': 'Descartar',
      'email': 'Correo Electrónico',
      'password': 'Contraseña',
      'phone': 'Número de Teléfono',
      'search': 'Buscar evaluaciones...',
      'no_data': 'No hay evaluaciones disponibles en este momento',
      'offline_msg': 'Estás desconectado. Mostrando evaluaciones en caché.',
      'retry': 'Reintentar',
    },
    'French': {
      'app_title': 'ExaMore',
      'login': 'Connexion',
      'register': "S'inscrire",
      'forgot_password': 'Mot de passe oublié ?',
      'home': 'Accueil',
      'exams': 'Examens',
      'profile': 'Profil',
      'settings': 'Paramètres',
      'classrooms': 'Classes',
      'exams_taken': 'Examens Passés',
      'avg_score': 'Note Moyenne',
      'save': 'Enregistrer les modifications',
      'cancel': 'Annuler',
      'discard': 'Abandonner',
      'email': 'Adresse E-mail',
      'password': 'Mot de passe',
      'phone': 'Numéro de téléphone',
      'search': 'Rechercher des évaluations...',
      'no_data': 'Aucune évaluation disponible pour le moment',
      'offline_msg': 'Vous êtes hors ligne. Affichage des examens en cache.',
      'retry': 'Réessayer',
    },
    'Hindi': {
      'app_title': 'ExaMore',
      'login': 'लॉग इन करें',
      'register': 'पंजीकरण करें',
      'forgot_password': 'पासवर्ड भूल गए?',
      'home': 'होम',
      'exams': 'परीक्षाएं',
      'profile': 'प्रोफाइल',
      'settings': 'सेटिंग्स',
      'classrooms': 'कक्षाएं',
      'exams_taken': 'दी गई परीक्षाएं',
      'avg_score': 'औसत अंक',
      'save': 'बदलाव सहेजें',
      'cancel': 'रद्द करें',
      'discard': 'खारिज करें',
      'email': 'ईमेल पता',
      'password': 'पासवर्ड',
      'phone': 'फ़ोन नंबर',
      'search': 'मूल्यांकन खोजें...',
      'no_data': 'वर्तमान में कोई मूल्यांकन उपलब्ध नहीं है',
      'offline_msg': 'आप ऑफ़लाइन हैं। कैश्ड परीक्षाएं दिखाई जा रही हैं।',
      'retry': 'पुनः प्रयास करें',
    },
    'German': {
      'app_title': 'ExaMore',
      'login': 'Anmelden',
      'register': 'Registrieren',
      'forgot_password': 'Passwort vergessen?',
      'home': 'Startseite',
      'exams': 'Prüfungen',
      'profile': 'Profil',
      'settings': 'Einstellungen',
      'classrooms': 'Klassen',
      'exams_taken': 'Abgelegte Prüfungen',
      'avg_score': 'Durchschnittsnote',
      'save': 'Änderungen speichern',
      'cancel': 'Abbrechen',
      'discard': 'Verwerfen',
      'email': 'E-Mail-Adresse',
      'password': 'Passwort',
      'phone': 'Telefonnummer',
      'search': 'Bewertungen suchen...',
      'no_data': 'Derzeit sind keine Bewertungen verfügbar',
      'offline_msg': 'Sie sind offline. Zwischengespeicherte Prüfungen werden angezeigt.',
      'retry': 'Wiederholen',
    },
  };

  String translate(String key) {
    return _localizedValues[language]?[key] ?? _localizedValues['English']?[key] ?? key;
  }
}
