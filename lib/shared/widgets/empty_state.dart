import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/shared/widgets/tonal_icon_circle.dart';

/// Empty state (PRD §7.1, §6.9): ikon lingkaran tonal + satu kalimat +
/// satu tombol opsional.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    this.illustration,
    required this.title,
    this.iconSemantics,
    this.body,
    this.action,
  });

  final IconData icon;

  /// Ilustrasi (bergambar) pengganti ikon; bila diisi, menggantikan [icon].
  final Widget? illustration;

  /// Judul singkat (titleMedium), mis. "Belum ada catatan makan hari ini."
  final String title;

  /// Label Semantics ikon; default = [title].
  final String? iconSemantics;

  /// Kalimat penjelas opsional (bodySmall, teks sekunder).
  final String? body;

  /// Satu tombol aksi (mis. "Catat manual" / "Foto makanan").
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          illustration ??
              TonalIconCircle(
                icon: icon,
                iconSemantics: iconSemantics ?? title,
              ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
            textAlign: TextAlign.center,
          ),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              body!,
              style: textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
