import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_theme.dart';

/// Ilustrasi "piring di dalam bingkai kamera" untuk panel pemindai.
///
/// Murni `CustomPainter` dengan token tema (tanpa PNG, tanpa gradien).
/// Bagian dekoratif: teks di panel tetap membawa makna. Dipakai dua kali:
/// di `CapturePanel` (onHero = true) dan di layar kamera saat memuat.
class PlateViewfinderIllustration extends StatelessWidget {
  const PlateViewfinderIllustration({
    super.key,
    this.size = 120,
    this.onHero = false,
    this.onCamera = false,
  });

  final double size;

  /// True bila digambar di atas permukaan hero hijau tua.
  final bool onHero;

  /// True bila digambar di atas preview kamera (latar mengikuti tema terbalik:
  /// gelap di light, terang di dark). Memakai `onPrimary` agar tetap terbaca.
  final bool onCamera;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final Color line;
    final Color plate;
    final Color plateInner;
    final Color accent;
    if (onCamera) {
      line = colors.onPrimary;
      plate = colors.onPrimary.withValues(alpha: 0.16);
      plateInner = colors.textPrimary.withValues(alpha: 0.32);
      accent = colors.accent;
    } else if (onHero) {
      line = colors.onHeroSurfaceMuted;
      plate = colors.onHeroSurface;
      plateInner = colors.heroTrack;
      accent = colors.onHeroAccent;
    } else {
      line = colors.primary;
      plate = colors.primaryContainer;
      plateInner = colors.surface;
      accent = colors.accent;
    }

    return Semantics(
      excludeSemantics: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: _PlateViewfinderPainter(
          line: line,
          plate: plate,
          plateInner: plateInner,
          accent: accent,
        ),
      ),
    );
  }
}

class _PlateViewfinderPainter extends CustomPainter {
  const _PlateViewfinderPainter({
    required this.line,
    required this.plate,
    required this.plateInner,
    required this.accent,
  });

  final Color line;
  final Color plate;
  final Color plateInner;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = math.min(size.width, size.height) * 0.46;
    final plateRadius = outer * 0.72;

    // Empat sudut bingkai: sudutnya "terbuka" agar terasa seperti viewfinder,
    // bukan kotak dekoratif penuh.
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.6, size.width * 0.022)
      ..color = line;
    final bracket = outer * 0.34;
    for (final dx in const [-1, 1]) {
      for (final dy in const [-1, 1]) {
        final x = center.dx + dx * outer;
        final y = center.dy + dy * outer;
        canvas.drawLine(
          Offset(x - dx * bracket, y),
          Offset(x, y),
          corner,
        );
        canvas.drawLine(
          Offset(x, y - dy * bracket),
          Offset(x, y),
          corner,
        );
      }
    }

    // Lingkaran putus-putus di luar piring.
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, size.width * 0.018)
      ..color = line;
    const segments = 24;
    for (var i = 0; i < segments; i += 2) {
      final start = (i / segments) * 2 * math.pi - math.pi / 2;
      final sweep = (1 / segments) * 2 * math.pi * 0.72;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outer * 0.9),
        start,
        sweep,
        false,
        dash,
      );
    }

    // Piring: dua cincin konsentris.
    canvas.drawCircle(
      center,
      plateRadius,
      Paint()..color = plate,
    );
    canvas.drawCircle(
      center,
      plateRadius * 0.76,
      Paint()..color = plateInner,
    );

    // Tiga "makanan" abstrak: cukup untuk memberi isyarat isi piring tanpa
    // mengarang contoh makanan tertentu.
    final food = Paint()..color = accent;
    canvas.drawCircle(
      center + Offset(-plateRadius * 0.34, plateRadius * 0.12),
      plateRadius * 0.17,
      food,
    );
    canvas.drawCircle(
      center + Offset(plateRadius * 0.28, -plateRadius * 0.22),
      plateRadius * 0.13,
      food,
    );
    final leaf = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, size.width * 0.02);
    canvas.drawLine(
      center + Offset(plateRadius * 0.05, plateRadius * 0.42),
      center + Offset(plateRadius * 0.38, plateRadius * 0.26),
      leaf,
    );
  }

  @override
  bool shouldRepaint(_PlateViewfinderPainter oldDelegate) =>
      oldDelegate.line != line ||
      oldDelegate.plate != plate ||
      oldDelegate.plateInner != plateInner ||
      oldDelegate.accent != accent;
}
