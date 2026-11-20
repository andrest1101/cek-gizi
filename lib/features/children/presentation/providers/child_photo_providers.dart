import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/features/children/data/datasources/child_photo_store.dart';
import 'package:cekgizi/features/children/data/services/child_photo_editor.dart';
import 'package:cekgizi/features/children/data/services/child_photo_service.dart';

/// Satu instance store agar cache path di memori tetap konsisten.
final childPhotoStoreProvider = Provider<ChildPhotoStore>(
  (ref) => LocalChildPhotoStore(),
);

final childPhotoPickerProvider = Provider<ChildPhotoPicker>(
  (ref) => const ImagePickerChildPhotoPicker(),
);

/// Pemotong foto profil (tangkap area lingkaran → JPEG 512px tanpa EXIF).
final childPhotoEditorProvider = Provider<ChildPhotoEditor>(
  (ref) => const RepaintBoundaryChildPhotoEditor(),
);

/// Path foto lokal untuk [childId]. Null berarti belum ada foto (atau
/// plugin penyimpanan tidak tersedia, mis. di widget test) sehingga avatar
/// default yang tampil.
final childPhotoPathProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, childId) async {
      try {
        return await ref.watch(childPhotoStoreProvider).pathFor(childId);
      } catch (_) {
        return null;
      }
    });
