import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/theme/theme_providers.dart';
import 'package:cekgizi/shared/widgets/section_heading.dart';
import 'package:cekgizi/shared/widgets/tonal_icon_circle.dart';

/// Bagian Tampilan di Akun: pilih Terang / Gelap / mengikuti Sistem.
///
/// Murni lokal (tersimpan di `LocalPrefs`), tidak bergantung pada Supabase
/// maupun pengaturan tema perangkat. Default aplikasi = terang.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final mode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeading(title: AppStrings.accountAppearanceTitle),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: AppSurfaces.card(context),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TonalIconCircle(
                    icon: Icons.palette_rounded,
                    iconSemantics: AppStrings.accountAppearanceSemantics,
                    size: 40,
                    iconSize: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.accountAppearanceTitle,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.accountAppearanceBody,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                label: AppStrings.accountAppearanceSemantics,
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(AppStrings.accountThemeLight),
                      icon: Icon(Icons.light_mode_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(AppStrings.accountThemeDark),
                      icon: Icon(Icons.dark_mode_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(AppStrings.accountThemeSystem),
                      icon: Icon(Icons.smartphone_rounded, size: 18),
                    ),
                  ],
                  selected: {mode},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) return;
                    ref.read(themeModeProvider.notifier).set(selection.first);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
