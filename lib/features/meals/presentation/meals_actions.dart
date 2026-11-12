import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

/// Aksi catat kelompok pangan yang dipakai bersama oleh grid di layar Makan
/// dan tombol aksi pada tips Beranda.
///
/// Aturan:
/// - Belum tercatat → simpan satu log, tampilkan snackbar dengan "Urungkan".
/// - Sudah tercatat → TIDAK menambah log duplikat; tawarkan hapus.
Future<void> logFoodGroup(
  BuildContext context,
  WidgetRef ref, {
  required String childId,
  required String groupCode,
  required String groupLabel,
  required bool alreadyLogged,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final notifier = ref.read(foodLogsProvider(childId).notifier);

  if (alreadyLogged) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(AppStrings.makanGroupAlreadyLogged(groupLabel)),
        action: SnackBarAction(
          label: AppStrings.makanDeleteLog,
          onPressed: () => _removeGroup(context, ref, childId, groupCode),
        ),
      ),
    );
    return;
  }

  try {
    final log = await notifier.addManualGroup(
      groupCode: groupCode,
      groupLabel: groupLabel,
    );
    messenger?.showSnackBar(
      SnackBar(
        content: Text(AppStrings.makanLogAdded(groupLabel)),
        action: SnackBarAction(
          label: AppStrings.makanUndoAction,
          onPressed: () => notifier.deleteLog(log.id),
        ),
      ),
    );
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(content: Text(AppStrings.makanSaveError)),
    );
  }
}

Future<void> _removeGroup(
  BuildContext context,
  WidgetRef ref,
  String childId,
  String groupCode,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await ref
        .read(foodLogsProvider(childId).notifier)
        .removeGroupToday(groupCode);
    messenger?.showSnackBar(
      const SnackBar(content: Text(AppStrings.makanLogDeleted)),
    );
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(content: Text(AppStrings.makanSaveError)),
    );
  }
}
