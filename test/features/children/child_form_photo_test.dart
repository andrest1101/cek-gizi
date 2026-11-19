import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/data/services/child_photo_service.dart';
import 'package:cekgizi/features/children/presentation/providers/child_photo_providers.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/children/presentation/screens/child_form_screen.dart';

import '../../fakes.dart';

/// Regresi alur foto profil di formulir anak: pilih foto → pratinjau muncul
/// → hapus foto → teks hilang. Kompresi nyata tidak dijalankan (plugin
/// kamera/galeri diganti fake), tetapi state UI-nya diuji penuh.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'pilih foto dari kamera menampilkan pratinjau lalu bisa dihapus',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await LocalPrefs.load();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localPrefsProvider.overrideWithValue(prefs),
            childPhotoPickerProvider.overrideWithValue(
              const _FakeChildPhotoPicker(),
            ),
            childRepositoryProvider.overrideWithValue(FakeChildRepository()),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            home: const ChildFormScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Sebelum memilih: tombol hapus belum tampil.
      expect(find.text(AppStrings.childPhotoRemove), findsNothing);

      await tester.tap(find.text(AppStrings.childPhotoTake));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Pratinjau (widget Image) & tombol hapus muncul.
      expect(find.byType(Image), findsOneWidget);
      expect(find.text(AppStrings.childPhotoRemove), findsOneWidget);

      // Hapus foto → dialog konfirmasi → pratinjau hilang.
      await tester.tap(find.text(AppStrings.childPhotoRemove));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.childPhotoRemoveTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.childDeleteConfirm));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsNothing);
      expect(find.text(AppStrings.childPhotoRemove), findsNothing);
    },
  );
}

/// Picker palsu: langsung mengembalikan byte foto.
class _FakeChildPhotoPicker implements ChildPhotoPicker {
  const _FakeChildPhotoPicker();

  @override
  Future<Uint8List?> pick(ChildPhotoSource source) async {
    // Byte bukan gambar valid - pratinjau diuji lewat widget state,
    // bukan lewat decode codec.
    return Uint8List.fromList(const [0, 1, 2, 3, 4, 5]);
  }
}
