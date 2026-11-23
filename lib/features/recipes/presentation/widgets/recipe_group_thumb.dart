import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/meals/presentation/widgets/food_group_logo.dart';

/// "Sampul" resep: kolase logo kelompok pangan yang tercakup.
///
/// Memakai aset logo kelompok yang sudah ada (bukan ikon generik), sehingga
/// tiap resep punya identitas visual yang jujur terhadap isinya. Maksimum
/// [maxLogos] logo ditampilkan dalam grid 2 kolom; kelompok selengkapnya
/// tetap terbaca lewat chip di kartu dan label Semantics.
class RecipeGroupThumb extends StatelessWidget {
  const RecipeGroupThumb({
    super.key,
    required this.groups,
    this.size = 80,
    this.maxLogos = 4,
  });

  final List<String> groups;
  final double size;
  final int maxLogos;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final shown = groups.take(maxLogos).toList();
    final logoSize = (size - 8) / 2;
    final labels = groups.map(AppStrings.groupLabel).join(', ');

    return Semantics(
      label: AppStrings.recipesThumbSemantics(labels),
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.control + 4),
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: logoSize * 2,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final code in shown)
                FoodGroupLogo(code: code, size: logoSize),
            ],
          ),
        ),
      ),
    );
  }
}
