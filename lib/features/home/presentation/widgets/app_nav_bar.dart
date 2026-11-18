import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Satu destinasi navigasi utama.
///
/// Daftar ini adalah sumber kebenaran urutan tab: indeks di sini HARUS sama
/// dengan urutan `StatefulShellBranch` di `core/router.dart`.
enum AppDestination {
  home(
    path: '/',
    label: AppStrings.navHome,
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  makan(
    path: '/makan',
    label: AppStrings.navMakan,
    icon: Icons.restaurant_outlined,
    selectedIcon: Icons.restaurant_rounded,
  ),
  recipes(
    path: '/recipes',
    label: AppStrings.navRecipe,
    icon: Icons.menu_book_outlined,
    selectedIcon: Icons.menu_book_rounded,
  ),
  growth(
    path: '/growth',
    label: AppStrings.navGrowth,
    icon: Icons.show_chart_rounded,
    selectedIcon: Icons.show_chart_rounded,
  ),
  account(
    path: '/account',
    label: AppStrings.navAccount,
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
  );

  const AppDestination({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Bilah navigasi utama: permukaan `surface` tanpa garis atas, dengan pil
/// tonal di destinasi aktif (bukan `NavigationBar` bawaan, agar tidak terasa
/// seperti template).
///
/// Label selalu tampil supaya ikon tidak menjadi tebakan. Target sentuh tiap
/// item ≥ 48dp dan teks dibatasi satu baris agar aman di 360dp @1,3.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Material(
      color: colors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              for (var index = 0; index < AppDestination.values.length; index++)
                Expanded(
                  child: _NavItem(
                    destination: AppDestination.values[index],
                    selected: index == currentIndex,
                    onTap: () => onSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final iconColor = selected ? colors.primary : colors.textSecondary;
    final labelColor = selected ? colors.primary : colors.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.fast),
                  curve: AppMotion.easeOutCubic,
                  width: 44,
                  height: 26,
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 19,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.navLabel.copyWith(
                    color: labelColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
