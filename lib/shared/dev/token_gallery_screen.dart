import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_colors.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/shared/widgets/empty_state.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/section_header.dart';

/// Layar UJI token untuk Batch 1 (PRD §10: "Layar uji menampilkan semua
/// token di kedua tema"). Ini alat developer, bukan alur pengguna; diganti
/// oleh Beranda asli di Batch 4.
///
/// Tidak memakai literal warna sama sekali - semua dari [AppColors] dan
/// `Theme.of(context)`.
class TokenGalleryScreen extends StatelessWidget {
  const TokenGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Token Galeri (Batch 1)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          const Text(
            'Semua token §7.2–7.4 ditampilkan di kedua tema. '
            'Angka memakai tabular figures; tidak ada gradien.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _ThemePreview(name: 'Light', theme: AppTheme.light()),
          const SizedBox(height: AppSpacing.xxl),
          _ThemePreview(name: 'Dark', theme: AppTheme.dark()),
          const SizedBox(height: AppSpacing.xxxl),
        ],
        ),
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({
    required this.name,
    required this.theme,
  });

  final String name;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final textTheme = Theme.of(context).textTheme;
          final colors = Theme.of(context).extension<AppColors>()!;
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: colors.outline, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tema $name',
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Divider(
                  height: AppSpacing.xxl,
                  color: colors.outline,
                  thickness: 1,
                ),
                const SectionHeader(title: 'Warna'),
                const SizedBox(height: AppSpacing.sm),
                _ColorSwatches(colors: colors),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(title: 'Tipografi'),
                const SizedBox(height: AppSpacing.sm),
                _TypographySamples(colors: colors),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(title: 'Spacing (4pt)'),
                const SizedBox(height: AppSpacing.sm),
                _SpacingScale(colors: colors),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(title: 'Radius'),
                const SizedBox(height: AppSpacing.sm),
                _RadiusSamples(colors: colors),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(title: 'Motion'),
                const SizedBox(height: AppSpacing.sm),
                _MotionTokens(colors: colors),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(title: 'Tombol'),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton(
                      onPressed: () => _toast(context, 'Aksi utama ditekan'),
                      child: const Text('Aksi utama'),
                    ),
                    OutlinedButton(
                      onPressed: () => _toast(context, 'Aksi sekunder ditekan'),
                      child: const Text('Sekunder'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(title: 'Komponen'),
                const SizedBox(height: AppSpacing.sm),
                EmptyState(
                  icon: Icons.flatware_rounded,
                  title: 'Belum ada catatan hari ini.',
                  body: 'Ketuk tombol di bawah untuk mulai mencatat.',
                  action: FilledButton(
                    onPressed: () => _toast(context, 'Foto makanan ditekan'),
                    child: const Text('Foto makanan'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ErrorCard(
                  message: 'Layanan sedang sibuk, coba lagi sebentar.',
                  onRetry: () => _toast(context, 'Coba lagi ditekan'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

String _hex(Color color) {
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class _ColorSwatches extends StatelessWidget {
  const _ColorSwatches({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, Color)>[
      ('background', colors.background),
      ('surface', colors.surface),
      ('surfaceVariant', colors.surfaceVariant),
      ('outline', colors.outline),
      ('textPrimary', colors.textPrimary),
      ('textSecondary', colors.textSecondary),
      ('primary', colors.primary),
      ('onPrimary', colors.onPrimary),
      ('primaryContainer', colors.primaryContainer),
      ('accent', colors.accent),
      ('statusGood', colors.statusGood),
      ('statusWatch', colors.statusWatch),
      ('statusWatchText', colors.statusWatchText),
      ('statusAlert', colors.statusAlert),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.md,
      children: [
        for (final (name, color) in entries)
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                    border: Border.all(color: colors.outline, width: 1),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  name,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  _hex(color),
                  style: AppTextStyles.label.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TypographySamples extends StatelessWidget {
  const _TypographySamples({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final samples = <(String, Widget)>[
      ('heroNumber 28/34', Text('4/8', style: textTheme.displaySmall)),
      ('titleLarge 22/28', Text('Tumbuh kembang', style: textTheme.titleLarge)),
      ('titleMedium 17/24',
          Text('Piring Hari Ini', style: textTheme.titleMedium)),
      ('body 16/24',
          Text('Hari ini kita cek dulu makanannya.', style: textTheme.bodyLarge)),
      ('bodySmall 14/20',
          Text('Angka mengikuti tabel standar.', style: textTheme.bodySmall)),
      ('label 13/16',
          Text('LABEL / KAPTION', style: textTheme.labelLarge)),
      ('bodyTabular 16/24',
          Text('7,4 kg · 76,0 cm · z = −0,61',
              style: AppTextStyles.bodyTabular.copyWith(
                color: colors.textPrimary,
              ))),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (spec, sample) in samples) ...[
          Text(
            spec,
            style: AppTextStyles.label.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          DefaultTextStyle.merge(
            style: TextStyle(color: colors.textPrimary),
            child: sample,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _SpacingScale extends StatelessWidget {
  const _SpacingScale({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    const entries = <(String, double)>[
      ('xs - 4', AppSpacing.xs),
      ('sm - 8', AppSpacing.sm),
      ('md - 12', AppSpacing.md),
      ('lg - 16', AppSpacing.lg),
      ('xl - 20 (padding layar)', AppSpacing.xl),
      ('xxl - 24', AppSpacing.xxl),
      ('xxxl - 32', AppSpacing.xxxl),
      ('sectionGap - 28', AppSpacing.sectionGap),
    ];
    return Column(
      children: [
        for (final (name, value) in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 132,
                  child: Text(
                    name,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Container(
                  height: 14,
                  width: value * 7,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RadiusSamples extends StatelessWidget {
  const _RadiusSamples({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final entries = <(String, double)>[
      ('control - 12', AppRadius.control),
      ('card - 20', AppRadius.card),
      ('pill - 999', AppRadius.pill),
    ];
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        for (final (name, radius) in entries)
          Container(
            width: 110,
            height: 56,
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: colors.outline, width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              name,
              style: AppTextStyles.label.copyWith(color: colors.textPrimary),
            ),
          ),
      ],
    );
  }
}

class _MotionTokens extends StatelessWidget {
  const _MotionTokens({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final tokens = <String>[
      'fast - ${AppMotion.fast.inMilliseconds}ms · easeOutCubic',
      'normal - ${AppMotion.normal.inMilliseconds}ms · easeOutCubic',
      'ring - ${AppMotion.ring.inMilliseconds}ms · easeOutCubic',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final token in tokens)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text(
              token,
              style: AppTextStyles.bodySmall.copyWith(color: colors.textPrimary),
            ),
          ),
      ],
    );
  }
}
