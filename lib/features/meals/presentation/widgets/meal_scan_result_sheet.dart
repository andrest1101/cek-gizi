import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/entities/meal_scan.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';

/// Sheet hasil scan makanan (PRD §6.4, human-in-the-loop).
///
/// Menampilkan item terdeteksi sebagai baris yang bisa dihapus, diubah,
/// atau ditambah manual; porsi opsional; wajib pilih jenis makan.
/// "Simpan ke catatan" membuat satu log `source=scan` dengan item final.
class MealScanResultSheet extends ConsumerStatefulWidget {
  const MealScanResultSheet({
    super.key,
    required this.result,
    required this.childId,
  });

  final MealScanResult result;
  final String childId;

  @override
  ConsumerState<MealScanResultSheet> createState() =>
      _MealScanResultSheetState();
}

enum _ScanPortion { none, little, medium, finished }

class _EditableItem {
  _EditableItem({
    required this.name,
    required this.groups,
    this.confidence = 1,
  });

  String name;
  Set<String> groups;
  _ScanPortion portion = _ScanPortion.none;
  double confidence;

  static const portions = [_ScanPortion.little, _ScanPortion.medium, _ScanPortion.finished];
}

class _MealScanResultSheetState extends ConsumerState<MealScanResultSheet> {
  final _addController = TextEditingController();
  late final List<_EditableItem> _items;
  MealType? _mealType;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _items = [
      for (final item in widget.result.items)
        _EditableItem(
          name: item.name,
          groups: {...item.groups},
          confidence: item.confidence,
        ),
    ];
    _mealType = _defaultMealType(DateTime.now());
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }

  static MealType _defaultMealType(DateTime now) {
    final hour = now.hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 14) return MealType.lunch;
    if (hour < 17) return MealType.snack;
    return MealType.dinner;
  }

  static String _portionToString(_ScanPortion portion) => switch (portion) {
        _ScanPortion.little => 'sedikit',
        _ScanPortion.medium => 'sedang',
        _ScanPortion.finished => 'habis',
        _ScanPortion.none => '',
      };

  bool get _canSave =>
      !_saving &&
      _mealType != null &&
      _items.isNotEmpty &&
      _items.every((item) => item.groups.isNotEmpty);

  Future<void> _save() async {
    if (!_canSave) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final child = ref.read(selectedChildProvider).value;
      if (child == null) {
        throw StateError('Tidak ada anak yang dipilih.');
      }
      final logItems = [
        for (final item in _items)
          FoodLogItem(
            name: item.name,
            groups: item.groups.toList(),
            portion: item.portion == _ScanPortion.none
                ? null
                : _portionToString(item.portion),
          ),
      ];
      final log = await ref
          .read(foodLogsProvider(widget.childId).notifier)
          .addScanLog(items: logItems, mealType: _mealType!);
      if (!mounted) return;
      if (log.id.isEmpty) {
        throw StateError('Log tersimpan tanpa id.');
      }
      Navigator.pop(context, true);
      messenger?.showSnackBar(
        const SnackBar(content: Text(AppStrings.scanSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saveError = AppStrings.scanSaveError;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan provider anak & catatan makan ter-subscribe sejak awal.
    // `foodLogsProvider` autoDispose: tanpa listener, ref notifier mati
    // setelah build selesai dan `addScanLog` akan memakai ref yang disposed.
    ref.watch(selectedChildProvider);
    ref.watch(foodLogsProvider(widget.childId));
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
        child: Container(
          color: colors.surface,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 720),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _DragHandle()),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.restaurant_rounded,
                            color: colors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  AppStrings.scanSheetTitle,
                                  style: textTheme.titleMedium?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppStrings.scanSheetSubtitle,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_items.isEmpty)
                      _EmptyItems()
                    else ...[
                      for (final (index, item) in _items.indexed) ...[
                        KeyedSubtree(
                          key: ValueKey('scan-item-card-$index'),
                          child: _EditableItemCard(
                            item: item,
                            index: index,
                            onRemove: () =>
                                setState(() => _items.removeAt(index)),
                            onChanged: () => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _AddItemRow(
                      controller: _addController,
                      onAdd: (name) => setState(
                        () => _items.add(
                          _EditableItem(
                            name: name,
                            groups: <String>{},
                            confidence: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      header: true,
                      child: Text(
                        AppStrings.scanMealTypeLabel,
                        style: textTheme.labelLarge?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final mealType in const [
                          MealType.breakfast,
                          MealType.lunch,
                          MealType.snack,
                          MealType.dinner,
                        ])
                          ChoiceChip(
                            label: Text(_mealTypeLabel(mealType)),
                            selected: _mealType == mealType,
                            onSelected: (_) =>
                                setState(() => _mealType = mealType),
                          ),
                      ],
                    ),
                    if (_saveError != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _saveError!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.statusAlert,
                        ),
                      ),
                    ] else
                      const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _canSave ? _save : null,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: const Text(AppStrings.scanSave),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  static String _mealTypeLabel(MealType mealType) => switch (mealType) {
        MealType.breakfast => AppStrings.mealBreakfast,
        MealType.lunch => AppStrings.mealLunch,
        MealType.snack => AppStrings.mealSnack,
        MealType.dinner => AppStrings.mealDinner,
      };
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: colors.outline,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppSurfaces.sunken(context),
      child: Text(
        'Belum ada item. Foto ulang atau tambah item di bawah.',
        style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
      ),
    );
  }
}

class _EditableItemCard extends StatelessWidget {
  const _EditableItemCard({
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  final _EditableItem item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppSurfaces.sunken(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.name,
                  onChanged: (value) => item.name = value.trim(),
                  textInputAction: TextInputAction.next,
                  maxLength: 40,
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    border: InputBorder.none,
                    hintText: AppStrings.scanAddItemHint,
                  ),
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (item.confidence < 0.6)
                Semantics(
                  label: AppStrings.scanConfidenceLow,
                  child: Container(
                    margin: const EdgeInsets.only(right: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.statusWatch.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      AppStrings.scanConfidenceLow,
                      style: textTheme.labelMedium?.copyWith(
                        color: colors.statusWatchText,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              IconButton(
                tooltip: AppStrings.makanDeleteLog,
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final code in FoodGroup.allCodes)
                FilterChip(
                  label: Text(AppStrings.groupShortLabel(code)),
                  selected: item.groups.contains(code),
                  showCheckmark: false,
                  onSelected: (_) {
                    if (item.groups.contains(code)) {
                      item.groups = {...item.groups}..remove(code);
                    } else if (item.groups.length < 3) {
                      item.groups = {...item.groups, code};
                    }
                    onChanged();
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                AppStrings.portionLabel,
                style: textTheme.labelMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final portion in _EditableItem.portions)
                    ChoiceChip(
                      label: Text(_portionLabelOf(portion)),
                      selected: item.portion == portion,
                      onSelected: (_) {
                        item.portion =
                            item.portion == portion ? _ScanPortion.none : portion;
                        onChanged();
                      },
                    ),
                ],
              ),
            ],
          ),
          if (item.groups.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                AppStrings.scanItemEmptyGroups,
                style: textTheme.bodySmall?.copyWith(
                  color: colors.statusAlert,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _portionLabelOf(_ScanPortion portion) => switch (portion) {
        _ScanPortion.little => AppStrings.portionLittle,
        _ScanPortion.medium => AppStrings.portionMedium,
        _ScanPortion.finished => AppStrings.portionFinished,
        _ScanPortion.none => '',
      };
}

class _AddItemRow extends StatelessWidget {
  const _AddItemRow({required this.controller, required this.onAdd});

  final TextEditingController controller;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            maxLength: 40,
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              hintText: AppStrings.scanAddItemHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.control),
                borderSide: BorderSide(color: colors.outline),
              ),
            ),
            onSubmitted: (_) => _submit(),
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(AppStrings.scanAddItemButton),
        ),
      ],
    );
  }

  void _submit() {
    final name = controller.text.trim();
    if (name.isEmpty) return;
    onAdd(name);
    controller.clear();
  }
}
