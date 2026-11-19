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
import 'package:cekgizi/shared/illustrations/onboarding_guidance_illustration.dart';
import 'package:cekgizi/shared/illustrations/onboarding_growth_illustration.dart';
import 'package:cekgizi/shared/illustrations/plate_viewfinder_illustration.dart';
import 'package:cekgizi/shared/widgets/app_logo_mark.dart';
import 'package:cekgizi/shared/widgets/section_reveal.dart';

/// Onboarding 3 layar (PRD §6.1). Setelah "Mulai", flag onboarding tersimpan
/// lokal (offline-safe) dan lanjut ke consent.
///
/// Satu layar = satu cerita: panel ilustrasi penuh di atas, teks editorial
/// rata kiri, lalu progress dan aksi utama yang selalu di jangkauan jempol.
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
      <({String eyebrow, String title, String body})>[
        (
          eyebrow: AppStrings.onboardingEyebrow1,
          title: AppStrings.onboardingTitle1,
          body: AppStrings.onboardingBody1,
        ),
        (
          eyebrow: AppStrings.onboardingEyebrow2,
          title: AppStrings.onboardingTitle2,
          body: AppStrings.onboardingBody2,
        ),
        (
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
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: _OnboardingTopBar(onSkip: _finish),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (context, index) => _Slide(
                    slide: _slides[index],
                    index: index,
                  ),
                ),
              ),
              _OnboardingFooter(
                page: _page,
                total: _slides.length,
                isLast: _isLast,
                onNext: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingTopBar extends StatelessWidget {
  const _OnboardingTopBar({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const AppLogoMark(size: 40),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              AppConfig.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: colors.textSecondary,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            child: const Text(AppStrings.onboardingSkip),
          ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.slide, required this.index});

  final ({String eyebrow, String title, String body}) slide;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final stageHeight = (constraints.maxHeight * 0.50).clamp(160.0, 320.0);
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IllustrationStage(height: stageHeight, index: index),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.xxl,
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                  ),
                  child: SectionReveal(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _EyebrowPill(text: slide.eyebrow),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            slide.title,
                            style: AppTextStyles.titleLarge.copyWith(
                              fontSize: 26,
                              height: 1.25,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            slide.body,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 15,
                              height: 1.5,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _IllustrationStage extends StatelessWidget {
  const _IllustrationStage({required this.height, required this.index});

  final double height;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final illustrationSize = (height * 0.82).clamp(110.0, 230.0);
    final illustration = switch (index) {
      0 => PlateViewfinderIllustration(size: illustrationSize),
      1 => OnboardingGrowthIllustration(size: illustrationSize),
      _ => OnboardingGuidanceIllustration(size: illustrationSize),
    };

    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.card),
        ),
        child: Container(
          height: height,
          width: double.infinity,
          color: colors.surfaceVariant,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            alignment: Alignment.center,
            children: [
              Positioned(
                left: -height * 0.34,
                top: -height * 0.34,
                child: _DecorativeRing(
                  size: height * 0.94,
                  color: colors.outline,
                ),
              ),
              Positioned(
                right: -height * 0.16,
                bottom: -height * 0.20,
                child: _DecorativeRing(
                  size: height * 0.62,
                  color: colors.primaryContainer,
                ),
              ),
              Positioned(
                right: height * 0.12,
                top: height * 0.12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              illustration,
            ],
          ),
        ),
      ),
    );
  }
}

class _DecorativeRing extends StatelessWidget {
  const _DecorativeRing({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
    );
  }
}

class _EyebrowPill extends StatelessWidget {
  const _EyebrowPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: AppTextStyles.label.copyWith(
          color: colors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({
    required this.page,
    required this.total,
    required this.isLast,
    required this.onNext,
  });

  final int page;
  final int total;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.lg,
          AppSpacing.screenPadding,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: AppStrings.onboardingPageSemantics(page + 1, total),
                    child: ExcludeSemantics(
                      child: Row(
                        key: const Key('onboarding-progress'),
                        children: [
                          for (var index = 0; index < total; index++)
                            Expanded(
                              child: AnimatedContainer(
                                duration: reduceMotion
                                    ? Duration.zero
                                    : AppMotion.fast,
                                curve: AppMotion.easeOutCubic,
                                height: 4,
                                margin: EdgeInsets.only(
                                  right: index == total - 1
                                      ? 0
                                      : AppSpacing.xs + 2,
                                ),
                                decoration: BoxDecoration(
                                  color: index <= page
                                      ? colors.primary
                                      : colors.outline,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  AppStrings.onboardingStep(page + 1, total),
                  style: AppTextStyles.label.copyWith(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('onboarding-cta'),
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLast
                          ? AppStrings.onboardingStart
                          : AppStrings.onboardingNext,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      isLast
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.disclaimer,
              textAlign: TextAlign.center,
              style: AppTextStyles.label.copyWith(
                color: colors.textSecondary,
                fontSize: 11,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
