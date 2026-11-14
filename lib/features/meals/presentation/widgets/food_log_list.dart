import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/presentation/meal_presentation.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

/// Daftar catatan makan dengan aksi hapus + urungkan. Dipakai di hari ini dan
/// riwayat agar perilaku hapus selalu sama.
class FoodLogList extends ConsumerWidget {
  const FoodLogList({
    super.key,
    required this.logs,
    required this.childId,
    this.showDividers = false,
  });

  final List<FoodLog> logs;
  final String childId;
  final bool showDividers;

  Future<void> _deleteWithUndo(
    BuildContext context,
    WidgetRef ref,
    FoodLog log,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final notifier = ref.read(foodLogsProvider(childId).notifier);
    try {
      await notifier.deleteLog(log.id);
      messenger?.showSnackBar(
        SnackBar(
          content: const Text(AppStrings.makanLogDeleted),
          action: SnackBarAction(
            label: AppStrings.makanUndoAction,
            onPressed: () => notifier.restoreLog(log),
          ),
        ),
      );
    } catch (_) {
      messenger?.showSnackBar(
        const SnackBar(content: Text(AppStrings.makanSaveError)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < logs.length; index++) ...[
          FoodLogRow(
            log: logs[index],
            onDelete: () => _deleteWithUndo(context, ref, logs[index]),
          ),
          if (showDividers && index < logs.length - 1)
            Divider(height: 1, color: colors.outline),
        ],
      ],
    );
  }
}

/// Satu baris catatan: ikon kelompok, nama item, jam, dan tombol hapus.
class FoodLogRow extends StatelessWidget {
  const FoodLogRow({
    super.key,
    required this.log,
    required this.onDelete,
  });

  final FoodLog log;
  final VoidCallback onDelete;

  IconData _leadingIcon() {
    if (log.groups.length == 1) return foodGroupIcon(log.groups.first);
    return Icons.restaurant_rounded;
  }

  bool _isBreastMilk() =>
      log.groups.length == 1 && log.groups.first == 'breast_milk';

  String _time(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}.'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final asi = _isBreastMilk();

    return Dismissible(
      key: ValueKey('log-${log.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: colors.statusAlert.withValues(alpha: 0.14),
        child: Icon(Icons.delete_rounded, color: colors.statusAlert),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 0,
        leading: SizedBox(
          width: 40,
          height: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: asi ? colors.primaryContainer : colors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _leadingIcon(),
              size: 20,
              color: asi ? colors.primary : colors.textSecondary,
            ),
          ),
        ),
        title: Text(
          log.items.map((item) => item.name).join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
        ),
        subtitle: Text(
          _time(log.eatenAt),
          style: textTheme.labelMedium?.copyWith(
            color: colors.textSecondary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        trailing: IconButton(
          tooltip: AppStrings.makanDeleteLog,
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline_rounded,
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
