import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/time/clock.dart';
import 'package:cekgizi/features/account/presentation/providers/account_providers.dart';
import 'package:cekgizi/features/account/presentation/widgets/account_about_section.dart';
import 'package:cekgizi/features/account/presentation/widgets/account_child_strip.dart';
import 'package:cekgizi/features/account/presentation/widgets/account_delete_dialog.dart';
import 'package:cekgizi/features/account/presentation/widgets/account_identity_card.dart';
import 'package:cekgizi/features/account/presentation/widgets/account_privacy_card.dart';
import 'package:cekgizi/features/account/presentation/widgets/appearance_section.dart';
import 'package:cekgizi/features/account/presentation/widgets/reminder_settings_section.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/chat/presentation/widgets/tanya_bubble.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
import 'package:cekgizi/shared/widgets/screen_header.dart';
import 'package:cekgizi/shared/widgets/section_heading.dart';
import 'package:cekgizi/shared/widgets/skeleton.dart';

/// Tab Akun (PRD §6.8): identitas anak terpilih, foto profil lokal, daftar
/// anak, pengingat, ringkasan privasi, dan sumber rujukan.
///
/// Bagian yang butuh backend tambahan (kunci akun, ekspor, hapus akun)
/// menyusul di batch Privasi & Akun. Tidak ada baris menu kosong.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenListProvider);
    final now = ref.watch(clockProvider)();

    // Hapus Akun (UX-5): snackbar + pindah ke /opening setelah sukses atau
    // sana snackbar error di riwayat notifikasi.
    ref.listen(deleteAccountProvider, (_, next) {
      if (!context.mounted) return;
      if (next.isDone) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.accountDeleteDone)));
        context.go('/opening');
      } else if (next.error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppStrings.accountDeleteError)));
      }
    });

    return Scaffold(
      floatingActionButton: const TanyaBubble(),
      body: SafeArea(
        child: ListView(
          key: const Key('account-list'),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xxxl * 3,
          ),
          children: [
            const ScreenHeader(
              eyebrow: AppStrings.accountEyebrow,
              title: AppStrings.accountTitle,
              subtitle: AppStrings.accountSubtitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionHeading(
              title: AppStrings.accountChildSection,
              action: TextButton(
                onPressed: () => context.push('/children'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                ),
                child: const Text(AppStrings.accountChildManage),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Bedakan memuat / gagal / benar-benar kosong. Sebelumnya
            // `.value` membuat keadaan memuat & galat tampil seolah
            // "belum ada anak".
            childrenAsync.when(
              loading: () => const _AccountChildSkeleton(),
              error: (error, stackTrace) => ErrorCard(
                message: AppStrings.childListLoadError,
                onRetry: () => ref.invalidate(childrenListProvider),
              ),
              data: (children) {
                final child = ref.watch(selectedChildProvider).value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (child == null)
                      const _NoChildCard()
                    else
                      AccountIdentityCard(child: child, now: now),
                    if (children.length > 1) ...[
                      const SizedBox(height: AppSpacing.md),
                      AccountChildStrip(children: children, now: now),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            const AppearanceSection(),
            const SizedBox(height: AppSpacing.xxl),
            const ReminderSettingsSection(),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeading(title: AppStrings.accountPrivacyTitle),
            const SizedBox(height: AppSpacing.md),
            AccountPrivacyCard(
              onDelete: () => confirmAccountDelete(context, ref),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const AccountAboutSection(),
          ],
        ),
      ),
    );
  }
}

/// Kerangka kartu identitas selama daftar anak masih dimuat.
class _AccountChildSkeleton extends StatelessWidget {
  const _AccountChildSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('account-child-loading'),
      decoration: AppSurfaces.card(context),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Skeleton(width: 64, height: 64, radius: AppRadius.pill),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 140, height: 18),
                    SizedBox(height: AppSpacing.xs),
                    Skeleton(width: 96, height: 14),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          Skeleton(height: 14),
          SizedBox(height: AppSpacing.sm),
          Skeleton(width: 180, height: 14),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(Icons.child_care_rounded, color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
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
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => context.push('/children/add'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text(AppStrings.accountChildEmptyCta),
            ),
          ),
        ],
      ),
    );
  }
}
