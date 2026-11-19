import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:cekgizi/shared/widgets/app_logo_mark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('onboarding responsif dan berprogres (${brightness.name})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      SharedPreferences.setMockInitialValues({});
      final prefs = await LocalPrefs.load();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          home: OnboardingScreen(prefs: prefs),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppConfig.appName), findsOneWidget);
      expect(find.byType(AppLogoMark), findsOneWidget);
      expect(find.byKey(const Key('onboarding-progress')), findsOneWidget);
      expect(find.byKey(const Key('onboarding-cta')), findsOneWidget);
      expect(find.text(AppStrings.onboardingEyebrow1), findsOneWidget);
      expect(find.text(AppStrings.onboardingStep(1, 3)), findsOneWidget);
      expect(find.text(AppStrings.onboardingTitle1), findsOneWidget);
      expect(find.text(AppStrings.disclaimer), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text(AppStrings.onboardingNext));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.onboardingEyebrow2), findsOneWidget);
      expect(find.text(AppStrings.onboardingStep(2, 3)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reduce motion menonaktifkan perpindahan animasi', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    SharedPreferences.setMockInitialValues({});
    final prefs = await LocalPrefs.load();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: OnboardingScreen(prefs: prefs),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppStrings.onboardingNext));
    await tester.pump();

    expect(find.text(AppStrings.onboardingEyebrow2), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
