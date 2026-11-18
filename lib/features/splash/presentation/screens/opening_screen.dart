import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'package:cekgizi/core/bootstrap/backend_ready_provider.dart';
import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';

/// Satu-satunya layar pra-aplikasi: Lottie CekGizi sebagai page loading.
///
/// Alur: native splash (solid #145C45) → Lottie (satu page) → aplikasi.
/// Backend berjalan di latar; layar ini menampilkan animasi selagi backend
/// disiapkan. Bila Lottie selesai lebih dulu, layar menahan frame terakhir
/// dengan progres halus sampai backend siap; bila backend selesai lebih dulu,
/// aplikasi langsung masuk begitu animasi kelar.
///
/// Lottie diubah ke **0,65× speed** (bukan 0,5× = terlalu pelan, bukan 1,0× =
/// sedang tayang terlalu cepat). Reduce-motion dihormati, dan ada batas keras
/// [_fallbackDelay] agar aplikasi tidak pernah berhenti di sini.
class OpeningScreen extends ConsumerStatefulWidget {
  const OpeningScreen({super.key, required this.nextLocation});

  final String nextLocation;

  @override
  ConsumerState<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends ConsumerState<OpeningScreen>
    with SingleTickerProviderStateMixin {
  /// Kecepatan animasi 0,65× (frame asli 60fps → terasa lebih tenang).
  static const double _speed = 0.65;

  /// Batas keras total; lebih longgar dari durasi backend terburuk
  /// (lihat `startup_guard.dart`) supaya tidak pernah macet.
  static const Duration _fallbackDelay = Duration(seconds: 20);

  late final AnimationController _controller;
  bool _animationDone = false;
  bool _backendDone = false;
  bool _navigated = false;
  Timer? _fallback;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    ref
        .read(backendReadyProvider)
        .then((_) => _noteBackendDone())
        .catchError((_) => _noteBackendDone());
    // Tunggu frame pertama agar MediaQuery & GoRouter siap.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startOpening());
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startOpening() {
    if (!mounted) return;
    _fallback = Timer(_fallbackDelay, _finishAnyway);

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _animationDone = true;
      _maybeGo();
      return;
    }
    // Durasi belum diketahui sampai onLoaded; forward dipanggil dari sana.
  }

  void _noteBackendDone() {
    if (!mounted) return;
    _backendDone = true;
    _maybeGo();
  }

  void _maybeGo() {
    if (_navigated || !_animationDone || !_backendDone) return;
    _goNext();
  }

  void _finishAnyway() {
    if (_navigated || !mounted) return;
    _goNext();
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _fallback?.cancel();
    _fallback = null;
    context.go(widget.nextLocation);
  }

  Duration _scaled(Duration original) =>
      Duration(milliseconds: (original.inMilliseconds / _speed).round());

  Future<void> _play() async {
    try {
      await _controller.forward();
    } catch (_) {
      // Ticker bisa dibatalkan sistem (app masuk latar) - diabaikan.
    }
    if (!mounted) return;
    _animationDone = true;
    _maybeGo();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final waitingForBackend = _animationDone && !_backendDone;

    return Scaffold(
      backgroundColor: AppSurfaces.splashSurface,
      body: Semantics(
        label: waitingForBackend
            ? '${AppConfig.appName} — ${AppStrings.startupLoading}'
            : AppConfig.appName,
        liveRegion: true,
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Logo eksplisit berukuran square, terpusat di kedua sumbu.
              final shortSide = math.min(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final size = (shortSide * 0.66).clamp(208.0, 300.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: size,
                    height: size,
                    child: Lottie.asset(
                      'assets/animations/cekgizi_opening.json',
                      controller: _controller,
                      repeat: false,
                      fit: BoxFit.contain,
                      onLoaded: (composition) {
                        if (!mounted || _navigated) return;
                        _controller.duration = _scaled(composition.duration);
                        if (reduceMotion) {
                          _controller.value = 1;
                          _animationDone = true;
                          _maybeGo();
                        } else {
                          unawaited(_play());
                        }
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const _Wordmark(),
                    ),
                  ),
                  if (waitingForBackend) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppSurfaces.onSplashSurfaceMuted,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Fallback statis: hanya tampil bila aset Lottie gagal dimuat.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppConfig.appName,
        textAlign: TextAlign.center,
        style: AppTextStyles.titleLarge.copyWith(
          color: AppSurfaces.onSplashSurface,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
