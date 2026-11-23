import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Indikator "CekGizi sedang menjawab" - tiga titik bergantian menyala.
///
/// Mengikuti bentuk jawaban asisten (lembar `surface` ber-border) tetapi
/// menyusut selebar isinya, tanpa avatar dan tanpa nama agar identitas tidak
/// berulang. Hormati `MediaQuery.disableAnimations` (titik statis).
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _controller?.stop();
      return;
    }
    _controller ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final reduce = MediaQuery.of(context).disableAnimations;
    final controller = _controller;

    Widget dot(int index) {
      final circle = Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
      );
      if (reduce || controller == null) return circle;
      return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final phase = (controller.value + index / 3) % 1.0;
          final wave = (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
          return Opacity(opacity: 0.35 + wave * 0.65, child: child);
        },
        child: circle,
      );
    }

    return Semantics(
      label: AppStrings.tanyaAssistantTyping(),
      excludeSemantics: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.control + 4),
            border: Border.all(color: colors.outline, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [for (var i = 0; i < 3; i++) dot(i)],
          ),
        ),
      ),
    );
  }
}
