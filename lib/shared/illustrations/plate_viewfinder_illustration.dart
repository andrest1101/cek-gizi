import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_theme.dart';

/// Ilustrasi "piring dipindai" untuk panel pemindai (PRD v2.2).
///
/// Flat-lay piring dengan isi yang **heterogen & asimetris**: tumpukan nasi
/// di kiri bawah, satu lauk (bulat telur) di kanan atas, dan dua daun di
/// tengah. Tidak ada bentuk berulang sejajar, jadi tidak terbaca seperti
/// wajah. Sudut bingkai kamera putus-putus tetap dipertahankan.
///
/// Murni `CustomPainter` dengan token tema (tanpa PNG). Dekoratif: teks di
/// sebelahnya selalu membawa makna.
class PlateViewfinderIllustration extends StatelessWidget {
  const PlateViewfinderIllustration({
    super.key,
    this.size = 112,
    this.onHero = false,
    this.onCamera = false,
  });

  final double size;

  /// True bila digambar di atas permukaan hero hijau tua.
  final bool onHero;

  /// True bila digambar di atas preview kamera (latar terbalik: gelap di
  /// light, terang di dark). Memakai `onPrimary` agar tetap terbaca.
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

    // ── Bingkai kamera: empat sudut (viewfinder) ────────────────────────
    final cornerStroke = math.max(1.6, size.width * 0.022);
    final corner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = cornerStroke
      ..color = line;
    final bracket = outer * 0.34;
    for (final dx in const [-1, 1]) {
      for (final dy in const [-1, 1]) {
        final x = center.dx + dx * outer;
        final y = center.dy + dy * outer;
        canvas.drawLine(Offset(x - dx * bracket, y), Offset(x, y), corner);
        canvas.drawLine(Offset(x, y - dy * bracket), Offset(x, y), corner);
      }
    }

    // ── Lingkaran putus-putus di luar piring ────────────────────────────
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.4, size.width * 0.018)
      ..color = line.withValues(alpha: 0.9);
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

    // ── Piring: cincin luar + bagian dalam ──────────────────────────────
    canvas.drawCircle(center, plateRadius, Paint()..color = plate);
    canvas.drawCircle(
      center,
      plateRadius * 0.78,
      Paint()..color = plateInner,
    );

    // ── Isi piring (asimetris, bentuk berbeda) ──────────────────────────
    // Nasi: tumpukan kiri bawah, setengah lingkaran + tiga garis tekstur.
    final riceCenter = Offset(
      center.dx - plateRadius * 0.30,
      center.dy + plateRadius * 0.28,
    );
    final riceRadius = plateRadius * 0.30;
    canvas.drawArc(
      Rect.fromCircle(center: riceCenter, radius: riceRadius),
      math.pi,
      math.pi,
      true,
      Paint()..color = line.withValues(alpha: 0.28),
    );
    final riceStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.3, size.width * 0.015)
      ..color = line;
    for (var i = 0; i < 3; i++) {
      final y = riceCenter.dy - riceRadius * (0.22 + i * 0.2);
      final reach = riceRadius * (0.62 - i * 0.16);
      canvas.drawLine(
        Offset(riceCenter.dx - reach, y),
        Offset(riceCenter.dx + reach, y),
        riceStroke,
      );
    }

    // Lauk (telur): rounded square di kanan atas, sedikit diputar.
    final eggCenter = Offset(
      center.dx + plateRadius * 0.28,
      center.dy - plateRadius * 0.26,
    );
    final eggSize = plateRadius * 0.46;
    canvas.save();
    canvas.translate(eggCenter.dx, eggCenter.dy);
    canvas.rotate(-0.38);
    final eggRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: eggSize,
        height: eggSize,
      ),
      Radius.circular(eggSize * 0.26),
    );
    canvas.drawRRect(eggRect, Paint()..color = accent);
    canvas.drawCircle(
      Offset.zero,
      eggSize * 0.18,
      Paint()..color = plateInner,
    );
    canvas.restore();

    // Daun: dua elips memanjang diagonal di tengah, ruang kosong seimbang.
    final leafPaint = Paint()..color = line.withValues(alpha: 0.95);
    void drawLeaf(Offset origin, double angle, double length) {
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: length,
          height: length * 0.38,
        ),
        leafPaint,
      );
      canvas.restore();
    }

    drawLeaf(Offset(center.dx + plateRadius * 0.06, center.dy + plateRadius * 0.08),
        -0.35,
        plateRadius * 0.34);
    drawLeaf(Offset(center.dx + plateRadius * 0.02, center.dy + plateRadius * 0.30),
        0.15,
        plateRadius * 0.28);
  }

  @override
  bool shouldRepaint(_PlateViewfinderPainter oldDelegate) =>
      oldDelegate.line != line ||
      oldDelegate.plate != plate ||
      oldDelegate.plateInner != plateInner ||
      oldDelegate.accent != accent;
}
