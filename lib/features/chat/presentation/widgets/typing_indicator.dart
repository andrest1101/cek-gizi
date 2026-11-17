import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Indikator "CekGizi sedang menjawab" - tiga titik bergantian menyala.
/// Hormati `MediaQuery.disableAnimations` (titik statis).
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

    Widget dots() => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final dot = Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
            );
            if (reduce || controller == null) return dot;
            return AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                // Fase bergeser 0.33 per titik agar menyala bergantian.
                final phase = (controller.value + index / 3) % 1.0;
                final wave = (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
                return Opacity(opacity: 0.35 + wave * 0.65, child: child);
              },
              child: dot,
            );
          }),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.spa_rounded, size: 18, color: colors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outline, width: 1),
          ),
          child: Semantics(
            label: AppStrings.tanyaAssistantTyping(),
            child: dots(),
          ),
        ),
      ],
    );
  }
}
