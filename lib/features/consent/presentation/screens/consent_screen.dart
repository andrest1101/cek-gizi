import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/core/supabase/supabase_client_provider.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/consent/data/repositories/consent_repository_impl.dart';
import 'package:cekgizi/features/consent/domain/use_cases/accept_consent.dart';
import 'package:cekgizi/shared/widgets/app_logo_mark.dart';
import 'package:cekgizi/shared/widgets/section_reveal.dart';
import 'package:cekgizi/shared/widgets/tonal_icon_circle.dart';

/// Layar consent WAJIB (PRD §6.1, §8.3): tanpa setuju, app tidak bisa
/// dipakai. Simpan ke Supabase (`user_consents`) lalu tandai flag lokal.
///
/// Susunan: top bar merek → hero persetujuan → rincian data yang disimpan →
/// disclaimer → footer tetap berisi checkbox dan aksi utama. Checkbox dan
/// tombol selalu terlihat tanpa perlu menggulir ke ujung halaman.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key, required this.prefs});

  final LocalPrefs prefs;

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _agreed = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    if (!_agreed || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ConsentRepositoryImpl(ref.read(supabaseClientProvider));
      await AcceptConsent(repo)(version: LocalPrefs.consentVersion);
      await widget.prefs.setConsentAccepted();
      if (!mounted) return;
      context.go('/');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = AppStrings.consentError);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _setAgreed(bool? value) {
    if (_busy) return;
    setState(() => _agreed = value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              const SafeArea(
                bottom: false,
                child: _ConsentTopBar(),
              ),
              Expanded(
                child: ListView(
                  key: const Key('consent-list'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.xs,
                    AppSpacing.screenPadding,
                    AppSpacing.xxl,
                  ),
                  children: const [
                    SectionReveal(child: _ConsentHero()),
                    SizedBox(height: AppSpacing.xxl),
                    _ConsentDataSection(),
                    SizedBox(height: AppSpacing.xl),
                    _ConsentDisclaimerCard(),
                  ],
                ),
              ),
              _ConsentFooter(
                agreed: _agreed,
                busy: _busy,
                error: _error,
                onChanged: _setAgreed,
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentTopBar extends StatelessWidget {
  const _ConsentTopBar();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const AppLogoMark(size: 40),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppConfig.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 1,
            ),
            decoration: BoxDecoration(
              color: colors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              AppStrings.consentStepLabel,
              style: AppTextStyles.label.copyWith(
                color: colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentHero extends StatelessWidget {
  const _ConsentHero();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      key: const Key('consent-hero'),
      clipBehavior: Clip.hardEdge,
      decoration: AppSurfaces.hero(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -48,
            top: -48,
            child: _HeroRing(
              size: 160,
              color: colors.onHeroSurface.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            right: 8,
            bottom: -40,
            child: _HeroRing(
              size: 100,
              color: colors.onHeroSurface.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    TonalIconCircle(
                      icon: Icons.shield_rounded,
                      iconSemantics: AppStrings.consentPrivacySemantics,
                      size: 44,
                      iconSize: 22,
                      backgroundColor: colors.onHeroSurface.withValues(
                        alpha: 0.14,
                      ),
                      iconColor: colors.onHeroSurface,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        AppStrings.consentEyebrow,
                        style: AppTextStyles.label.copyWith(
                          color: colors.onHeroSurfaceMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  header: true,
                  child: Text(
                    AppStrings.consentTitle,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontSize: 24,
                      height: 1.25,
                      color: colors.onHeroSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppStrings.consentIntro,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 13.5,
                    height: 1.5,
                    color: colors.onHeroSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroRing extends StatelessWidget {
  const _HeroRing({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
    );
  }
}

class _ConsentDataSection extends StatelessWidget {
  const _ConsentDataSection();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.consentDataTitle,
          style: AppTextStyles.titleMedium.copyWith(color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          key: const Key('consent-data-card'),
          decoration: AppSurfaces.card(context),
          child: Column(
            children: [
              for (
                var index = 0;
                index < AppStrings.consentDataItems.length;
                index++
              ) ...[
                _ConsentDataRow(
                  item: AppStrings.consentDataItems[index],
                  icon: _consentDataIcons[index],
                ),
                if (index != AppStrings.consentDataItems.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 68),
                    child: Divider(height: 1, color: colors.outline),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

const _consentDataIcons = <IconData>[
  Icons.child_care_rounded,
  Icons.face_retouching_natural_rounded,
  Icons.photo_camera_rounded,
  Icons.lock_rounded,
  Icons.tune_rounded,
];

class _ConsentDataRow extends StatelessWidget {
  const _ConsentDataRow({required this.item, required this.icon});

  final ({String title, String body}) item;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(icon, size: 20, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.body,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentDisclaimerCard extends StatelessWidget {
  const _ConsentDisclaimerCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      key: const Key('consent-disclaimer'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.accentContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: colors.onAccentContainer,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.consentDisclaimerTitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.onAccentContainer,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppStrings.disclaimer,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.onAccentContainer,
                    fontSize: 12.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentFooter extends StatelessWidget {
  const _ConsentFooter({
    required this.agreed,
    required this.busy,
    required this.error,
    required this.onChanged,
    required this.onSubmit,
  });

  final bool agreed;
  final bool busy;
  final String? error;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Container(
      key: const Key('consent-footer'),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null) ...[
                _ConsentError(message: error!),
                const SizedBox(height: AppSpacing.md),
              ],
              AnimatedContainer(
                duration: reduceMotion ? Duration.zero : AppMotion.fast,
                curve: AppMotion.easeOutCubic,
                decoration: BoxDecoration(
                  color: agreed
                      ? colors.primaryContainer
                      : colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  border: Border.all(
                    color: agreed ? colors.primary : colors.outline,
                    width: agreed ? 1.5 : 1,
                  ),
                ),
                child: CheckboxListTile(
                  key: const Key('consent-agree'),
                  value: agreed,
                  onChanged: busy ? null : onChanged,
                  controlAffinity: ListTileControlAffinity.leading,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    AppStrings.consentAgreeLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('consent-submit'),
                  onPressed: agreed && !busy ? onSubmit : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: busy
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              AppStrings.consentSubmit,
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          AppStrings.consentSubmit,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.consentDeclineHint,
                textAlign: TextAlign.center,
                style: AppTextStyles.label.copyWith(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConsentError extends StatelessWidget {
  const _ConsentError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: colors.statusAlert.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: colors.statusAlert,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.statusAlert,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
