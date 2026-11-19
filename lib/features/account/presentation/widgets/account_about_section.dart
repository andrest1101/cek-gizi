import 'package:flutter/material.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/shared/widgets/section_heading.dart';
import 'package:cekgizi/shared/widgets/settings_tile.dart';

/// Seksi "Tentang aplikasi": sumber rujukan yang bisa dibuka, versi, dan
/// disclaimer tetap. Tidak ada tautan yang dikarang - rujukan ditulis apa
/// adanya dan bisa diperiksa sendiri oleh orang tua.
class AccountAboutSection extends StatelessWidget {
  const AccountAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeading(title: AppStrings.accountDisclaimerTitle),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: AppSurfaces.card(context),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsTile(
                icon: Icons.menu_book_rounded,
                title: AppStrings.accountReferenceTitle,
                subtitle: AppStrings.accountReferenceSubtitle,
                onTap: () => _showReferences(context),
              ),
              Divider(height: 1, indent: 68, color: colors.outline),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppConfig.appName} · '
                      '${AppStrings.accountVersionLabel} '
                      '${AppConfig.appVersion}',
                      style: AppTextStyles.label.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppStrings.accountDisclaimerBody,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showReferences(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ReferencesSheet(),
    );
  }
}

class _ReferencesSheet extends StatelessWidget {
  const _ReferencesSheet();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        AppSpacing.screenPadding,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                AppStrings.accountReferenceSheetTitle,
                style: AppTextStyles.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const _ReferenceRow(
              icon: Icons.gavel_rounded,
              text: AppStrings.accountReferencePermenkes,
            ),
            const SizedBox(height: AppSpacing.md),
            const _ReferenceRow(
              icon: Icons.public_rounded,
              text: AppStrings.accountReferenceWho,
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: AppSurfaces.sunken(context),
              child: Text(
                AppStrings.accountReferenceNote,
                style: AppTextStyles.label.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text(AppStrings.accountReferenceClose),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          child: Icon(icon, size: 18, color: colors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textPrimary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}
