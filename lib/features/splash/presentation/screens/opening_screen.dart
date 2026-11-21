import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/theme/app_surfaces.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';

/// Satu-satunya layar pra-aplikasi: Lottie CekGizi sebagai page loading.
///
/// Alur: splash sistem Android (solid #145C45, tanpa ikon) → Lottie (satu
/// page) → onboarding/consent/beranda. Backend tetap disiapkan di latar oleh
/// `main()`, tetapi TIDAK menghalangi perpindahan layar: begitu animasi selesai
/// aplikasi langsung lanjut. Ini membuat startup ±3 detik, bukan 13 detik.
///
/// Reduce-motion dihormati (langsung lanjut, tanpa suara), dan ada batas keras
/// [_fallbackDelay] agar aplikasi tidak pernah berhenti di sini.
class OpeningScreen extends ConsumerStatefulWidget {
  const OpeningScreen({super.key, required this.nextLocation});

  final String nextLocation;

  @override
  ConsumerState<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends ConsumerState<OpeningScreen>
    with SingleTickerProviderStateMixin {
  /// Kecepatan asli 1×: durasi Lottie 3 detik (180 frame @60fps).
  static const double _speed = 1.0;

  /// Laju suara mengikuti animasi 1× (audio diproduksi untuk 0,65×).
  static const double _soundRate = 1.5;

  /// Batas keras: cukup untuk animasi 3 dtk + margin muat aset.
  static const Duration _fallbackDelay = Duration(seconds: 6);

  late final AnimationController _controller;
  AudioPlayer? _player;
  bool _navigated = false;
  Timer? _fallback;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    // Tunggu frame pertama agar MediaQuery & GoRouter siap.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startOpening());
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _controller.dispose();
    unawaited(_disposePlayer());
    super.dispose();
  }

  Future<void> _disposePlayer() async {
    final player = _player;
    _player = null;
    try {
      await player?.dispose();
    } catch (_) {
      // abaikan - pemain audio gagal dilepas bukan alasan app crash
    }
  }

  void _startOpening() {
    if (!mounted) return;
    _fallback = Timer(_fallbackDelay, _finishAnyway);

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _goNext();
    }
    // Durasi belum diketahui sampai onLoaded; forward dipanggil dari sana.
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
    _goNext();
  }

  /// Suara khas logo — diputar bersamaan dengan animasi Lottie.
  /// Reduce-motion tidak memutar suara; kegagalan audio diabaikan (bisu).
  Future<void> _playLogoSound(bool reduceMotion) async {
    if (reduceMotion) return;
    try {
      final player = AudioPlayer();
      _player = player;
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(0.35);
      await player.setPlaybackRate(_soundRate);
      await player.play(AssetSource('audio/cek-gizi_audio.wav'));
    } catch (_) {
      // bisu - splash tetap berjalan
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: AppSurfaces.splashSurface,
      body: Semantics(
        label: AppConfig.appName,
        liveRegion: true,
        child: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Logo eksplisit berukuran square, terpusat di kedua sumbu.
              final shortSide = math.min(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final size = (shortSide * 0.80).clamp(220.0, 330.0);
              return SizedBox(
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
                      _goNext();
                    } else {
                      unawaited(_playLogoSound(reduceMotion));
                      unawaited(_play());
                    }
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      const _Wordmark(),
                ),
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
