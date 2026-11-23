import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_colors.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/chat/domain/entities/chat_message.dart';
import 'package:cekgizi/features/chat/presentation/widgets/chat_message_tile.dart';

import '../../fakes.dart';

/// Kontrak visual pesan (UX-18): jawaban asisten = lembar `surface` tanpa
/// avatar/nama berulang; pesan pengguna = pil `primary` di kanan.
void main() {
  Future<void> pumpTile(
    WidgetTester tester,
    Widget child, {
    Brightness brightness = Brightness.light,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.light
            ? AppTheme.light()
            : AppTheme.dark(),
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  /// Cek label `Semantics` langsung dari pohon widget (tanpa perlu
  /// mengompilasi pohon semantik).
  bool hasSemanticsLabel(WidgetTester tester, String label) => tester
      .widgetList<Semantics>(find.byType(Semantics))
      .any((widget) => widget.properties.label == label);

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets(
      'jawaban asisten berupa lembar surface tanpa identitas berulang '
      '(${brightness.name})',
      (tester) async {
        await pumpTile(
          tester,
          ChatMessageTile(
            message: fakeChatMessage(
              id: 'a1',
              role: ChatRole.assistant,
              content: '**Camilan** sehat:\n- pisang\n- pepaya',
              createdAt: DateTime(2026, 11, 22, 22, 23),
            ),
          ),
          brightness: brightness,
        );

        // Identitas hanya di header: tidak ada avatar/nama asisten di pesan.
        expect(find.text(AppConfig.appName), findsNothing);
        expect(find.byIcon(Icons.spa_rounded), findsNothing);

        // Peran tetap diumumkan ke pembaca layar.
        expect(
          hasSemanticsLabel(tester, AppStrings.tanyaAnswerSemantics()),
          isTrue,
        );

        // Jawaban dirender tanpa penanda markdown mentah.
        expect(find.textContaining('Camilan'), findsOneWidget);
        expect(find.textContaining('**'), findsNothing);
        expect(find.textContaining('- '), findsNothing);
        expect(find.text('22.23'), findsOneWidget);

        // Lembar memakai `surface` (bukan background) sebagai penanda jawaban.
        final card = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(ChatMessageTile),
                matching: find.byType(Container),
              )
              .first,
        );
        final decoration = card.decoration! as BoxDecoration;
        final expected = brightness == Brightness.light
            ? AppColors.light.surface
            : AppColors.dark.surface;
        expect(decoration.color, expected);
        expect(decoration.border, isNotNull);
      },
    );
  }

  testWidgets('pesan pengguna tetap pil primary dan punya label semantik', (
    tester,
  ) async {
    await pumpTile(
      tester,
      ChatMessageTile(
        message: fakeChatMessage(
          id: 'u1',
          role: ChatRole.user,
          content: 'Camilan sehat untuk anak',
          createdAt: DateTime(2026, 11, 22, 22, 21),
        ),
      ),
    );

    expect(
      hasSemanticsLabel(tester, AppStrings.tanyaUserMessageSemantics),
      isTrue,
    );
    expect(find.text('Camilan sehat untuk anak'), findsOneWidget);
    expect(find.text('22.21'), findsOneWidget);
    expect(find.byIcon(Icons.spa_rounded), findsNothing);
  });
}
