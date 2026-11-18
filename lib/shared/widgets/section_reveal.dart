import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_motion.dart';

/// Masuk halus untuk satu blok konten (opacity + 8dp naik).
///
/// Gerak dipakai sekali saat blok pertama muncul, bukan berulang, dan selalu
/// lewat [AppMotion.of] sehingga pengaturan "kurangi animasi" dihormati.
/// Tidak membungkus logika bisnis dan tidak mengubah struktur semantik.
class SectionReveal extends StatelessWidget {
  const SectionReveal({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.normal);
    if (duration == Duration.zero) return child;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: AppMotion.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
