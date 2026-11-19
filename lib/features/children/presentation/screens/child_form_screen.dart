import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/children/data/services/child_photo_service.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/domain/repositories/child_exceptions.dart';
import 'package:cekgizi/features/children/presentation/providers/child_photo_providers.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/shared/widgets/child_avatar.dart';
import 'package:cekgizi/shared/widgets/segment_control.dart';

/// Formulir tambah/ubah anak. Tanggal lahir dibatasi 0–60 bulan
/// (target pemantauan aplikasi) dan tidak boleh di masa depan.
///
/// Foto profil opsional: dipilih dari kamera/galeri, dikompres, lalu
/// disimpan **hanya di perangkat** setelah data anak berhasil disimpan.
class ChildFormScreen extends ConsumerStatefulWidget {
  const ChildFormScreen({super.key, this.existing});

  final ChildProfile? existing;

  @override
  ConsumerState<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends ConsumerState<ChildFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameController;

  DateTime _birthDate = DateTime.now();
  Sex _sex = Sex.male;

  /// Foto baru yang belum ditulis ke disk (ditahan di memori sampai simpan).
  Uint8List? _pendingPhoto;
  bool _photoRemoved = false;
  bool _photoBusy = false;
  String? _photoError;

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nicknameController = TextEditingController(text: existing?.nickname);
    if (existing != null) {
      _birthDate = existing.birthDate;
      _sex = existing.sex;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  DateTime get _firstAllowedDate {
    final now = DateTime.now();
    return DateTime(now.year, now.month - 60, now.day);
  }

  String get _displayName {
    final name = _nicknameController.text.trim();
    return name.isEmpty ? AppStrings.childAvatarLabel : name;
  }

  Future<void> _pickBirthDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate.isBefore(_firstAllowedDate)
          ? _firstAllowedDate
          : (_birthDate.isAfter(today) ? today : _birthDate),
      firstDate: _firstAllowedDate,
      lastDate: today,
      helpText: AppStrings.childBirthDateLabel,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  String? _validateNickname(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return AppStrings.validationRequired;
    if (trimmed.length > 30) return AppStrings.childNicknameMaxLength;
    return null;
  }

  Future<void> _pickPhoto(ChildPhotoSource source) async {
    if (_photoBusy || _busy) return;
    setState(() {
      _photoBusy = true;
      _photoError = null;
    });
    try {
      final bytes = await ref.read(childPhotoPickerProvider).pick(source);
      if (!mounted) return;
      if (bytes != null) {
        setState(() {
          _pendingPhoto = bytes;
          _photoRemoved = false;
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(() => _photoError = AppStrings.childPhotoPermissionError);
      }
    } on ChildPhotoException {
      if (mounted) {
        setState(() => _photoError = AppStrings.childPhotoError);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _photoError = AppStrings.childPhotoError);
      }
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _removePhoto() async {
    if (_photoBusy || _busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.childPhotoRemoveTitle),
        content: const Text(AppStrings.childPhotoRemoveBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.childDeleteCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.childDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _pendingPhoto = null;
      _photoRemoved = true;
      _photoError = null;
    });
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final avatarKey = _sex == Sex.male ? 'boy' : 'girl';

    late final String childId;
    try {
      if (widget.existing == null) {
        final created = await ref
            .read(childrenListProvider.notifier)
            .addChild(
              nickname: _nicknameController.text,
              birthDate: _birthDate,
              sex: _sex,
              avatarKey: avatarKey,
            );
        childId = created.id;
        ref.read(selectedChildIdProvider.notifier).select(created.id);
      } else {
        final updated = widget.existing!.copyWith(
          nickname: _nicknameController.text.trim(),
          birthDate: _birthDate,
          sex: _sex,
          avatarKey: avatarKey,
        );
        await ref.read(childrenListProvider.notifier).updateChild(updated);
        childId = updated.id;
      }
    } on ChildLimitException {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppStrings.childMaxReached;
        });
      }
      return;
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppStrings.childSaveError;
        });
      }
      return;
    }

    // Data anak sudah tersimpan. Foto disimpan terpisah agar kegagalan file
    // tidak membuat pengguna menyimpan ulang data (dan mungkin duplikat).
    var photoFailed = false;
    try {
      final store = ref.read(childPhotoStoreProvider);
      if (_pendingPhoto != null) {
        await store.save(childId, _pendingPhoto!);
      } else if (_photoRemoved) {
        await store.delete(childId);
      }
      ref.invalidate(childPhotoPathProvider(childId));
    } catch (_) {
      photoFailed = true;
    }

    if (!mounted) return;
    setState(() => _busy = false);
    if (photoFailed) {
      messenger.showSnackBar(
        const SnackBar(content: Text(AppStrings.childPhotoSaveError)),
      );
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final isEdit = widget.existing != null;
    final existingPath = widget.existing == null
        ? null
        : ref.watch(childPhotoPathProvider(widget.existing!.id)).value;
    final ImageProvider? previewPhoto;
    if (_pendingPhoto != null) {
      previewPhoto = MemoryImage(_pendingPhoto!);
    } else if (!_photoRemoved && existingPath != null) {
      previewPhoto = FileImage(File(existingPath));
    } else {
      previewPhoto = null;
    }
    final hasPhoto = previewPhoto != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? AppStrings.childEditTitle : AppStrings.childAddTitle,
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: colors.statusAlert,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _error!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.statusAlert,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text(AppStrings.childSave),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              AppSpacing.xxl,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: AppSurfaces.sunken(context, radius: AppRadius.card),
                child: Column(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Semantics(
                          label: AppStrings.childPhotoPreviewSemantics(
                            _displayName,
                          ),
                          image: true,
                          child: ChildAvatar(
                            sex: _sex,
                            photo: previewPhoto,
                            size: 104,
                            semanticLabel: _displayName,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colors.surface,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              _photoBusy
                                  ? Icons.hourglass_top_rounded
                                  : Icons.photo_camera_rounded,
                              size: 18,
                              color: colors.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppStrings.childPhotoTitle,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      AppStrings.childPhotoHint,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    if (_photoBusy) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppStrings.childPhotoProcessing,
                        style: AppTextStyles.label.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (_photoError != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 16,
                            color: colors.statusAlert,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _photoError!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colors.statusAlert,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _photoBusy || _busy
                              ? null
                              : () => _pickPhoto(ChildPhotoSource.camera),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(
                            Icons.photo_camera_rounded,
                            size: 18,
                          ),
                          label: const Text(AppStrings.childPhotoTake),
                        ),
                        OutlinedButton.icon(
                          onPressed: _photoBusy || _busy
                              ? null
                              : () => _pickPhoto(ChildPhotoSource.gallery),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(
                            Icons.photo_library_outlined,
                            size: 18,
                          ),
                          label: const Text(AppStrings.childPhotoGallery),
                        ),
                        if (hasPhoto)
                          TextButton.icon(
                            onPressed: _photoBusy || _busy
                                ? null
                                : _removePhoto,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              foregroundColor: colors.statusAlert,
                            ),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                            ),
                            label: const Text(AppStrings.childPhotoRemove),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppStrings.childDetailsSectionTitle,
                style: AppTextStyles.titleMedium.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _nicknameController,
                validator: _validateNickname,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 30,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: AppStrings.childNicknameLabel,
                  hintText: AppStrings.childNicknameHint,
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _FormSectionHeading(
                title: AppStrings.childBirthDateLabel,
                icon: Icons.cake_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: _busy ? null : _pickBirthDate,
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: AppStrings.childBirthDateLabel,
                    prefixIcon: Icon(Icons.calendar_month_rounded),
                  ),
                  child: Text(
                    IdDateFormat.full(_birthDate),
                    style: AppTextStyles.body.copyWith(
                      color: colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              Text(
                AppStrings.childBirthDateHint,
                style: AppTextStyles.label.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const SizedBox(height: AppSpacing.lg),
              const _FormSectionHeading(
                title: AppStrings.childSexLabel,
                icon: Icons.wc_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentControl<Sex>(
                selected: _sex,
                onChanged: (value) => setState(() => _sex = value),
                options: const <SegmentOption<Sex>>[
                  SegmentOption(
                    value: Sex.male,
                    label: AppStrings.childSexMale,
                    semanticLabel: AppStrings.childSexMale,
                  ),
                  SegmentOption(
                    value: Sex.female,
                    label: AppStrings.childSexFemale,
                    semanticLabel: AppStrings.childSexFemale,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.childAvatarHint,
                style: AppTextStyles.label.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormSectionHeading extends StatelessWidget {
  const _FormSectionHeading({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
