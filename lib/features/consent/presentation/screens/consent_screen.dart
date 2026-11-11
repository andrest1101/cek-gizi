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
    final textTheme = Theme.of(context).textTheme;

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
            const Align(
              alignment: Alignment.centerLeft,
              child: TonalIconCircle(
                icon: Icons.privacy_tip_rounded,
                iconSemantics: AppStrings.consentPrivacySemantics,
                size: 64,
                iconSize: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                AppStrings.consentTitle,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.consentIntro,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              AppStrings.consentDataTitle,
              style: textTheme.titleMedium?.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final bullet in AppStrings.consentBullets)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: _Bullet(text: bullet),
              ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: AppSurfaces.sunken(
                context,
                radius: AppRadius.card,
              ),
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
                          style: textTheme.labelLarge?.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.disclaimer,
                    style: textTheme.bodySmall?.copyWith(
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
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.statusAlert,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Container(
              decoration: BoxDecoration(
                color: AppSurfaces.cardColor(context),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: _agreed ? colors.primary : colors.outline,
                  width: _agreed ? 1.5 : 1,
                ),
              ),
              child: CheckboxListTile(
                value: _agreed,
                onChanged: (value) =>
                    setState(() => _agreed = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                title: Text(
                  AppStrings.consentAgreeLabel,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
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
              style: textTheme.labelMedium?.copyWith(
                color: colors.textSecondary,
              ),
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
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, size: 16, color: colors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.textPrimary,
                ),
          ),
        ),
      ],
    );
  }
}
