import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/chat/domain/entities/chat_message.dart';

/// Kartu khusus untuk jawaban dengan `safety_flag` (PRD §3.8, §6.7).
///
/// Bukan bubble biasa: warna status selalu berpasangan dengan ikon dan
/// teks, dan aksi tersedia langsung (darurat → hubungi 112; sebaliknya →
/// konfirmasi mengerti).
class SafetyCard extends StatefulWidget {
  const SafetyCard({super.key, required this.flag});

  final ChatSafetyFlag flag;

  @override
  State<SafetyCard> createState() => _SafetyCardState();
}

class _SafetyCardState extends State<SafetyCard> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isEmergency = widget.flag == ChatSafetyFlag.emergency;

    if (_acknowledged) return const SizedBox.shrink();

    final accent = isEmergency ? colors.statusAlert : colors.statusWatchText;
    final fill = isEmergency
        ? colors.statusAlert.withValues(alpha: 0.12)
        : colors.statusWatch.withValues(alpha: 0.16);

    return Semantics(
      container: true,
      label: isEmergency
          ? AppStrings.tanyaSafetyEmergencySemantics
          : AppStrings.tanyaSafetyReferSemantics,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: accent.withValues(alpha: 0.55), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isEmergency
                  ? Icons.emergency_rounded
                  : Icons.medical_information_rounded,
              color: accent,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEmergency
                        ? AppStrings.tanyaSafetyEmergencyTitle
                        : AppStrings.tanyaSafetyReferTitle,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isEmergency
                        ? AppStrings.tanyaSafetyEmergencyBody
                        : AppStrings.tanyaSafetyReferBody,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isEmergency) ...[
                    FilledButton.icon(
                      onPressed: () => _call112(context),
                      icon: const Icon(Icons.phone_rounded, size: 20),
                      label: const Text(AppStrings.tanyaSafetyEmergencyCall),
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.statusAlert,
                        foregroundColor: colors.onPrimary,
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppStrings.tanyaSafetyEmergencyNote,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ] else
                    OutlinedButton(
                      onPressed: () => setState(() => _acknowledged = true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        minimumSize: const Size(0, 48),
                        side: BorderSide(color: accent.withValues(alpha: 0.6)),
                      ),
                      child: const Text(AppStrings.tanyaSafetyReferAck),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _call112(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: '112');
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        _showCallFailed(context);
      }
    } catch (_) {
      if (context.mounted) _showCallFailed(context);
    }
  }

  void _showCallFailed(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(AppStrings.tanyaCallFailed)));
  }
}
