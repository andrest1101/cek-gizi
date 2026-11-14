import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

/// Aksi catat/hapus satu kelompok pangan yang dipakai bersama oleh checklist
/// Makan dan tombol aksi pada tips Beranda.
///
/// Aturan:
/// - Belum tercatat → simpan satu log, tampilkan snackbar dengan "Urungkan".
/// - Sudah tercatat → TIDAK menambah log duplikat; tawarkan hapus.

/// Catat satu kelompok pangan untuk hari ini.
Future<void> logFoodGroup(
  BuildContext context,
  WidgetRef ref, {
  required String childId,
  required String groupCode,
  required String groupLabel,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final notifier = ref.read(foodLogsProvider(childId).notifier);

  try {
    if (groupCode == 'breast_milk') {
      await notifier.addBreastMilkToday();
      messenger?.showSnackBar(
        SnackBar(
          content: const Text(AppStrings.makanAsiLoggedFeedback),
          action: SnackBarAction(
            label: AppStrings.makanUndoAction,
            onPressed: () => notifier.removeBreastMilkToday(),
          ),
        ),
      );
      return;
    }

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

/// Tawarkan hapus untuk kelompok yang sudah tercatat hari ini.
Future<void> removeFoodGroup(
  BuildContext context,
  WidgetRef ref, {
  required String childId,
  required String groupCode,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final notifier = ref.read(foodLogsProvider(childId).notifier);

  try {
    if (groupCode == 'breast_milk') {
      await notifier.removeBreastMilkToday();
      messenger?.showSnackBar(
        const SnackBar(content: Text(AppStrings.makanAsiRemovedFeedback)),
      );
      return;
    }
    await notifier.removeGroupToday(groupCode);
    messenger?.showSnackBar(
      const SnackBar(content: Text(AppStrings.makanLogDeleted)),
    );
  } catch (_) {
    messenger?.showSnackBar(
      const SnackBar(content: Text(AppStrings.makanSaveError)),
    );
  }
}

/// Beri tahu bahwa kelompok sudah tercatat dan tawarkan hapus.
void showGroupAlreadyLogged(
  BuildContext context,
  WidgetRef ref, {
  required String childId,
  required String groupCode,
  required String groupLabel,
  required bool canRemove,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        canRemove
            ? AppStrings.makanGroupAlreadyLogged(groupLabel)
            : AppStrings.makanGroupInCombinedLog,
      ),
      action: canRemove
          ? SnackBarAction(
              label: AppStrings.makanDeleteLog,
              onPressed: () => removeFoodGroup(
                context,
                ref,
                childId: childId,
                groupCode: groupCode,
              ),
            )
          : null,
    ),
  );
}

/// True bila semua catatan hari ini yang memuat [groupCode] adalah catatan
/// satu kelompok. Hanya kondisi itu yang bisa dihapus dari checklist tanpa
/// membuang kelompok lain yang ikut tercatat dalam catatan gabungan.
bool canRemoveGroupFromChecklist(
  Iterable<List<String>> logGroups,
  String groupCode,
) {
  var found = false;
  for (final groups in logGroups) {
    if (!groups.contains(groupCode)) continue;
    found = true;
    if (groups.length != 1 || groups.first != groupCode) return false;
  }
  return found;
}
