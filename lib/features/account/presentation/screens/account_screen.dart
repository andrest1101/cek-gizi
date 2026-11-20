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
import 'package:cekgizi/features/account/presentation/widgets/reminder_settings_section.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/chat/presentation/widgets/tanya_bubble.dart';
import 'package:cekgizi/shared/widgets/screen_header.dart';
import 'package:cekgizi/shared/widgets/section_heading.dart';

/// Tab Akun (PRD §6.8): identitas anak terpilih, foto profil lokal, daftar
/// anak, pengingat, ringkasan privasi, dan sumber rujukan.
///
/// Bagian yang butuh backend tambahan (kunci akun, ekspor, hapus akun)
/// menyusul di batch Privasi & Akun. Tidak ada baris menu kosong.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider).value;
    final children = ref.watch(childrenListProvider).value ?? const [];
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
            if (child == null)
              const _NoChildCard()
            else
              AccountIdentityCard(child: child, now: now),
            if (children.length > 1) ...[
              const SizedBox(height: AppSpacing.md),
              AccountChildStrip(children: children, now: now),
            ],
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
