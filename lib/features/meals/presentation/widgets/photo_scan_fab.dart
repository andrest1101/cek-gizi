import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';

/// FAB "Foto makanan" (PRD §6.2, §6.4) - hanya tampil untuk anak >=6 bulan.
/// Menyembunyikan FAB untuk bayi di bawah 6 bulan karena scanner dinonaktifkan.
class PhotoScanFab extends ConsumerWidget {
  const PhotoScanFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider).value;
    if (child == null) return const SizedBox.shrink();
    final ageMonths = child.ageInCompletedMonths(DateTime.now());
    if (!DietaryDiversity.isScanSupportedForAge(ageMonths)) {
      return const SizedBox.shrink();
    }
    return FloatingActionButton.extended(
      heroTag: null,
      onPressed: () => context.push('/scan'),
      icon: const Icon(Icons.photo_camera_rounded),
      label: const Text(AppStrings.photoScanFab),
      tooltip: AppStrings.photoScanFabSemantics,
    );
  }
}
