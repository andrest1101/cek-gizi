import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/core/utils/date_format.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/domain/repositories/child_exceptions.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/shared/widgets/child_avatar.dart';

/// Formulir tambah/ubah anak. Tanggal lahir dibatasi 0–60 bulan
/// (target pemantauan aplikasi) dan tidak boleh di masa depan.
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
  String _avatarKey = 'sprout';
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
      _avatarKey = existing.avatarKey;
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
    if (trimmed.length > 30) return 'Maksimal 30 karakter.';
    return null;
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.existing == null) {
        final created =
            await ref.read(childrenListProvider.notifier).addChild(
                  nickname: _nicknameController.text,
                  birthDate: _birthDate,
                  sex: _sex,
                  avatarKey: _avatarKey,
                );
        ref.read(selectedChildIdProvider.notifier).select(created.id);
      } else {
        final updated = widget.existing!.copyWith(
          nickname: _nicknameController.text.trim(),
          birthDate: _birthDate,
          sex: _sex,
          avatarKey: _avatarKey,
        );
        await ref.read(childrenListProvider.notifier).updateChild(updated);
      }
      if (!mounted) return;
      context.pop();
    } on ChildLimitException {
      setState(() => _error = AppStrings.childMaxReached);
    } catch (error) {
      setState(() {
        _error = 'Gagal menyimpan. Periksa koneksi internet kamu, lalu coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? AppStrings.childEditTitle : AppStrings.childAddTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              Center(
                child: ChildAvatar(avatarKey: _avatarKey, size: 96),
              ),
              const SizedBox(height: AppSpacing.xxl),
              TextFormField(
                controller: _nicknameController,
                validator: _validateNickname,
                textCapitalization: TextCapitalization.words,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: AppStrings.childNicknameLabel,
                  hintText: AppStrings.childNicknameHint,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: _busy ? null : _pickBirthDate,
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppStrings.childBirthDateLabel,
                    prefixIcon: const Icon(Icons.calendar_month_rounded),
                  ),
                  child: Text(
                    IdDateFormat.full(_birthDate),
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppStrings.childSexLabel,
                style: textTheme.labelLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              SegmentedButton<Sex>(
                segments: const [
                  ButtonSegment(
                    value: Sex.male,
                    label: Text(AppStrings.childSexMale),
                    icon: Icon(Icons.male_rounded),
                  ),
                  ButtonSegment(
                    value: Sex.female,
                    label: Text(AppStrings.childSexFemale),
                    icon: Icon(Icons.female_rounded),
                  ),
                ],
                selected: {_sex},
                onSelectionChanged: _busy
                    ? null
                    : (value) => setState(() => _sex = value.first),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppStrings.childAvatarLabel,
                style: textTheme.labelLarge?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final key in AvatarCatalog.icons.keys)
                    _AvatarOption(
                      avatarKey: key,
                      selected: key == _avatarKey,
                      onTap: _busy
                          ? null
                          : () => setState(() => _avatarKey = key),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.statusAlert,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text(AppStrings.childSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.avatarKey,
    required this.selected,
    required this.onTap,
  });

  final String avatarKey;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Avatar $avatarKey',
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? colors.primaryContainer : colors.surfaceVariant,
            border: Border.all(
              color: selected ? colors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            AvatarCatalog.of(avatarKey),
            size: 28,
            color: selected ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
