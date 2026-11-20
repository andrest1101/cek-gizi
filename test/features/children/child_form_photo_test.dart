import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/data/services/child_photo_editor.dart';
import 'package:cekgizi/features/children/data/services/child_photo_service.dart';
import 'package:cekgizi/features/children/presentation/providers/child_photo_providers.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/children/presentation/screens/child_form_screen.dart';
import 'package:cekgizi/features/children/presentation/screens/child_photo_crop_screen.dart';

import '../../fakes.dart';

/// Regresi: pilih foto → crop → pratinjau muncul → hapus foto → teks hilang.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('pilih foto dari galeri, atur di crop, lalu bisa dihapus', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await LocalPrefs.load();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ChildFormScreen(),
        ),
        GoRoute(
          path: '/children/photo-crop',
          builder: (context, state) =>
              ChildPhotoCropScreen(args: state.extra! as ChildPhotoCropArgs),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localPrefsProvider.overrideWithValue(prefs),
          childPhotoPickerProvider.overrideWithValue(
            const _FakeChildPhotoPicker(),
          ),
          childPhotoEditorProvider.overrideWithValue(
            const _FakeChildPhotoEditor(),
          ),
          childRepositoryProvider.overrideWithValue(FakeChildRepository()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text(AppStrings.childPhotoRemove), findsNothing);

    await tester.tap(find.text(AppStrings.childPhotoGallery));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Crop screen tampil.
    expect(find.text(AppStrings.childPhotoCropTitle), findsOneWidget);
    expect(find.byIcon(Icons.zoom_in_rounded), findsOneWidget);
    await tester.tap(find.text(AppStrings.childPhotoCropUse));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Kembali ke form: pratinjau + tombol Atur foto + Hapus foto muncul.
    expect(find.text(AppStrings.childPhotoAdjust), findsOneWidget);
    expect(find.text(AppStrings.childPhotoRemove), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Atur ulang foto dari pratinjau.
    await tester.tap(find.text(AppStrings.childPhotoAdjust));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.childPhotoCropTitle), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.childPhotoCropCancel));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.childPhotoAdjust), findsOneWidget);

    // Hapus foto → konfirmasi → pratinjau hilang.
    await tester.tap(find.text(AppStrings.childPhotoRemove));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.childPhotoRemoveTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.childDeleteConfirm));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsNothing);
    expect(find.text(AppStrings.childPhotoRemove), findsNothing);
  });
}

class _FakeChildPhotoPicker implements ChildPhotoPicker {
  const _FakeChildPhotoPicker();

  static final Uint8List _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
  );

  @override
  Future<Uint8List?> pick(ChildPhotoSource source) async => _png;
}

class _FakeChildPhotoEditor implements ChildPhotoEditor {
  const _FakeChildPhotoEditor();

  @override
  Future<Uint8List?> crop(GlobalKey boundaryKey) async =>
      _FakeChildPhotoPicker._png;
}
