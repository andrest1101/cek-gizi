import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/domain/entities/measure_mode.dart';
import 'package:cekgizi/features/growth/domain/repositories/growth_exceptions.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/shared/widgets/segment_control.dart';
import 'package:cekgizi/shared/widgets/z_score_table.dart';

/// Bottom sheet tambah/ubah ukuran (PRD §6.5): tanggal, berat, tinggi,
/// cara ukur, validasi ganda, lalu hasil z-score ditampilkan.
Future<void> showMeasurementSheet(
  BuildContext context, {
  GrowthMeasurement? existing,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _MeasurementSheet(existing: existing),
  );
}

class _MeasurementSheet extends ConsumerStatefulWidget {
  const _MeasurementSheet({this.existing});

  final GrowthMeasurement? existing;

  @override
  ConsumerState<_MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends ConsumerState<_MeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _measuredOn = DateTime.now();
  MeasureMode _mode = MeasureMode.lying;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _weightController.text = existing.weightKg.toStringAsFixed(1);
      _heightController.text = existing.lengthHeightCm.toStringAsFixed(1);
      _noteController.text = existing.note ?? '';
      _measuredOn = existing.measuredOn;
      _mode = existing.measureMode;
    } else {
      final child = ref.read(selectedChildProvider).value;
      final today = DateTime.now();
      if (child != null) {
        final age = child.ageInCompletedMonths(today);
        _mode = age < 24 ? MeasureMode.lying : MeasureMode.standing;
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double? _parse(String raw) => double.tryParse(raw.replaceAll(',', '.'));

  String? _validateWeight(String? value) {
    final parsed = value == null ? null : _parse(value);
    if (parsed == null) return AppStrings.validationRequired;
    if (parsed < 1 || parsed > 30) return AppStrings.validationWeightRange;
    return null;
  }

  String? _validateHeight(String? value) {
    final parsed = value == null ? null : _parse(value);
    if (parsed == null) return AppStrings.validationRequired;
    if (parsed < 35 || parsed > 130) return AppStrings.validationHeightRange;
    return null;
  }

  Future<void> _pickDate() async {
    final child = ref.read(selectedChildProvider).value;
    final first = child?.birthDate ?? DateTime(2000);
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _measuredOn.isBefore(first) ? first : _measuredOn,
      firstDate: first,
      lastDate: today,
      helpText: AppStrings.growthMeasureDate,
    );
    if (picked != null) {
      setState(() => _measuredOn = picked);
    }
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final child = ref.read(selectedChildProvider).value;
    if (child == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final weight = _parse(_weightController.text)!;
    final height = _parse(_heightController.text)!;
    final note = _noteController.text;
    final notifier = ref.read(measurementsProvider(child.id).notifier);

    try {
      final measurement = _isEdit
          ? await notifier.updateMeasurement(
              existing: widget.existing!,
              weightKg: weight,
              lengthHeightCm: height,
              mode: _mode,
              note: note,
            )
          : await notifier.addMeasurement(
              measuredOn: _measuredOn,
              weightKg: weight,
              lengthHeightCm: height,
              mode: _mode,
              note: note,
            );
      if (!mounted) return;
      Navigator.of(context).pop();
      await showDialog<void>(
        context: context,
        builder: (context) => _ResultDialog(
          childName: child.nickname,
          measurement: measurement,
        ),
      );
    } on DuplicateMeasurementException {
      setState(() => _error = AppStrings.validationDuplicateDate);
    } catch (error) {
      setState(
        () => _error =
            'Gagal menyimpan. Periksa koneksi internet kamu, lalu coba lagi.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.md,
          AppSpacing.screenPadding,
          AppSpacing.screenPadding + MediaQuery.paddingOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.outline,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(
                    _isEdit
                        ? AppStrings.growthEditTitle
                        : AppStrings.growthAddMeasurement,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _isEdit
                      ? AppStrings.growthDateLocked
                      : AppStrings.growthSheetHint,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                InkWell(
                  onTap: _busy || _isEdit ? null : _pickDate,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: AppStrings.growthMeasureDate,
                      prefixIcon: const Icon(Icons.calendar_month_rounded),
                      suffixIcon: _isEdit
                          ? Icon(
                              Icons.lock_outline_rounded,
                              color: colors.textSecondary,
                              size: 20,
                            )
                          : null,
                    ),
                    child: Text(
                      IdDateFormat.full(_measuredOn),
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _validateWeight,
                  decoration: const InputDecoration(
                    labelText: AppStrings.growthMeasureWeight,
                    suffixText: 'kg',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _validateHeight,
                  decoration: const InputDecoration(
                    labelText: AppStrings.growthMeasureHeightLength,
                    suffixText: 'cm',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.growthMeasureMode,
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentControl<MeasureMode>(
                  selected: _mode,
                  onChanged: (value) => setState(() => _mode = value),
                  options: const <SegmentOption<MeasureMode>>[
                    SegmentOption(
                      value: MeasureMode.lying,
                      label: AppStrings.growthMeasureModeLying,
                      semanticLabel:
                          AppStrings.growthMeasureModeLyingSemantics,
                    ),
                    SegmentOption(
                      value: MeasureMode.standing,
                      label: AppStrings.growthMeasureModeStanding,
                      semanticLabel:
                          AppStrings.growthMeasureModeStandingSemantics,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _noteController,
                  maxLength: AppStrings.growthNoteMaxLength,
                  maxLines: 2,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: AppStrings.growthMeasureNote,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.statusAlert.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: colors.statusAlert,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _error!,
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.statusAlert,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text(AppStrings.growthMeasureSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({required this.childName, required this.measurement});

  final String childName;
  final GrowthMeasurement measurement;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('${AppStrings.growthMeasureSaved}: $childName'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: AppSurfaces.sunken(context),
              child: ZScoreTable(measurement: measurement),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.statusDetailFootnote,
              style: textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.actionClose),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/growth');
          },
          child: const Text(AppStrings.growthViewChart),
        ),
      ],
    );
  }
}
