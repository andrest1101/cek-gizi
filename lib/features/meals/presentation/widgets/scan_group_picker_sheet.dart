import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';
import 'package:cekgizi/features/meals/presentation/widgets/food_group_logo.dart';

/// Buka pemilih kelompok pangan untuk satu item hasil scan.
///
/// Mengembalikan `null` bila ditutup tanpa menyimpan, atau himpunan kode
/// kelompok final saat tombol Selesai ditekan.
Future<Set<String>?> showScanGroupPicker(
  BuildContext context, {
  required String itemName,
  required Set<String> selected,
  int maxGroups = 3,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ScanGroupPickerSheet(
      itemName: itemName,
      selected: selected,
      maxGroups: maxGroups,
    ),
  );
}

/// Grid dua kolom berisi 8 kelompok pangan dengan logo, label, dan status
/// terpilih. Maksimal [maxGroups] kelompok per item agar tetap fokus.
class ScanGroupPickerSheet extends StatefulWidget {
  const ScanGroupPickerSheet({
    super.key,
    required this.itemName,
    required this.selected,
    this.maxGroups = 3,
  });

  final String itemName;
  final Set<String> selected;
  final int maxGroups;

  @override
  State<ScanGroupPickerSheet> createState() => _ScanGroupPickerSheetState();
}

class _ScanGroupPickerSheetState extends State<ScanGroupPickerSheet> {
  late final Set<String> _selected;
  bool _limitHit = false;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.selected};
  }

  void _toggle(String code) {
    if (_selected.contains(code)) {
      setState(() {
        _selected.remove(code);
        _limitHit = false;
      });
      return;
    }
    if (_selected.length >= widget.maxGroups) {
      setState(() => _limitHit = true);
      return;
    }
    setState(() {
      _selected.add(code);
      _limitHit = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);
    final available = media.size.height - media.viewInsets.bottom;
    final maxHeight = available > 0
        ? available * 0.85
        : media.size.height * 0.85;
    final duration = AppMotion.of(context, AppMotion.normal);

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xs,
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
                                Semantics(
                                  header: true,
                                  child: Text(
                                    AppStrings.scanGroupPickerTitle,
                                    style: textTheme.titleMedium?.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  AppStrings.scanGroupPickerSubtitle,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  AppStrings.scanGroupPickerFor(
                                    widget.itemName,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: AppStrings.actionClose,
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.outline),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xs,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.scanGroupPickerCount(
                          _selected.length,
                          widget.maxGroups,
                        ),
                        style: textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      AnimatedSize(
                        duration: duration,
                        curve: AppMotion.easeOutCubic,
                        alignment: Alignment.topLeft,
                        child: _limitHit
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xs,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 16,
                                      color: colors.statusWatchText,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        AppStrings.scanGroupPickerFull,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colors.statusWatchText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.sm,
                      AppSpacing.xl,
                      AppSpacing.lg,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final tileWidth =
                            (constraints.maxWidth - AppSpacing.sm) / 2;
                        return Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            for (final code in FoodGroup.allCodes)
                              SizedBox(
                                width: tileWidth,
                                child: _GroupTile(
                                  code: code,
                                  selected: _selected.contains(code),
                                  onTap: () => _toggle(code),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(top: BorderSide(color: colors.outline)),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.sm,
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const Key('scan-group-done'),
                        onPressed: () =>
                            Navigator.of(context).pop({..._selected}),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 52),
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: const Text(AppStrings.scanGroupPickerDone),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.code,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: AppStrings.groupLabel(code),
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: InkWell(
            key: ValueKey('scan-group-tile-$code'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.fast),
              curve: AppMotion.easeOutCubic,
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? colors.primaryContainer
                    : colors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.control),
                border: Border.all(
                  color: selected ? colors.primary : colors.outline,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  FoodGroupLogo(code: code, size: 32),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppStrings.groupShortLabel(code),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? colors.primary : Colors.transparent,
                      border: selected
                          ? null
                          : Border.all(color: colors.outline),
                    ),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: colors.onPrimary,
                          )
                        : null,
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
