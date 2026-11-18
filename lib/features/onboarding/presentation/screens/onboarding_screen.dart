import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/core/theme/app_motion.dart';
import 'package:cekgizi/core/theme/app_radius.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_text_styles.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/shared/widgets/tonal_icon_circle.dart';

/// Onboarding 3 layar (PRD §6.1). Setelah "Mulai", flag onboarding tersimpan
/// lokal (offline-safe) dan lanjut ke consent.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.prefs});

  final LocalPrefs prefs;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides =
      <({IconData icon, String eyebrow, String title, String body})>[
        (
          icon: Icons.photo_camera_rounded,
          eyebrow: AppStrings.onboardingEyebrow1,
          title: AppStrings.onboardingTitle1,
          body: AppStrings.onboardingBody1,
        ),
        (
          icon: Icons.show_chart_rounded,
          eyebrow: AppStrings.onboardingEyebrow2,
          title: AppStrings.onboardingTitle2,
          body: AppStrings.onboardingBody2,
        ),
        (
          icon: Icons.favorite_rounded,
          eyebrow: AppStrings.onboardingEyebrow3,
          title: AppStrings.onboardingTitle3,
          body: AppStrings.onboardingBody3,
        ),
      ];

  bool get _isLast => _page == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await widget.prefs.setOnboardingCompleted();
    if (!mounted) return;
    context.go('/consent');
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpToPage(_page + 1);
      return;
    }
    _controller.nextPage(
      duration: AppMotion.normal,
      curve: AppMotion.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Icon(
                      Icons.eco_rounded,
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      AppConfig.appName,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: colors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  if (!_isLast)
                    TextButton(
                      onPressed: _finish,
                      child: const Text(AppStrings.onboardingSkip),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => _Slide(slide: _slides[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              child: Row(
                children: [
                  Semantics(
                    label: AppStrings.onboardingPageSemantics(
                      _page + 1,
                      _slides.length,
                    ),
                    child: Row(
                      children: [
                        for (var i = 0; i < _slides.length; i++)
                          AnimatedContainer(
                            duration: reduceMotion
                                ? Duration.zero
                                : AppMotion.fast,
                            curve: AppMotion.easeOutCubic,
                            width: _page == i ? 26 : 7,
                            height: 7,
                            margin: const EdgeInsets.only(right: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: _page == i
                                  ? colors.primary
                                  : colors.outline,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppStrings.onboardingStep(_page + 1, _slides.length),
                    style: AppTextStyles.label.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.xl,
                AppSpacing.screenPadding,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                      _isLast
                          ? AppStrings.onboardingStart
                          : AppStrings.onboardingNext,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppStrings.disclaimer,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.slide});

  final ({IconData icon, String eyebrow, String title, String body}) slide;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
            vertical: AppSpacing.lg,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - AppSpacing.xxl).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _OnboardingIllustration(
                  icon: slide.icon,
                  semantics: slide.title,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  slide.eyebrow,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 25,
                    height: 1.25,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  slide.body,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingIllustration extends StatelessWidget {
  const _OnboardingIllustration({required this.icon, required this.semantics});

  final IconData icon;
  final String semantics;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);

    return Semantics(
      label: semantics,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          width: 208,
          height: 196,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 184,
                height: 184,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outline, width: 1),
                ),
              ),
              Container(
                width: 152,
                height: 152,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.surfaceVariant,
                ),
              ),
              TonalIconCircle(
                icon: icon,
                iconSemantics: semantics,
                size: 104,
                iconSize: 48,
              ),
              Positioned(
                top: 16,
                right: 22,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.accent,
                    border: Border.all(color: colors.background, width: 3),
                  ),
                ),
              ),
              Positioned(
                bottom: 22,
                left: 16,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
