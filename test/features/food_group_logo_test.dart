import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/presentation/widgets/food_group_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('semua 8 logo kelompok termuat tanpa error', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final code in FoodGroup.allCodes)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: FoodGroupLogo(code: code, size: 34),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsNWidgets(FoodGroup.allCodes.length));
    expect(tester.takeException(), isNull);
  });

  testWidgets('semua 8 logo kelompok termuat pada dark theme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final code in FoodGroup.allCodes)
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: FoodGroupLogo(code: code, size: 34),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsNWidgets(FoodGroup.allCodes.length));
  });

  testWidgets('kode tak dikenal menampilkan fallback tanpa crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: SizedBox(
            width: 40,
            height: 40,
            child: FoodGroupLogo(code: 'bukan_kelompok', size: 34),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
  });
}
