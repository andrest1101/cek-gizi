import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';

/// Lightweight branded opening shown after app initialization.
///
/// Backend and preferences are initialized before Flutter mounts (dengan
/// batas waktu), so this screen is intentionally a short transition rather
/// than a network loader. Ada pengaman: bila animasi tidak pernah selesai
/// (mis. ticker dijeda oleh sistem), layar tetap melanjutkan setelah
/// [_fallbackDelay] agar aplikasi tidak pernah berhenti di logo.
class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key, required this.nextLocation});

  final String nextLocation;

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _animationDuration = Duration(milliseconds: 1250);

  /// Batas keras sebelum dipaksa lanjut. Lebih longgar dari durasi animasi
  /// supaya tidak memotong gerak normal, tetapi tetap jauh di bawah ambang
  /// "terasa macet".
  static const Duration _fallbackDelay = Duration(milliseconds: 1900);

  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleOffset;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineOffset;
  bool _openingStarted = false;
  bool _navigated = false;
  Timer? _fallback;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _animationDuration);
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.42, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.62, curve: Curves.easeOutCubic),
      ),
    );
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.36, 0.72, curve: Curves.easeOut),
    );
    _titleOffset = Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.36, 0.78, curve: Curves.easeOutCubic),
          ),
        );
    _taglineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 0.96, curve: Curves.easeOut),
    );
    _taglineOffset =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.62, 1, curve: Curves.easeOutCubic),
          ),
        );
    // Tunggu frame pertama dulu: MediaQuery & GoRouter siap dipakai, dan
    // pengguna melihat logo seketika.
    WidgetsBinding.instance.addPostFrameCallback((_) => _startOpening());
  }

  void _startOpening() {
    if (!mounted || _openingStarted) return;
    _openingStarted = true;
    _fallback = Timer(_fallbackDelay, _goNext);

    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _goNext();
      return;
    }
    unawaited(_playAnimation());
  }

  /// `forward()` bisa berakhir dengan `TickerCanceled` bila layar dilepas
  /// sebelum animasi selesai - itu bukan galat yang perlu ditampilkan.
  Future<void> _playAnimation() async {
    try {
      await _controller.forward();
    } catch (_) {
      // Diabaikan: pengaman [_fallback] / dispose yang menangani.
    }
    _goNext();
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    _navigated = true;
    _fallback?.cancel();
    _fallback = null;
    context.go(widget.nextLocation);
  }

  @override
  void dispose() {
    _fallback?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final logo = Image.asset(
      'assets/logo/logo_splash_screen.png',
      width: 176,
      height: 176,
      // Batasi bitmap yang di-decode: aset 176dp tidak perlu resolusi penuh.
      cacheWidth: 352,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: '${AppConfig.appName} — logo',
    );

    final title = Text(
      AppConfig.appName,
      textAlign: TextAlign.center,
      style: AppTextStyles.titleLarge.copyWith(
        fontSize: 29,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        color: colors.textPrimary,
      ),
    );

    final tagline = Text(
      AppStrings.openingTagline,
      textAlign: TextAlign.center,
      style: AppTextStyles.bodySmall.copyWith(
        fontSize: 14,
        height: 1.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        color: colors.textSecondary,
      ),
    );

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
            ),
            child: Semantics(
              label: AppConfig.appName,
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (reduceMotion)
                    logo
                  else
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(scale: _logoScale, child: logo),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  if (reduceMotion)
                    title
                  else
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: SlideTransition(
                        position: _titleOffset,
                        child: _StaggeredWord(
                          word: AppConfig.appName,
                          controller: _controller,
                          style: title.style!,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  if (reduceMotion)
                    tagline
                  else
                    FadeTransition(
                      opacity: _taglineOpacity,
                      child: SlideTransition(
                        position: _taglineOffset,
                        child: tagline,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reveals the brand name character by character with a short, tightly spaced
/// stagger so it reads as one intentional title rather than a typewriter.
class _StaggeredWord extends StatelessWidget {
  const _StaggeredWord({
    required this.word,
    required this.controller,
    required this.style,
  });

  final String word;
  final AnimationController controller;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final characters = word.characters.toList(growable: false);
    return Semantics(
      label: word,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < characters.length; index++)
              _StaggeredCharacter(
                character: characters[index],
                index: index,
                count: characters.length,
                controller: controller,
                style: style,
              ),
          ],
        ),
      ),
    );
  }
}

class _StaggeredCharacter extends StatelessWidget {
  const _StaggeredCharacter({
    required this.character,
    required this.index,
    required this.count,
    required this.controller,
    required this.style,
  });

  final String character;
  final int index;
  final int count;
  final AnimationController controller;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final start = 0.40 + (index / count) * 0.20;
    final end = (start + 0.22).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.18),
          end: Offset.zero,
        ).animate(animation),
        child: Text(character, style: style),
      ),
    );
  }
}
