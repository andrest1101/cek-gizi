import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/presentation/providers/growth_providers.dart';
import 'package:cekgizi/features/growth/presentation/widgets/add_measurement_sheet.dart';
import 'package:cekgizi/features/growth/presentation/widgets/growth_chart.dart';
import 'package:cekgizi/features/growth/presentation/widgets/growth_status_card.dart';
import 'package:cekgizi/features/growth/presentation/widgets/status_copy.dart';
import 'package:cekgizi/shared/widgets/child_avatar.dart';
import 'package:cekgizi/shared/widgets/section_header.dart';
import 'package:cekgizi/shared/widgets/status_pill.dart';

/// Layar Tumbuh (PRD §6.5): status terbaru, 3 tab grafik pita SD, riwayat.
class GrowthScreen extends ConsumerStatefulWidget {
  const GrowthScreen({super.key});

  @override
  ConsumerState<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends ConsumerState<GrowthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final childAsync = ref.watch(selectedChildProvider);
    final child = childAsync.value;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (child != null)
              ChildAvatar(avatarKey: child.avatarKey, size: 36),
            const SizedBox(width: AppSpacing.sm),
            Text(child?.nickname ?? AppStrings.growthTitle),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showMeasurementSheet(context),
        icon: const Icon(Icons.straighten_rounded),
        label: const Text(AppStrings.growthAddMeasurement),
      ),
      body: SafeArea(
        child: child == null
            ? Center(
                child: Text(
                  'Tambah anak dulu di Beranda.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              )
            : _Body(
                childId: child.id,
                tabController: _tabController,
              ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.childId,
    required this.tabController,
  });

  final String childId;
  final TabController tabController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final measurementsAsync = ref.watch(measurementsProvider(childId));

    return measurementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Text('Gagal memuat pengukuran. Periksa koneksi kamu.'),
        ),
      ),
      data: (measurements) {
        final sorted = [...measurements]
          ..sort((a, b) => a.measuredOn.compareTo(b.measuredOn));

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.xxxl + AppSpacing.xl,
          ),
          children: [
            const GrowthStatusCard(),
            const SizedBox(height: AppSpacing.lg),
            TabBar(
              controller: tabController,
              labelStyle: Theme.of(context).textTheme.labelLarge,
              unselectedLabelStyle: Theme.of(context).textTheme.labelLarge,
              labelColor: colors.primary,
              unselectedLabelColor: colors.textSecondary,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(color: colors.primary, width: 2.5),
                insets: const EdgeInsets.symmetric(horizontal: 8),
              ),
              tabs: const [
                Tab(text: AppStrings.growthTabLengthHeight),
                Tab(text: AppStrings.growthTabWeight),
                Tab(text: AppStrings.growthTabWeightHeight),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 320,
              child: _ChartArea(
                tabController: tabController,
                measurements: sorted,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Garis hijau = rentang wajar; kuning = perlu perhatian. '
              'Tabel: Permenkes 2/2020.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            const SectionHeader(title: AppStrings.growthHistoryTitle),
            const SizedBox(height: AppSpacing.sm),
            for (final measurement in sorted.reversed)
              _MeasurementTile(measurement: measurement),
          ],
        );
      },
    );
  }
}

class _ChartArea extends ConsumerWidget {
  const _ChartArea({
    required this.tabController,
    required this.measurements,
  });

  final TabController tabController;
  final List<GrowthMeasurement> measurements;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(selectedChildProvider);
    final child = childAsync.value;
    if (child == null) return const SizedBox.shrink();

    if (measurements.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Text(
            AppStrings.growthNoMeasurementsBody,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return TabBarView(
      controller: tabController,
      children: [
        for (final index in const [
          AnthropometryIndex.haz,
          AnthropometryIndex.waz,
          AnthropometryIndex.whz,
        ])
          GrowthChart(
            child: child,
            measurements: measurements,
            index: index,
            semanticsLabel: _semantics(measurements.last, index),
          ),
      ],
    );
  }

  static String _semantics(GrowthMeasurement latest, AnthropometryIndex index) {
    final value = switch (index) {
      AnthropometryIndex.haz =>
        'Tinggi ${GrowthStatusCopy.formatKgCm(latest.lengthHeightCm)} cm',
      AnthropometryIndex.waz =>
        'Berat ${GrowthStatusCopy.formatKgCm(latest.weightKg)} kg',
      AnthropometryIndex.whz =>
        'Berat ${GrowthStatusCopy.formatKgCm(latest.weightKg)} kg menurut panjang/tinggi',
    };
    return 'Grafik pertumbuhan. Pengukuran terakhir $value, '
        'usia ${latest.ageMonths} bulan.';
  }
}

class _MeasurementTile extends ConsumerWidget {
  const _MeasurementTile({required this.measurement});

  final GrowthMeasurement measurement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final statusHaz = measurement.statusHaz;
    final tone = statusHaz == null
        ? StatusTone.watch
        : GrowthStatusCopy.forIndex(
            AnthropometryIndex.haz,
            statusHaz,
          ).tone;
    final category = statusHaz == null
        ? AppStrings.statusOutOfRangeShort
        : AppStrings.officialCategoryHaz[statusHaz] ?? statusHaz;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: colors.outline, width: 1),
        ),
        child: ListTile(
          minVerticalPadding: AppSpacing.md,
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.straighten_rounded),
          ),
          title: Text(
            '${GrowthStatusCopy.formatKgCm(measurement.weightKg)} kg · '
            '${GrowthStatusCopy.formatKgCm(measurement.lengthHeightCm)} cm',
            style: textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  IdDateFormat.full(measurement.measuredOn),
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                StatusPill(label: category, tone: tone),
              ],
            ),
          ),
          trailing: PopupMenuButton<String>(
            tooltip: 'Opsi pengukuran',
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  await showMeasurementSheet(
                    context,
                    existing: measurement,
                  );
                case 'delete':
                  await _confirmDelete(context, ref);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Ubah')),
              PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus pengukuran?'),
        content: const Text(
          'Pengukuran ini akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final childId = ref.read(selectedChildProvider).value?.id;
      if (childId == null) return;
      await ref.read(measurementsProvider(childId).notifier).deleteMeasurement(
            measurement.id,
          );
    }
  }
}
