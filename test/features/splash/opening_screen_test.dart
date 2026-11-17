import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/splash/presentation/screens/opening_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('opening aman di 360dp @1.3 (${brightness.name})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const OpeningScreen(nextLocation: '/next'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.bySemanticsLabel(AppConfig.appName), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text(AppStrings.openingTagline), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
