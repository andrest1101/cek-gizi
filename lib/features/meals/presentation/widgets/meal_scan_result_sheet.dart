import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/entities/meal_scan.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/domain/services/piring_day.dart';
import 'package:cekgizi/features/meals/presentation/meal_presentation.dart';
import 'package:cekgizi/features/meals/presentation/providers/meals_providers.dart';
import 'package:cekgizi/features/meals/presentation/widgets/scan_group_picker_sheet.dart';
import 'package:cekgizi/features/meals/presentation/widgets/scan_result_footer.dart';
import 'package:cekgizi/features/meals/presentation/widgets/scan_result_item_tile.dart';
import 'package:cekgizi/shared/widgets/segment_control.dart';
import 'package:cekgizi/shared/widgets/tonal_icon_circle.dart';

/// Sheet hasil scan makanan (PRD §6.4, human-in-the-loop).
///
/// Item terdeteksi tampil sebagai baris yang bisa diubah, dihapus, atau
/// ditambah manual. Porsi opsional; wajib pilih jenis makan dan minimal satu
/// kelompok per item. "Simpan ke catatan" membuat satu log `source=scan`.
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

class _MealScanResultSheetState extends ConsumerState<MealScanResultSheet> {
  late final List<ScanItemDraft> _items;
  final Set<Object> _removing = {};
  late MealType _mealType;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _items = [
      for (final item in widget.result.items)
        ScanItemDraft(
          name: item.name,
          groups: {...item.groups},
          confidence: item.confidence,
        ),
    ];
    _mealType = defaultMealTypeFor(ref.read(clockProvider)());
  }

  bool get _canSave =>
      !_saving &&
      _removing.isEmpty &&
      _items.isNotEmpty &&
      _items.every(
        (item) => item.name.trim().isNotEmpty && item.groups.isNotEmpty,
      );

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
            portion: item.portion == ScanPortion.none
                ? null
                : item.portion.storageValue,
          ),
      ];
      final log = await ref
          .read(foodLogsProvider(widget.childId).notifier)
          .addScanLog(items: logItems, mealType: _mealType);
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

  void _addItem(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _items.add(
        ScanItemDraft(name: trimmed, groups: <String>{}, confidence: 1),
      );
    });
  }

  void _removeItem(ScanItemDraft item) {
    if (_saving || _removing.contains(item.id)) return;
    final duration = AppMotion.of(context, AppMotion.normal);
    setState(() => _removing.add(item.id));
    Future.delayed(duration, () {
      if (!mounted) return;
      setState(() {
        _items.removeWhere((draft) => draft.id == item.id);
        _removing.remove(item.id);
      });
    });
  }

  Future<void> _openGroupPicker(ScanItemDraft item) async {
    final picked = await showScanGroupPicker(
      context,
      itemName: item.name.trim().isEmpty
          ? AppStrings.scanAddItemHint
          : item.name.trim(),
      selected: item.groups,
      maxGroups: 3,
    );
    if (picked == null || !mounted) return;
    setState(() => item.groups = {...picked});
  }

  /// Pratinjau target Piring Hari Ini setelah item ini disimpan.
  ///
  /// Dihitung dari aturan usia (`nutrition_rules.json`) + log hari ini,
  /// bukan dari jawaban model.
  String? _diversityPreview(PiringDay? piring) {
    final profile = piring?.profile;
    if (profile == null) return null;
    if (!_items.any((item) => item.groups.isNotEmpty)) return null;

    final union = <String>{
      for (final code in piring?.groups ?? const <String>{})
        if (FoodGroup.fromCode(code) != null) code,
      for (final item in _items)
        for (final code in item.groups)
          if (FoodGroup.fromCode(code) != null) code,
    };
    if (union.isEmpty) return null;

    final summary = DietaryDiversity.evaluate(
      groupCodes: union,
      profile: profile,
    );
    return AppStrings.scanDiversityPreview(summary.groupCount, summary.target);
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan provider anak & catatan makan ter-subscribe sejak awal.
    // `foodLogsProvider` autoDispose: tanpa listener, ref notifier mati
    // setelah build selesai dan `addScanLog` akan memakai ref yang disposed.
    ref.watch(selectedChildProvider);
    ref.watch(foodLogsProvider(widget.childId));
    final piring = ref.watch(piringTodayProvider(widget.childId)).value;
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);
    final available = media.size.height - media.viewInsets.bottom;
    final maxHeight = available > 0
        ? available * 0.92
        : media.size.height * 0.92;
    final keyboardOpen = media.viewInsets.bottom > 0;
    final duration = AppMotion.of(context, AppMotion.normal);
    final groupCount = _items.expand((item) => item.groups).toSet().length;

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
        child: Container(
          color: colors.surface,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetHeader(
                  itemCount: _items.length,
                  compact: keyboardOpen,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Divider(height: 1, color: colors.outline),
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    key: const Key('scan-result-scroll'),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_items.isEmpty)
                          const _EmptyItems()
                        else ...[
                          for (final (index, item) in _items.indexed) ...[
                            AnimatedSize(
                              duration: duration,
                              curve: AppMotion.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: _removing.contains(item.id)
                                  ? const SizedBox(width: double.infinity)
                                  : _ItemEntrance(
                                      child: KeyedSubtree(
                                        key: ValueKey('scan-item-card-$index'),
                                        child: ScanResultItemTile(
                                          key: ValueKey(item.id),
                                          item: item,
                                          index: index,
                                          onChanged: () => setState(() {}),
                                          onRemove: () => _removeItem(item),
                                          onEditGroups: () =>
                                              _openGroupPicker(item),
                                        ),
                                      ),
                                    ),
                            ),
                            if (index < _items.length - 1 &&
                                !_removing.contains(item.id))
                              Divider(
                                height: AppSpacing.xxxl,
                                color: colors.outline,
                              ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _AddItemTile(onAdd: _addItem),
                        const SizedBox(height: AppSpacing.xxl),
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
                        SegmentControl<MealType>(
                          options: [
                            for (final type in const [
                              MealType.breakfast,
                              MealType.lunch,
                              MealType.dinner,
                              MealType.snack,
                            ])
                              SegmentOption(
                                value: type,
                                label: mealTypeLabel(type),
                                semanticLabel:
                                    '${AppStrings.scanMealTypeLabel}: '
                                    '${mealTypeLabel(type)}',
                              ),
                          ],
                          selected: _mealType,
                          onChanged: (value) =>
                              setState(() => _mealType = value),
                        ),
                      ],
                    ),
                  ),
                ),
                ScanResultFooter(
                  itemCount: _items.length,
                  groupCount: groupCount,
                  canSave: _canSave,
                  saving: _saving,
                  onSave: _save,
                  diversityText: _diversityPreview(piring),
                  error: _saveError,
                  compact: keyboardOpen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.itemCount,
    required this.compact,
    required this.onClose,
  });

  final int itemCount;
  final bool compact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.md,
        compact ? AppSpacing.sm : AppSpacing.md,
      ),
      child: Column(
        children: [
          Center(child: _DragHandle()),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!compact) ...[
                      Text(
                        AppStrings.scanSheetEyebrow,
                        style: textTheme.labelMedium?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        AppStrings.scanSheetTitle,
                        style: textTheme.titleLarge?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppStrings.scanSheetSubtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      if (itemCount > 0) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _CountPill(count: itemCount),
                      ],
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: AppStrings.actionClose,
                onPressed: onClose,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_rounded, size: 14, color: colors.primary),
            const SizedBox(width: AppSpacing.xs + 2),
            AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.fast),
              child: Text(
                AppStrings.scanItemCount(count),
                key: ValueKey(count),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          const TonalIconCircle(
            icon: Icons.no_food_rounded,
            iconSemantics: AppStrings.scanEmptySemantics,
            size: 56,
            iconSize: 26,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppStrings.scanEmptyTitle,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.scanEmptyBody,
            textAlign: TextAlign.center,
            style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AddItemTile extends StatefulWidget {
  const _AddItemTile({required this.onAdd});

  final ValueChanged<String> onAdd;

  @override
  State<_AddItemTile> createState() => _AddItemTileState();
}

class _AddItemTileState extends State<_AddItemTile> {
  final _controller = TextEditingController();
  bool _open = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      _error = null;
    });
  }

  void _cancel() {
    FocusScope.of(context).unfocus();
    _controller.clear();
    setState(() {
      _open = false;
      _error = null;
    });
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = AppStrings.scanAddItemEmpty);
      return;
    }
    widget.onAdd(name);
    _controller.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _open = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final duration = AppMotion.of(context, AppMotion.normal);

    return AnimatedSize(
      duration: duration,
      curve: AppMotion.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _open
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('scan-add-item-field'),
                  controller: _controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  maxLength: 40,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) {
                    if (_error != null) {
                      setState(() => _error = null);
                    }
                  },
                  decoration: InputDecoration(
                    isDense: true,
                    counterText: '',
                    hintText: AppStrings.scanAddItemHint,
                    errorText: _error,
                  ),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _cancel,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text(AppStrings.actionCancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('scan-add-item-submit'),
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(AppStrings.scanAddItemButton),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Semantics(
              button: true,
              label: AppStrings.scanAddItemCta,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: InkWell(
                  key: const Key('scan-add-item-toggle'),
                  onTap: _toggle,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 56),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      border: Border.all(color: colors.outline),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_rounded,
                            size: 18,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            AppStrings.scanAddItemCta,
                            style: textTheme.labelLarge?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
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
}

class _ItemEntrance extends StatelessWidget {
  const _ItemEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.normal),
      curve: AppMotion.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: child,
        ),
      ),
      child: child,
    );
  }
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
