import 'package:flutter/material.dart';

import 'app.dart';
import 'features/auth/auth_bootstrap.dart';

Future<void> main() async {
  await bootstrapBackend();
  runApp(const CekGiziApp());
}
