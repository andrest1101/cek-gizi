import 'package:flutter/material.dart';

import 'package:cekgizi/features/growth/domain/entities/sex.dart';

/// Ilustrasi siluet bust untuk avatar default anak (PRD §0 #7 versi foto
/// opsional lokal). Dua bentuk saja - laki-laki dan perempuan - sehingga
/// avatar selalu otomatis mengikuti jenis kelamin dan tidak perlu dipilih
/// manual.
///
/// Warna figur diambil dari token tema (`primary`), latar dari
/// `primaryContainer` di [ChildAvatar]. Tidak ada warna kulit atau wajah
/// kartun agar netral untuk semua anak.
class ChildAvatarFigurePainter extends CustomPainter {
  const ChildAvatarFigurePainter({
    required this.color,
    required this.sex,
    required this.highlightColor,
  });

  final Color color;
  final Sex sex;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;

    // Rambut panjang di belakang kepala (perempuan) atau kap rambut pendek
    // (laki-laki). Digambar lebih dulu agar kepala menutup bagian tengah.
    if (sex == Sex.female) {
      final hair = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.265, h * 0.19, w * 0.47, h * 0.52),
        Radius.circular(w * 0.235),
      );
      canvas.drawRRect(hair, paint);
    } else {
      final fringe = Path()
        ..addArc(
          Rect.fromCircle(center: Offset(w * 0.5, h * 0.40), radius: w * 0.225),
          3.32,
          2.96,
        )
        ..close();
      canvas.drawPath(fringe, paint);
    }

    // Bahu membulat: terasa seperti potret bust, bukan ikon orang generik.
    final shoulders = Path()
      ..moveTo(w * 0.19, h * 1.02)
      ..cubicTo(w * 0.19, h * 0.73, w * 0.33, h * 0.64, w * 0.5, h * 0.64)
      ..cubicTo(w * 0.67, h * 0.64, w * 0.81, h * 0.73, w * 0.81, h * 1.02)
      ..close();
    canvas.drawPath(shoulders, paint);

    // Kepala.
    canvas.drawCircle(Offset(w * 0.5, h * 0.42), w * 0.205, paint);

    // Kilau lembut di sisi atas kepala agar siluet tidak terlihat datar.
    final highlight = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.5, h * 0.42), radius: w * 0.135),
      3.55,
      0.95,
      false,
      highlight,
    );
  }

  @override
  bool shouldRepaint(ChildAvatarFigurePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.sex != sex ||
      oldDelegate.highlightColor != highlightColor;
}
