import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cekgizi/core/storage/local_prefs.dart';
import 'package:cekgizi/core/theme/app_spacing.dart';
import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/children/presentation/providers/children_providers.dart';
import 'package:cekgizi/features/children/presentation/screens/child_form_screen.dart';
import 'package:cekgizi/features/children/presentation/screens/children_screen.dart';
import 'package:cekgizi/features/consent/presentation/screens/consent_screen.dart';
import 'package:cekgizi/features/growth/presentation/screens/growth_screen.dart';
import 'package:cekgizi/features/home/presentation/app_shell.dart';
import 'package:cekgizi/features/home/presentation/home_screen.dart';
import 'package:cekgizi/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:cekgizi/shared/widgets/error_card.dart';

/// Dikonfigurasi di `main()`; tes melakukan override dengan prefs dari
/// SharedPreferences mock.
final localPrefsProvider = Provider<LocalPrefs>(
  (ref) => throw UnimplementedError('Override localPrefsProvider di main().'),
);

final routerProvider = Provider<GoRouter>((ref) {
  final prefs = ref.watch(localPrefsProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final location = state.matchedLocation;
      if (!prefs.isOnboardingCompleted && location != '/onboarding') {
        return '/onboarding';
      }
      if (prefs.isOnboardingCompleted &&
          !prefs.isConsentAccepted &&
          location != '/consent') {
        return '/consent';
      }
      if (prefs.isOnboardingCompleted &&
          prefs.isConsentAccepted &&
          (location == '/onboarding' || location == '/consent')) {
        return '/';
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: ErrorCard(
            message: 'Alamat "${state.uri}" tidak ada. Kembali ke Beranda.',
            onRetry: () => context.go('/'),
          ),
        ),
      ),
    ),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/growth',
                name: '/growth',
                builder: (context, state) => const GrowthScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        name: '/onboarding',
        builder: (context, state) => OnboardingScreen(prefs: prefs),
      ),
      GoRoute(
        path: '/consent',
        name: '/consent',
        builder: (context, state) => ConsentScreen(prefs: prefs),
      ),
      GoRoute(
        path: '/children',
        name: '/children',
        builder: (context, state) => const ChildrenScreen(),
      ),
      GoRoute(
        path: '/children/add',
        name: '/children/add',
        builder: (context, state) => const ChildFormScreen(),
      ),
      GoRoute(
        path: '/children/:id/edit',
        name: '/children/:id/edit',
        builder: (context, state) =>
            _EditChildRoute(childId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Tunggu daftar anak dimuat, lalu arahkan ke formulir edit.
class _EditChildRoute extends ConsumerWidget {
  const _EditChildRoute({required this.childId});

  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final childrenAsync = ref.watch(childrenListProvider);
    return childrenAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(title: const Text('Anak saya')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: ErrorCard(
              message: 'Gagal memuat data anak. Periksa koneksi kamu.',
              onRetry: () => ref.invalidate(childrenListProvider),
            ),
          ),
        ),
      ),
      data: (children) {
        final child = children.where((c) => c.id == childId).firstOrNull;
        if (child == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Anak saya')),
            body: Center(
              child: Text(
                'Anak tidak ditemukan.',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          );
        }
        return ChildFormScreen(existing: child);
      },
    );
  }
}
