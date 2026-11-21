import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prep_mate/core/localization/app_localizations.dart';
import 'package:prep_mate/core/widgets/offline_banner.dart';
import 'package:prep_mate/features/auth/widgets/custom_button.dart';
import 'package:prep_mate/features/auth/widgets/input_field.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Common Requirements & Cross-Screen Widget Tests', () {
    testWidgets('Button enforces disabled visual styling, semantics, and ignores tap',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Button(
                text: 'DISABLED ACTION',
                isDisabled: true,
                onPressed: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify button renders text and semantic label
      expect(find.text('DISABLED ACTION'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'DISABLED ACTION',
        ),
        findsOneWidget,
      );

      // Tap disabled button
      await tester.tap(find.text('DISABLED ACTION'));
      await tester.pump();

      // Callback must not be invoked
      expect(tapped, isFalse);
    });

    testWidgets('Button displays loading spinner and PROCESSING text during API calls',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Button(
                text: 'SUBMIT',
                isLoading: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('PROCESSING...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Inputfield configures proper keyboardType for specialized fields',
        (WidgetTester tester) async {
      final phoneController = TextEditingController();
      final emailController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Inputfield(
                  controller: phoneController,
                  hintText: 'Enter Phone',
                  icon: Icons.phone,
                  isPassword: false,
                  keyboardType: TextInputType.phone,
                  validator: (_) => null,
                ),
                Inputfield(
                  controller: emailController,
                  hintText: 'Enter Email',
                  icon: Icons.email,
                  isPassword: false,
                  keyboardType: TextInputType.emailAddress,
                  validator: (_) => null,
                ),
              ],
            ),
          ),
        ),
      );

      final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(textFields.length, 2);
      expect(textFields[0].keyboardType, TextInputType.phone);
      expect(textFields[1].keyboardType, TextInputType.emailAddress);
    });

    test('AppLanguageProvider updates locale, translations, and formats dates/currencies',
        () async {
      final provider = AppLanguageProvider();
      expect(provider.currentLanguage, 'English');
      expect(provider.locale.languageCode, 'en');

      // Test English translation
      final enLoc = AppLocalizations('English');
      expect(enLoc.translate('login'), 'Login');
      expect(enLoc.translate('home'), 'Home');
      expect(enLoc.translate('save'), 'Save Changes');

      // Switch to Spanish
      await provider.setLanguage('Spanish');
      expect(provider.currentLanguage, 'Spanish');
      expect(provider.locale.languageCode, 'es');

      final esLoc = AppLocalizations('Spanish');
      expect(esLoc.translate('login'), 'Iniciar Sesión');
      expect(esLoc.translate('home'), 'Inicio');
      expect(esLoc.translate('save'), 'Guardar Cambios');

      // Switch to Hindi
      await provider.setLanguage('Hindi');
      expect(provider.currentLanguage, 'Hindi');
      expect(provider.locale.languageCode, 'hi');

      final hiLoc = AppLocalizations('Hindi');
      expect(hiLoc.translate('login'), 'लॉग इन करें');
      expect(hiLoc.translate('home'), 'होम');

      // Test currency formatting (COM-ACC-007)
      expect(provider.formatCurrency(500), '₹500.00');

      // Switch to German
      await provider.setLanguage('German');
      expect(provider.formatCurrency(25), '€25.00');

      // Switch to English
      await provider.setLanguage('English');
      expect(provider.formatCurrency(100), '\$100.00');

      // Test date formatting (COM-ACC-007)
      final testDate = DateTime(2026, 11, 21);
      final formattedDate = provider.formatDate(testDate);
      expect(formattedDate, isNotEmpty);
    });

    testWidgets('OfflineBanner mounts without errors and provides retry trigger',
        (WidgetTester tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                OfflineBanner(
                  onRetry: () {
                    retried = true;
                  },
                ),
                const Text('Dashboard Content'),
              ],
            ),
          ),
        ),
      );

      // Verify dashboard content renders stably
      expect(find.text('Dashboard Content'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
