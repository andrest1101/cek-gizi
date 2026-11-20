import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/child_photo_providers.dart';
import 'package:cekgizi/features/children/presentation/screens/child_photo_crop_screen.dart';

/// Atur ulang foto profil yang sudah tersimpan (tab Akun): baca bytes lokal
/// → crop → timpa file → invalidate path provider.
Future<void> adjustSavedChildPhoto(
  BuildContext context,
  WidgetRef ref, {
  required ChildProfile child,
}) async {
  final path = ref.read(childPhotoPathProvider(child.id)).value;
  if (path == null) return;
  final Uint8List source;
  try {
    source = await File(path).readAsBytes();
  } catch (_) {
    return;
  }
  if (!context.mounted) return;
  final cropped = await context.push<Uint8List>(
    '/children/photo-crop',
    extra: ChildPhotoCropArgs(bytes: source),
  );
  if (cropped == null) return;
  await ref.read(childPhotoStoreProvider).save(child.id, cropped);
  ref.invalidate(childPhotoPathProvider(child.id));
}

/// Hapus foto profil lokal milik anak (tab Akun).
Future<void> deleteSavedChildPhoto(WidgetRef ref, String childId) async {
  await ref.read(childPhotoStoreProvider).delete(childId);
  ref.invalidate(childPhotoPathProvider(childId));
}
