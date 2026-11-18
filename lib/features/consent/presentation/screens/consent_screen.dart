import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/core/supabase/supabase_client_provider.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/consent/data/repositories/consent_repository_impl.dart';
import 'package:cekgizi/features/consent/domain/use_cases/accept_consent.dart';
import 'package:cekgizi/shared/widgets/tonal_icon_circle.dart';

/// Layar consent WAJIB (PRD §6.1, §8.3): tanpa setuju, app tidak bisa
/// dipakai. Simpan ke Supabase (`user_consents`) lalu tandai flag lokal.
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

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppConfig.appName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.sm,
            AppSpacing.screenPadding,
            AppSpacing.xxxl,
          ),
          children: [
            Row(
              children: [
                const TonalIconCircle(
                  icon: Icons.privacy_tip_rounded,
                  iconSemantics: AppStrings.consentPrivacySemantics,
                  size: 56,
                  iconSize: 27,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    AppStrings.consentDataTitle,
                    style: AppTextStyles.label.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Semantics(
              header: true,
              child: Text(
                AppStrings.consentTitle,
                style: AppTextStyles.titleLarge.copyWith(
                  fontSize: 26,
                  height: 1.25,
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.consentIntro,
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              AppStrings.consentDataTitle,
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final bullet in AppStrings.consentBullets)
              _Bullet(text: bullet),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: AppSurfaces.sunken(context, radius: AppRadius.card),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          AppStrings.consentDisclaimerTitle,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontSize: 15,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.disclaimer,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_error != null) ...[
              Row(
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
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.statusAlert,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AnimatedContainer(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: _agreed
                    ? colors.primaryContainer
                    : AppSurfaces.cardColor(context),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: _agreed ? colors.primary : colors.outline,
                  width: _agreed ? 1.5 : 1,
                ),
              ),
              child: CheckboxListTile(
                value: _agreed,
                onChanged: (value) => setState(() => _agreed = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                title: Text(
                  AppStrings.consentAgreeLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _agreed && !_busy ? _submit : null,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppStrings.consentSubmit),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.consentDeclineHint,
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 17, color: colors.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textPrimary,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}
