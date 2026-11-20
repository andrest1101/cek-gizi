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

    // Form kini bersih: tidak ada tombol Atur/Hapus foto berjejer.
    expect(find.text(AppStrings.childPhotoAdjust), findsNothing);
    expect(find.text(AppStrings.childPhotoRemove), findsNothing);
    expect(find.byType(Image), findsOneWidget);

    // Ketuk avatar/pencil → viewer foto (Atur / Hapus / Selesai).
    Future<void> openViewer() async {
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is Tooltip &&
              widget.message ==
                  AppStrings.childPhotoViewerSemantics(
                    AppStrings.childAvatarLabel,
                  ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.childPhotoViewerAdjust), findsOneWidget);
      expect(find.text(AppStrings.childPhotoViewerRemove), findsOneWidget);
      expect(find.text(AppStrings.childPhotoViewerDone), findsOneWidget);
    }

    await openViewer();

    // Atur → crop → pakai → kembali ke form.
    await tester.tap(find.text(AppStrings.childPhotoViewerAdjust));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.childPhotoCropTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.childPhotoCropUse));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);

    // Hapus dari viewer → konfirmasi → pratinjau hilang.
    await openViewer();
    await tester.tap(find.text(AppStrings.childPhotoViewerRemove));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.childPhotoRemoveTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.childDeleteConfirm));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // Yang tersisa hanyalah avatar default (AssetImage), bukan foto use
    // (MemoryImage).
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(images.any((image) => image.image is MemoryImage), isFalse);
    expect(images.any((image) => image.image is AssetImage), isTrue);
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
