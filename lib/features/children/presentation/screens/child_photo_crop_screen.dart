import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/presentation/providers/child_photo_providers.dart';
import 'package:cekgizi/features/children/presentation/widgets/circle_crop_guide.dart';

/// Argumen route untuk [ChildPhotoCropScreen].
final class ChildPhotoCropArgs {
  const ChildPhotoCropArgs({required this.bytes});

  final Uint8List bytes;
}

/// Layar penuh untuk menggeser/memperbesar foto profil sebelum dipakai.
///
/// Lingkaran di tengah adalah panduan: area itulah yang akan tampil sebagai
/// avatar. Hasil dipotong menjadi JPEG 512px tanpa EXIF di perangkat saja.
class ChildPhotoCropScreen extends ConsumerStatefulWidget {
  const ChildPhotoCropScreen({super.key, required this.args});

  final ChildPhotoCropArgs args;

  @override
  ConsumerState<ChildPhotoCropScreen> createState() =>
      _ChildPhotoCropScreenState();
}

class _ChildPhotoCropScreenState extends ConsumerState<ChildPhotoCropScreen> {
  static const double _guideSize = 280;

  final _boundaryKey = GlobalKey();
  final _controller = TransformationController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    final next = (currentScale * factor).clamp(1.0, 4.0);
    final ratio = next / currentScale;
    final offset = _controller.value.getTranslation();
    _controller.value = Matrix4.identity()
      ..translate(offset.x * ratio, offset.y * ratio)
      ..scale(next);
  }

  void _reset() => _controller.value = Matrix4.identity();

  Future<void> _apply() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final cropped = await ref
          .read(childPhotoEditorProvider)
          .crop(_boundaryKey);
      if (!mounted) return;
      if (cropped == null) {
        setState(() => _error = AppStrings.childPhotoCropError);
        return;
      }
      Navigator.of(context).pop<Uint8List>(cropped);
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppStrings.childPhotoCropError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.childPhotoCropTitle),
        leading: IconButton(
          tooltip: AppStrings.childPhotoCropCancel,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.childPhotoCropReset,
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                AppStrings.childPhotoCropHint,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: Center(
                  child: Semantics(
                    label: AppStrings.childPhotoCropGuideSemantics,
                    child: SizedBox.square(
                      dimension: _guideSize,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          RepaintBoundary(
                            key: _boundaryKey,
                            child: SizedBox.square(
                              dimension: _guideSize,
                              child: InteractiveViewer(
                                transformationController: _controller,
                                minScale: 1,
                                maxScale: 4,
                                child: Image.memory(
                                  widget.args.bytes,
                                  width: _guideSize,
                                  height: _guideSize,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium,
                                ),
                              ),
                            ),
                          ),
                          IgnorePointer(
                            child: CustomPaint(
                              painter: CircleCropGuidePainter(
                                overlayColor: colors.background.withValues(
                                  alpha: 0.72,
                                ),
                                borderColor: colors.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 16,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: AppStrings.childPhotoCropZoomOut,
                    onPressed: () => _zoom(1 / 1.3),
                    icon: const Icon(Icons.zoom_out_rounded),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton.filledTonal(
                    tooltip: AppStrings.childPhotoCropZoomIn,
                    onPressed: () => _zoom(1.3),
                    icon: const Icon(Icons.zoom_in_rounded),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  IconButton.filledTonal(
                    tooltip: AppStrings.childPhotoCropReset,
                    onPressed: _reset,
                    icon: const Icon(Icons.restart_alt_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _busy ? null : _apply,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(
                  _busy
                      ? AppStrings.childPhotoProcessing
                      : AppStrings.childPhotoCropUse,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
