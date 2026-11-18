import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/splash/presentation/screens/opening_screen.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/opening',
  routes: [
    GoRoute(
      path: '/opening',
      builder: (context, state) => const OpeningScreen(nextLocation: '/next'),
    ),
    GoRoute(
      path: '/next',
      builder: (context, state) => const Scaffold(body: Text('layar-berikut')),
    ),
  ],
);

Widget _app(GoRouter router, {bool reduceMotion = false}) {
  return MaterialApp.router(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    routerConfig: router,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('opening aman di 360dp @1.3 (${brightness.name})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      await tester.pumpWidget(_app(_router()));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.bySemanticsLabel(AppConfig.appName), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text(AppStrings.openingTagline), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Animasi selesai → layar berikutnya. Ini juga memastikan tidak ada
      // timer pengaman yang tertinggal (aplikasi tidak "macet di logo").
      await tester.pumpAndSettle();
      expect(find.text('layar-berikut'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('opening tetap lanjut saat animasi dimatikan', (tester) async {
    await tester.pumpWidget(_app(_router(), reduceMotion: true));
    await tester.pump();
    await tester.pump();

    expect(find.text('layar-berikut'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
