import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/features/growth/domain/entities/anthropometry_index.dart';

/// Nada status (PRD §7.2: warna status tidak pernah sinyal tunggal —
/// selalu disertai ikon dan teks).
enum StatusTone { good, watch, alert }

final class StatusCopy {
  const StatusCopy({
    required this.title,
    required this.body,
    required this.action,
    required this.tone,
  });

  final String title;
  final String body;
  final String action;
  final StatusTone tone;
}

abstract final class GrowthStatusCopy {
  const GrowthStatusCopy._();

  static StatusCopy haz(String? code) => switch (code) {
        'very_short' => const StatusCopy(
            title: AppStrings.statusAlertTitle,
            body: AppStrings.statusAlertBody,
            action: AppStrings.statusAlertAction,
            tone: StatusTone.alert,
          ),
        'short' => const StatusCopy(
            title: AppStrings.statusBelowTitle,
            body: AppStrings.statusBelowBody,
            action: AppStrings.statusBelowAction,
            tone: StatusTone.watch,
          ),
        'normal' => const StatusCopy(
            title: AppStrings.statusNormalTitle,
            body: AppStrings.statusNormalBody,
            action: AppStrings.statusNormalAction,
            tone: StatusTone.good,
          ),
        'tall' => const StatusCopy(
            title: AppStrings.statusAboveTitle,
            body: AppStrings.statusAboveBody,
            action: AppStrings.statusAboveAction,
            tone: StatusTone.watch,
          ),
        null => const StatusCopy(
            title: AppStrings.statusOutOfRangeTitle,
            body: AppStrings.statusOutOfRangeBody,
            action: AppStrings.statusBelowAction,
            tone: StatusTone.watch,
          ),
        _ => const StatusCopy(
            title: AppStrings.statusOutOfRangeTitle,
            body: AppStrings.statusOutOfRangeBody,
            action: AppStrings.statusBelowAction,
            tone: StatusTone.watch,
          ),
      };

  static StatusCopy waz(String? code) => switch (code) {
        'very_low' => const StatusCopy(
            title: AppStrings.statusAlertTitle,
            body: AppStrings.statusAlertBody,
            action: AppStrings.statusAlertAction,
            tone: StatusTone.alert,
          ),
        'low' => const StatusCopy(
            title: AppStrings.statusBelowTitle,
            body: AppStrings.statusBelowBody,
            action: AppStrings.statusBelowAction,
            tone: StatusTone.watch,
          ),
        'normal' => const StatusCopy(
            title: AppStrings.statusNormalTitle,
            body: AppStrings.statusNormalBody,
            action: AppStrings.statusNormalAction,
            tone: StatusTone.good,
          ),
        'risk_overweight' => const StatusCopy(
            title: AppStrings.statusAboveTitle,
            body: AppStrings.statusAboveBody,
            action: AppStrings.statusAboveAction,
            tone: StatusTone.watch,
          ),
        null => const StatusCopy(
            title: AppStrings.statusOutOfRangeTitle,
            body: AppStrings.statusOutOfRangeBody,
            action: AppStrings.statusBelowAction,
            tone: StatusTone.watch,
          ),
        _ => const StatusCopy(
            title: AppStrings.statusOutOfRangeTitle,
            body: AppStrings.statusOutOfRangeBody,
            action: AppStrings.statusBelowAction,
            tone: StatusTone.watch,
          ),
      };

  static StatusCopy whz(String? code) => switch (code) {
        'severe_wasting' => const StatusCopy(
            title: AppStrings.statusAlertTitle,
            body: AppStrings.statusAlertBody,
            action: AppStrings.statusAlertAction,
            tone: StatusTone.alert,
          ),
        'wasting' => const StatusCopy(
            title: AppStrings.statusBelowTitle,
            body: AppStrings.statusBelowBody,
            action: AppStrings.statusBelowAction,
            tone: StatusTone.watch,
          ),
        'normal' => const StatusCopy(
            title: AppStrings.statusNormalTitle,
            body: AppStrings.statusNormalBody,
            action: AppStrings.statusNormalAction,
            tone: StatusTone.good,
          ),
        'risk_over' => const StatusCopy(
            title: AppStrings.statusAboveTitle,
            body: AppStrings.statusAboveBody,
            action: AppStrings.statusAboveAction,
            tone: StatusTone.watch,
          ),
        'overweight' || 'obese' => const StatusCopy(
            title: AppStrings.statusAboveTitle,
            body: AppStrings.statusAboveBody,
            action: AppStrings.statusAboveAction,
            tone: StatusTone.watch,
          ),
        null => const StatusCopy(
            title: AppStrings.statusOutOfRangeTitle,
            body: AppStrings.statusOutOfRangeBody,
            action: AppStrings.statusBelowAction,
            tone: StatusTone.watch,
          ),
        _ => const StatusCopy(
            title: AppStrings.statusOutOfRangeTitle,
            body: AppStrings.statusOutOfRangeBody,
            action: AppStrings.statusBelowAction,
            tone: StatusTone.watch,
          ),
      };

  static StatusCopy forIndex(AnthropometryIndex index, String? code) =>
      switch (index) {
        AnthropometryIndex.haz => haz(code),
        AnthropometryIndex.waz => waz(code),
        AnthropometryIndex.whz => whz(code),
      };

  static Map<String, String> officialCategories(AnthropometryIndex index) =>
      switch (index) {
        AnthropometryIndex.haz => AppStrings.officialCategoryHaz,
        AnthropometryIndex.waz => AppStrings.officialCategoryWaz,
        AnthropometryIndex.whz => AppStrings.officialCategoryWhz,
      };

  static int severity(AnthropometryIndex index, String? code) =>
      switch (forIndex(index, code).tone) {
        StatusTone.good => 1,
        StatusTone.watch => 2,
        StatusTone.alert => 3,
      };

  /// "-0,53" gaya Indonesia; null aman.
  static String formatZ(double? z) {
    if (z == null) return '—';
    return z.toStringAsFixed(2).replaceFirst('.', ',');
  }

  static String formatKgCm(double value) =>
      value.toStringAsFixed(1).replaceFirst('.', ',');
}
