import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/account/presentation/providers/account_providers.dart';
import 'package:cekgizi/shared/widgets/tonal_icon_circle.dart';

/// Dialog konfirmasi sebelum Hapus Akun dijalankan.
///
/// Tampil: judul + uraian permanen, Cancel + Hapus akun (48dp). While
/// hapus sedang berjalan (`state.isBusy`), tombol Confirm dimatikan —
/// user bisa mencancel melalui layers belakang.
class AccountDeleteDialog extends ConsumerWidget {
  const AccountDeleteDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final state = ref.watch(deleteAccountProvider);
    return AlertDialog(
      icon: TonalIconCircle(
        icon: Icons.delete_forever_rounded,
        iconSemantics: AppStrings.accountDeleteTitle,
        iconSize: 20,
        size: 52,
        backgroundColor: colors.statusAlert.withValues(alpha: 0.12),
        iconColor: colors.statusAlert,
      ),
      title: Text(AppStrings.accountDeleteTitle),
      content: Text(
        AppStrings.accountDeleteBody,
        style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
          child: const Text(AppStrings.accountDeleteCancel),
        ),
        FilledButton.icon(
          onPressed: state.isBusy ? null : () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          icon: const Icon(Icons.delete_forever_rounded, size: 18),
          label: const Text(AppStrings.accountDeleteConfirm),
        ),
      ],
    );
  }
}

/// Tampilkan dialog, lalu jalankan hapus akun bila user memilih Confirm.
Future<void> confirmAccountDelete(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => const AccountDeleteDialog(),
  );
  if (confirmed == true && context.mounted) {
    ref.read(deleteAccountProvider.notifier).delete();
  }
}
