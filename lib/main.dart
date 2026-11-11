import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/router.dart';
import 'core/storage/local_prefs.dart';
import 'features/auth/auth_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await LocalPrefs.load();
  await bootstrapBackend();
  runApp(
    ProviderScope(
      overrides: [
        localPrefsProvider.overrideWithValue(prefs),
      ],
      child: const CekGiziApp(),
    ),
  );
}
