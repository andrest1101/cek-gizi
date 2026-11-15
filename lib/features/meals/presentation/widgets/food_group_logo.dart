import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_theme.dart';

/// Logo kelompok pangan (PRD §3.7) sebagai PNG transparan.
///
/// Berbeda dengan Material Icon, logo ini adalah ilustrasi lengkap sehingga
/// dibaca tanpa warna latar tertentu. Semua PNG dinormalisasi dulu (konten
/// tiap gambar dipipihkan ke satu sisi panjang yang sama dan ditempatkan di
/// tengah kanvas 512x512), sehingga *semua logo dirender dengan ukuran yang
/// sama persis* di dalam lingkaran yang sama - tidak ada yang terlalu besar
/// atau terlalu kecil.
///
/// [size] = ukuran kotak gambar. Konten visual mengisi sekitar 76% kotak;
/// sisanya menjadi padding transparan sehingga logo tidak mepet/lingkar
/// yang berbeda-beda.
class FoodGroupLogo extends StatelessWidget {
  const FoodGroupLogo({
    super.key,
    required this.code,
    this.size = 34,
  });

  final String code;

  /// Ukuran kotak gambar (dp). Konten visual ±76% dari ini.
  final double size;

  static const _paths = <String, String>{
    'breast_milk': 'assets/logo_kelompok_norm/breast_milk.png',
    'grains_tubers': 'assets/logo_kelompok_norm/grains_tubers.png',
    'legumes_nuts': 'assets/logo_kelompok_norm/legumes_nuts.png',
    'dairy': 'assets/logo_kelompok_norm/dairy.png',
    'flesh': 'assets/logo_kelompok_norm/flesh.png',
    'eggs': 'assets/logo_kelompok_norm/eggs.png',
    'vit_a_fruit_veg': 'assets/logo_kelompok_norm/vit_a_fruit_veg.png',
    'other_fruit_veg': 'assets/logo_kelompok_norm/other_fruit_veg.png',
  };

  @override
  Widget build(BuildContext context) {
    final path = _paths[code];
    final colors = AppTheme.colorsOf(context);
    if (path == null) {
      return Icon(
        Icons.restaurant_rounded,
        size: size * 0.8,
        color: colors.primary,
      );
    }
    return Semantics(
      excludeSemantics: true,
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.restaurant_rounded,
          size: size * 0.8,
          color: colors.primary,
        ),
      ),
    );
  }
}
