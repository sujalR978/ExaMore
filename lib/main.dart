import 'package:flutter/material.dart';
import 'package:prep_mate/core/theme/app_theme.dart';
import 'package:prep_mate/core/theme/theme_provider.dart';

import 'package:prep_mate/features/Auth/screens/splashScreen.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => ThemeProvider(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,

          themeMode: themeProvider.themeMode,
          home: const Splash(),
        );
      },
    );
  }
}
