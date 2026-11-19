import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/notifications/reminder_providers.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/shared/widgets/section_heading.dart';
import 'package:cekgizi/shared/widgets/settings_tile.dart';

/// Bagian Pengingat di layar Akun (PRD §6.8).
///
/// Dua pengingat lokal, default MATI. Setiap perubahan disimpan ke
/// `LocalPrefs` lalu dijadwalkan ulang penuh oleh [ReminderScheduler];
/// bila penerapan gagal, provider mengembalikan state sebelumnya.
class ReminderSettingsSection extends ConsumerWidget {
  const ReminderSettingsSection({super.key});

  static String _formatTime(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}.${minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final settings = ref.watch(reminderSettingsProvider);
    final notifier = ref.read(reminderSettingsProvider.notifier);

    void showPermissionDenied() {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(AppStrings.settingsReminderPermissionDenied),
          ),
        );
    }

    void showApplyError() {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text(AppStrings.settingsReminderSaveError)),
        );
    }

    Future<void> toggleMonthly(bool value) async {
      try {
        final ok = await notifier.setMonthlyEnabled(value);
        if (!ok && context.mounted) showPermissionDenied();
      } catch (_) {
        if (context.mounted) showApplyError();
      }
    }

    Future<void> toggleDaily(bool value) async {
      try {
        final ok = await notifier.setDailyEnabled(value);
        if (!ok && context.mounted) showPermissionDenied();
      } catch (_) {
        if (context.mounted) showApplyError();
      }
    }

    Future<void> changeMonthlyDay(int? day) async {
      if (day == null) return;
      try {
        await notifier.setMonthlyDay(day);
      } catch (_) {
        if (context.mounted) showApplyError();
      }
    }

    Future<void> changeDailyTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
          hour: settings.dailyHour,
          minute: settings.dailyMinute,
        ),
        helpText: AppStrings.settingsReminderTimeLabel,
      );
      if (picked == null) return;
      try {
        await notifier.setDailyTime(picked.hour, picked.minute);
      } catch (_) {
        if (context.mounted) showApplyError();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeading(title: AppStrings.settingsRemindersTitle),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: AppSurfaces.card(context),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsTile(
                icon: Icons.calendar_month_rounded,
                title: AppStrings.settingsReminderMonthlyTitle,
                subtitle: AppStrings.settingsReminderMonthlyBody(
                  settings.monthlyDay,
                ),
                trailing: Switch.adaptive(
                  value: settings.monthlyEnabled,
                  onChanged: toggleMonthly,
                ),
              ),
              if (settings.monthlyEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    68,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.settingsReminderMonthlyDayLabel,
                        style: AppTextStyles.label.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      DropdownButton<int>(
                        value: settings.monthlyDay,
                        onChanged: changeMonthlyDay,
                        items: [
                          for (var day = 1; day <= 28; day++)
                            DropdownMenuItem<int>(
                              value: day,
                              child: Text('$day'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              Divider(height: 1, indent: 68, color: colors.outline),
              SettingsTile(
                icon: Icons.restaurant_rounded,
                title: AppStrings.settingsReminderDailyTitle,
                subtitle: AppStrings.settingsReminderDailyBody(
                  _formatTime(settings.dailyHour, settings.dailyMinute),
                ),
                trailing: Switch.adaptive(
                  value: settings.dailyEnabled,
                  onChanged: toggleDaily,
                ),
              ),
              if (settings.dailyEnabled)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    68,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.settingsReminderTimeLabel,
                        style: AppTextStyles.label.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      TextButton(
                        onPressed: changeDailyTime,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                        ),
                        child: Text(
                          _formatTime(settings.dailyHour, settings.dailyMinute),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: colors.primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          AppStrings.settingsReminderFootnote,
          style: AppTextStyles.label.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
