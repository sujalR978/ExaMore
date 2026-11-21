import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prep_mate/core/theme/theme_provider.dart';
import 'package:prep_mate/main.dart';
import 'package:provider/provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
  });

  testWidgets('App smoke test: boots with ThemeProvider and mounts Splash screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );

    // Verify ExaMore branding is displayed on Splash screen
    expect(find.text("ExaMore"), findsOneWidget);
    expect(find.text("Smart Exams. Better Results."), findsOneWidget);

    // Drain splash duration timers
    await tester.pump(const Duration(seconds: 4));
  });
}
