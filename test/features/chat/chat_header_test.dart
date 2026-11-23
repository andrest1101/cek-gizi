import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/theme/app_colors.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/chat/presentation/widgets/chat_header.dart';
import 'package:cekgizi/features/chat/presentation/widgets/tanya_ai_mark.dart';

/// Header Tanya Gizi memakai mark AI asli, bukan ikon Material generik.
/// Mark dimuat dari aset mono-putih lalu di-tint ke `colors.primary` agar
/// kontras & identitas terjaga di light maupun dark (PRD §7.2, §7.7).
void main() {
  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('header menampilkan mark AI dari aset (${brightness.name})', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: brightness == Brightness.light
              ? AppTheme.light()
              : AppTheme.dark(),
          home: Scaffold(
            body: ChatHeader(
              onClose: () {},
              onClearHistory: () {},
              canClear: true,
            ),
          ),
        ),
      );

      // Aset mono-putih dipakai (bukan Icons.spa_rounded generik).
      final mark = tester.widget<Image>(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName == TanyaAiMark.assetPath,
        ),
      );
      expect(mark.width, 24);
      expect(mark.colorBlendMode, BlendMode.srcIn);
      expect(find.byIcon(Icons.spa_rounded), findsNothing);

      // Tint mengikuti token primary tema.
      final expected = brightness == Brightness.light
          ? AppColors.light.primary
          : AppColors.dark.primary;
      expect(mark.color, expected);

      // Peran asisten tetap diumumkan lewat Semantics induk.
      expect(
        find.ancestor(
          of: find.byType(TanyaAiMark),
          matching: find.bySemanticsLabel('Asisten ${AppConfig.appName}'),
        ),
        findsOneWidget,
      );
    });
  }
}
