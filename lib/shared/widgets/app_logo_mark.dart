import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Logo CekGizi sebagai penanda merek di top bar.
///
/// Memakai `logo_cek-gizi_mark.png` — versi 256×256 yang dipotong rapat dari
/// master `logo_cek-gizi.png` (1024×1024) agar huruf C–G terbaca pada ukuran
/// 40dp. Master tetap dipakai utuh untuk ikon launcher.
///
/// Logo bersifat dekoratif karena nama aplikasi selalu ada di sebelahnya;
/// semantiknya dikeluarkan agar pembaca layar tidak menyebut nama dua kali.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final radius = BorderRadius.circular(AppRadius.control);
    final decodeWidth = (size * MediaQuery.devicePixelRatioOf(context)).round();
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: radius),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: colors.outline, width: 1),
        ),
        child: Image.asset(
          'assets/logo/logo_cek-gizi_mark.png',
          width: size,
          height: size,
          cacheWidth: decodeWidth,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
