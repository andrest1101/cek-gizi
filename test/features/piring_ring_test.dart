import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/meals/presentation/widgets/piring_ring.dart';

void main() {
  group('PiringRing.segmentGapDegrees', () {
    test('hero 196dp / stroke 18dp: jarak visual antar ujung ±22dp', () {
      const size = 196.0;
      const stroke = 18.0;
      final gap = PiringRing.segmentGapDegrees(
        strokeWidth: stroke,
        size: size,
        segments: 8,
      );
      final radius = (size - stroke) / 2;
      final gapDp = gap * math.pi / 180 * radius;
      // (stroke + 4dp) — jarak yang terlihat tetap ±4dp setelah round cap.
      expect(gapDp, closeTo(stroke + 4, 0.01));
      // Busur tetap terbaca (tidak hilang karena celah).
      expect(360 / 8 - gap, greaterThan(20));
    });

    test('semesta 7 kelompok memakai rumus jarak yang sama', () {
      final gap8 = PiringRing.segmentGapDegrees(
        strokeWidth: 18,
        size: 196,
        segments: 8,
      );
      final gap7 = PiringRing.segmentGapDegrees(
        strokeWidth: 18,
        size: 196,
        segments: 7,
      );
      expect(gap7, closeTo(gap8, 0.001));
    });

    test('celah dibatasi agar busur tidak hilang pada ring kecil', () {
      final gap = PiringRing.segmentGapDegrees(
        strokeWidth: 12,
        size: 40,
        segments: 8,
      );
      final sweep = 360 / 8 - gap;
      expect(sweep, greaterThan(0));
      expect(gap, lessThanOrEqualTo(360 / 8 * 0.45));
    });
  });

  testWidgets('PiringRing besar menampilkan n/total + label semantik', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PiringRing(
            met: const {'grains_tubers', 'eggs'},
            size: 196,
            showCount: false,
          ),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(AppStrings.piringGroupsMetSemantics(2, 8)),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('PiringProgressRing menampilkan angka tanpa busur ganda', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: PiringProgressRing(met: 3, total: 8),
        ),
      ),
    );
    expect(find.text('3/8'), findsOneWidget);
    expect(
      find.bySemanticsLabel(AppStrings.piringGroupsMetSemantics(3, 8)),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('PiringProgressRing aman saat total 0', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: PiringProgressRing(met: 0, total: 0),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('0/1'), findsOneWidget);
  });
}
