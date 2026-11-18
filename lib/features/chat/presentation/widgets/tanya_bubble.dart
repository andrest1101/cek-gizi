import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Bubble Tanya Gizi yang mengambang di kanan bawah, di atas bilah navigasi.
///
/// Tanya bukan lagi tab: bubble ini satu-satunya pintu masuknya. Sengaja
/// memakai pil berlabel (bukan ikon telanjang) agar orang tua baru tetap
/// menemukannya tanpa menebak ikon.
class TanyaBubble extends StatelessWidget {
  const TanyaBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return FloatingActionButton.extended(
      heroTag: null,
      tooltip: AppStrings.tanyaBubbleSemantics,
      onPressed: () => context.push('/tanya'),
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      icon: const Icon(Icons.chat_bubble_rounded, size: 20),
      label: Text(
        AppStrings.tanyaBubbleLabel,
        style: AppTextStyles.label.copyWith(
          color: colors.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
