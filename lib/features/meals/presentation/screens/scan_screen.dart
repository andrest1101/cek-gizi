import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/meals/domain/entities/meal_scan.dart';
import 'package:cekgizi/features/meals/presentation/providers/scan_providers.dart';
import 'package:cekgizi/features/meals/presentation/widgets/manual_food_sheet.dart';
import 'package:cekgizi/features/meals/presentation/widgets/meal_scan_result_sheet.dart';

/// Layar scanner makanan (PRD §6.4): viewfinder berbentuk piring.
///
/// Alur: ambil/galeri foto → kompres (1024px, JPEG q75, ≤300KB, EXIF disingkirkan)
/// → invoke `analyze-meal` Edge Function → bottom sheet hasil (bisa diedit) →
/// simpan sebagai catatan (`source=scan`). Foto tidak pernah disimpan.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _initInFlight = false;
  bool _busy = false;
  String? _cameraError;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  /// Kamera dibiarkan hidup saat app hanya berpindah ke latar (Android
  /// menjeda preview sendiri). Model "dispose di on paused" terlalu agresif
  /// dan membuat `initialize()` yang sedang berjalan tidak pernah selesai
  /// ("Menyiapkan kamera…" selamanya). Di-resume, cukup pastikan controller
  /// siap lagi bila perlu.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final controller = _controller;
    final ready = controller != null && controller.value.isInitialized;
    if (!ready && _cameraError == null) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (!mounted || _initInFlight) return;
    final existing = _controller;
    if (existing != null && existing.value.isInitialized) return;

    _initInFlight = true;
    setState(() {
      _initializing = true;
      _cameraError = null;
    });
    CameraController? controller;
    try {
      ref.invalidate(availableCamerasProvider);
      final cameras = await ref
          .read(availableCamerasProvider.future)
          .timeout(const Duration(seconds: 10));
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _cameraError = 'no_camera';
        });
        return;
      }
      final backCamera = cameras.firstWhere(
        (camera) =>
            camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      controller = CameraController(
        backCamera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      // Overlay permission otomatis muncul dari plugin bila belum diizinkan;
      // batas waktu menjaga agar tidak menggantung di layar loading.
      await controller.initialize().timeout(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initializing = false;
      });
      controller = null;
    } on CameraException catch (exception) {
      if (!mounted) return;
      final denied = exception.code.startsWith('CameraAccessDenied');
      setState(() {
        _initializing = false;
        _cameraError = denied ? 'permission' : 'unavailable';
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraError = 'unavailable';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraError = 'unavailable';
      });
    } finally {
      if (controller != null) {
        try {
          await controller.dispose();
        } catch (_) {
          // abaikan - controller gagal diinisialisasi
        }
      }
      _initInFlight = false;
    }
  }

  ChildProfile? get _child => ref.read(selectedChildProvider).value;

  /// Buka sheet "Catat manual" untuk anak terpilih (offline-first);
  /// setelah tersimpan, kembali ke layar sebelumnya.
  void _openManualEntry() {
    final child = _child;
    if (child == null) return;
    showManualFoodSheet(context, childId: child.id).then((saved) {
      if (saved == true && mounted) context.pop();
    });
  }

  Future<void> _analyzeFile(XFile file) async {
    final child = _child;
    if (child == null || _busy) return;
    final ageMonths = child.ageInCompletedMonths(DateTime.now());
    setState(() {
      _busy = true;
      _scanError = null;
    });
    try {
      final bytes = await ref
          .read(mealScanCompressorProvider)
          .compress(File(file.path));
      final result = await ref.read(mealScanRepositoryProvider).analyze(
            imageBytes: bytes,
            ageMonths: ageMonths,
          );
      if (!mounted) return;
      if (!result.isFood || result.items.isEmpty) {
        setState(() {
          _busy = false;
          _scanError = 'no_food';
        });
        return;
      }
      setState(() => _busy = false);
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            MealScanResultSheet(result: result, childId: child.id),
      );
      if (saved == true && mounted) {
        context.pop();
      }
    } on ScanException catch (exception) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _scanError = exception.code;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _scanError = 'ai_unavailable';
      });
    }
  }

  Future<void> _shutter() async {
    final controller = _controller;
    if (controller == null || _busy || !controller.value.isInitialized) {
      return;
    }
    try {
      final file = await controller.takePicture();
      await _analyzeFile(file);
    } catch (_) {
      if (!mounted) return;
      setState(() => _scanError = 'invalid_image');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_busy) return;
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;
      await _analyzeFile(image);
    } catch (_) {
      if (!mounted) return;
      setState(() => _scanError = 'invalid_image');
    }
  }

  Future<void> _openAppSettings() async {
    final uri = Platform.isAndroid
        ? Uri.parse('package:com.example.cekgizi')
        : Uri.parse('app-settings:');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await Clipboard.setData(
        const ClipboardData(
          text: 'Buka Pengaturan Aplikasi CekGizi lalu izinkan kamera.',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final controller = _controller;
    final cameraReady =
        controller != null && controller.value.isInitialized && !_initializing;
    final cameraError = _cameraError;

    return Scaffold(
      // Latar gelap: ikon/teks kita berwarna terang - tetap terbaca
      // walau preview kamera sedang memuat atau gagal ditampilkan.
      backgroundColor: colors.textPrimary,
      body: SafeArea(
        child: cameraError != null && !cameraReady
            ? _CameraFallback(
                kind: cameraError,
                onRetry: _initCamera,
                onOpenSettings: _openAppSettings,
                onManual: _openManualEntry,
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (cameraReady)
                    _FullScreenCamera(controller: controller)
                  else
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Menyiapkan kamera…',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (cameraReady) ...[
                    const _PlateOverlay(),
                    _TopBar(
                      onClose: () => context.pop(),
                      onManual: _openManualEntry,
                    ),
                    _BottomBar(
                      onGallery: _pickFromGallery,
                      onShutter: _shutter,
                      busy: _busy,
                    ),
                  ],
                  if (_busy) const _AnalyzingOverlay(),
                  if (_scanError != null)
                    _ScanErrorPanel(
                      code: _scanError!,
                      onCloseError: () => setState(() => _scanError = null),
                      onRetry: _initCamera,
                      onManual: _openManualEntry,
                    ),
                ],
              ),
      ),
    );
  }
}

class _FullScreenCamera extends StatelessWidget {
  const _FullScreenCamera({required this.controller});

  final CameraController controller;

  /// Rasio tampilan preview (lebar/tinggi) untuk orientasi layar saat ini.
  ///
  /// Rumusnya identik dengan yang dipakai [CameraPreview] di internalnya,
  /// sehingga hasilnya selalu konsisten dengan yang diinginkan plugin.
  double get _displayRatio {
    final aspectRatio = controller.value.aspectRatio;
    if (!aspectRatio.isFinite || aspectRatio <= 0) return 0;

    final orientation =
        controller.value.previewPauseOrientation ??
        controller.value.lockedCaptureOrientation ??
        controller.value.deviceOrientation;
    final isLandscape =
        orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;
    final ratio = isLandscape ? aspectRatio : 1 / aspectRatio;
    return ratio.isFinite && ratio > 0 ? ratio : 0;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _displayRatio;
    if (ratio <= 0) {
      // Rasio belum siap - tampilkan preview apa adanya tanpa scaling.
      return CameraPreview(controller);
    }

    // `FittedBox` memberi constraint tak-terhingga ke anaknya, sehingga
    // memakai `AspectRatio` di sini membuat `RenderAspectRatio` melempar
    // "has unbounded constraints" dan seluruh frame gagal dirender (layar
    // kosong). `SizedBox` menentukan ukurannya sendiri sehingga aman, dan
    // `FittedBox.cover` tetap mengisi layar tanpa distorsi.
    // Angka 1000 hanyalah basis perhitungan rasio, bukan ukuran layar.
    final width = ratio >= 1 ? 1000.0 : 1000.0 * ratio;
    final height = ratio >= 1 ? 1000.0 / ratio : 1000.0;

    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: width,
        height: height,
        child: CameraPreview(controller),
      ),
    );
  }
}

class _PlateOverlay extends StatelessWidget {
  const _PlateOverlay();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 280,
          height: 280,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.onPrimary.withValues(alpha: 0.85),
              width: 3,
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, required this.onManual});

  final VoidCallback onClose;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: AppStrings.scanClose,
            child: IconButton(
              tooltip: AppStrings.scanClose,
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, color: colors.onPrimary),
            ),
          ),
          Expanded(
            child: Text(
              AppStrings.scanTitle,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('scan-topbar-manual'),
            onPressed: onManual,
            child: Text(
              AppStrings.scanManualButton,
              style: textTheme.labelLarge?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.onGallery,
    required this.onShutter,
    required this.busy,
  });

  final VoidCallback onGallery;
  final VoidCallback onShutter;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.scanHint,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Semantics(
                  button: true,
                  label: AppStrings.scanGallery,
                  child: IconButton.filledTonal(
                    tooltip: AppStrings.scanGallery,
                    onPressed: busy ? null : onGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                ),
                Semantics(
                  button: true,
                  label: AppStrings.scanShutterSemantics,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: busy ? null : onShutter,
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.onPrimary,
                          width: 4,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyzingOverlay extends StatelessWidget {
  const _AnalyzingOverlay();

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Positioned.fill(
      child: Container(
        color: colors.textPrimary.withValues(alpha: 0.4),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.scanAnalyzing,
                style: textTheme.bodyLarge?.copyWith(
                  color: colors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanErrorPanel extends StatelessWidget {
  const _ScanErrorPanel({
    required this.code,
    required this.onCloseError,
    required this.onRetry,
    required this.onManual,
  });

  final String code;
  final VoidCallback onCloseError;
  final Future<void> Function() onRetry;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final (icon, title) = switch (code) {
      'no_food' => (Icons.photo_camera_outlined, AppStrings.scanNoFoodTitle),
      'quota_daily' => (Icons.hourglass_empty_rounded, AppStrings.scanQuotaTitle),
      'offline' => (Icons.wifi_off_rounded, AppStrings.scanOfflineTitle),
      'timeout' || 'ai_unavailable' =>
        (Icons.cloud_off_rounded, AppStrings.scanBusyTitle),
      _ => (Icons.cloud_off_rounded, AppStrings.scanBusyTitle),
    };

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: AppSurfaces.card(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, color: colors.accent, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: AppStrings.actionClose,
                    onPressed: onCloseError,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.scanSheetError(code),
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: const ValueKey('scan-error-manual'),
                    onPressed: onManual,
                    child: const Text(AppStrings.scanManualButton),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (code != 'quota_daily')
                    FilledButton.icon(
                      onPressed: code == 'no_food'
                          ? onCloseError
                          : () => onRetry(),
                      icon: Icon(
                        code == 'no_food'
                            ? Icons.photo_camera_outlined
                            : Icons.refresh_rounded,
                        size: 18,
                      ),
                      label: Text(
                        code == 'no_food'
                            ? AppStrings.scanPhotoAgain
                            : AppStrings.scanRetry,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CameraFallback extends StatelessWidget {
  const _CameraFallback({
    required this.kind,
    required this.onRetry,
    required this.onOpenSettings,
    required this.onManual,
  });

  final String kind;
  final Future<void> Function() onRetry;
  final VoidCallback onOpenSettings;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final permission = kind == 'permission';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.no_photography_rounded,
                size: 44,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                permission
                    ? AppStrings.scanCameraPermissionTitle
                    : AppStrings.scanCameraUnavailableTitle,
                style: textTheme.titleLarge?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              permission
                  ? AppStrings.scanCameraPermissionBody
                  : AppStrings.scanCameraUnavailableBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (permission)
              FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_rounded),
                label: const Text(AppStrings.scanOpenSettings),
              ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: onRetry,
                  child: const Text(AppStrings.scanRetry),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  key: const ValueKey('scan-fallback-manual'),
                  onPressed: onManual,
                  child: const Text(AppStrings.scanManualButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
