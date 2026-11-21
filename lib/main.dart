import 'package:flutter/material.dart';
import 'package:prep_mate/core/localization/app_localizations.dart';
import 'package:prep_mate/core/services/notification_service.dart';
import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/core/theme/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:prep_mate/features/auth/screens/splash_screen.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase initialization error in main(): $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppLanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final languageProvider = Provider.of<AppLanguageProvider?>(context);

    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'ExaMore',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider?.themeMode ?? ThemeMode.system,
      locale: languageProvider?.locale,
      home: const Splash(),
    );
  }
}
