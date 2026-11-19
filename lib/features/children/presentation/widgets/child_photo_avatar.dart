import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/presentation/providers/child_photo_providers.dart';
import 'package:cekgizi/shared/widgets/child_avatar.dart';

/// Avatar anak yang otomatis memakai foto lokal bila tersedia, atau
/// ilustrasi default sesuai jenis kelamin.
class ChildPhotoAvatar extends ConsumerWidget {
  const ChildPhotoAvatar({
    super.key,
    required this.child,
    this.size = 44,
    this.semanticLabel,
  });

  final ChildProfile child;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(childPhotoPathProvider(child.id)).value;
    return ChildAvatar(
      sex: child.sex,
      avatarKey: child.avatarKey,
      photo: path == null ? null : FileImage(File(path)),
      size: size,
      semanticLabel: semanticLabel ?? child.nickname,
    );
  }
}
