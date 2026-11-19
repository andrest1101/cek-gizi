import 'package:flutter/material.dart';

import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/shared/illustrations/chat_illustration.dart';

/// Ilustrasi "pendamping, bukan dokter" untuk onboarding.
///
/// Gelembung tanya (edukasi) dengan lencana perisai (keamanan). Murni token
/// tema dan dekoratif; judul di sebelahnya yang membawa makna.
class OnboardingGuidanceIllustration extends StatelessWidget {
  const OnboardingGuidanceIllustration({super.key, this.size = 180});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final badge = size * 0.30;
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ChatIllustration(size: size * 0.84),
            Positioned(
              right: size * 0.02,
              bottom: size * 0.02,
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors.surfaceVariant,
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  size: badge * 0.54,
                  color: colors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
