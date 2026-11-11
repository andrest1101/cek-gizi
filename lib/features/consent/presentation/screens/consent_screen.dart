import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/consent/data/repositories/consent_repository_impl.dart';
import 'package:cekgizi/features/consent/domain/use_cases/accept_consent.dart';
import 'package:cekgizi/core/supabase/supabase_client_provider.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';
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
      setState(() {
        _error =
            'Persetujuan belum tersimpan. Periksa koneksi internet kamu, lalu coba lagi.';
      });
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
      appBar: AppBar(title: const Text(AppStrings.consentTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const TonalIconCircle(
              icon: Icons.privacy_tip_rounded,
              iconSemantics: 'Privasi data anak',
              size: 72,
              iconSize: 36,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppStrings.consentIntro,
              style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final bullet in AppStrings.consentBullets)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        bullet,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Text(
                AppStrings.disclaimer,
                style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (_error != null)
              ErrorCard(message: _error!, onRetry: _submit, title: AppStrings.errorTitle),
            if (_error != null) const SizedBox(height: AppSpacing.md),
            Semantics(
              container: true,
              checked: _agreed,
              child: Material(
                color: Colors.transparent,
                child: CheckboxListTile(
                  value: _agreed,
                  onChanged: (value) => setState(() => _agreed = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(AppStrings.consentAgreeLabel),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _agreed && !_busy ? _submit : null,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppStrings.consentSubmit),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.consentDeclineHint,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
