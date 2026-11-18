import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/features/account/presentation/widgets/reminder_settings_section.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/shared/widgets/child_avatar.dart';
import 'package:cekgizi/shared/widgets/screen_header.dart';

/// Tab Akun (PRD §6.8): profil anak di perangkat ini + pengingat lokal.
///
/// Bagian yang butuh backend (kunci akun, ekspor, hapus akun) menyusul di
/// batch Privasi & Akun. Layar ini hanya menampilkan yang benar-benar sudah
/// berfungsi - tidak ada baris menu kosong.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final child = ref.watch(selectedChildProvider).value;
    final now = ref.watch(clockProvider)();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          key: const Key('account-list'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xxxl + AppSpacing.lg,
          ),
          children: [
            const ScreenHeader(
              eyebrow: AppStrings.accountEyebrow,
              title: AppStrings.accountTitle,
              subtitle: AppStrings.accountSubtitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.accountChildSection,
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (child == null)
              const _NoChildCard()
            else
              _ChildCard(
                nickname: child.nickname,
                avatarKey: child.avatarKey,
                age: child.ageLabel(now),
              ),
            const SizedBox(height: AppSpacing.xxl),
            const ReminderSettingsSection(),
            const SizedBox(height: AppSpacing.xxl),
            Divider(color: colors.outline),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.accountDisclaimerTitle,
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.accountDisclaimerBody,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.accountLocalNote,
              style: AppTextStyles.label.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppConfig.appName,
              style: AppTextStyles.label.copyWith(
                color: colors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.nickname,
    required this.avatarKey,
    required this.age,
  });

  final String nickname;
  final String avatarKey;
  final String age;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      decoration: AppSurfaces.card(context),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              ChildAvatar(
                avatarKey: avatarKey,
                size: 52,
                semanticLabel: nickname,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      age,
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
          OutlinedButton.icon(
            onPressed: () => context.push('/children'),
            icon: const Icon(Icons.manage_accounts_rounded, size: 18),
            label: const Text(AppStrings.accountChildManage),
          ),
        ],
      ),
    );
  }
}

class _NoChildCard extends StatelessWidget {
  const _NoChildCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      decoration: AppSurfaces.card(context),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.accountChildEmptyTitle,
            style: AppTextStyles.titleMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppStrings.accountChildEmptyBody,
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => context.push('/children/add'),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text(AppStrings.accountChildEmptyCta),
            ),
          ),
        ],
      ),
    );
  }
}
