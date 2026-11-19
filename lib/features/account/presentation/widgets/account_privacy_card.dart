import 'package:flutter/material.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/shared/widgets/settings_tile.dart';

/// Ringkasan privasi yang jujur: apa yang tersimpan di server, apa yang
/// hanya ada di perangkat, dan apa yang dibuang setelah dipakai.
class AccountPrivacyCard extends StatelessWidget {
  const AccountPrivacyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      decoration: AppSurfaces.card(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SettingsTile(
            icon: Icons.child_care_rounded,
            title: AppStrings.accountPrivacyChildTitle,
            subtitle: AppStrings.accountPrivacyChildBody,
          ),
          Divider(height: 1, indent: 68, color: colors.outline),
          const SettingsTile(
            icon: Icons.face_retouching_natural_rounded,
            title: AppStrings.accountPrivacyPhotoTitle,
            subtitle: AppStrings.accountPrivacyPhotoBody,
          ),
          Divider(height: 1, indent: 68, color: colors.outline),
          const SettingsTile(
            icon: Icons.photo_camera_rounded,
            title: AppStrings.accountPrivacyFoodTitle,
            subtitle: AppStrings.accountPrivacyFoodBody,
          ),
          Divider(height: 1, indent: 68, color: colors.outline),
          const SettingsTile(
            icon: Icons.notifications_active_outlined,
            title: AppStrings.accountPrivacyReminderTitle,
            subtitle: AppStrings.accountPrivacyReminderBody,
          ),
        ],
      ),
    );
  }
}
