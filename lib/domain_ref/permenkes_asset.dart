import 'package:flutter/services.dart';

import 'permenkes_reference_tables.dart';

/// Memuat tabel SD Permenkes 2/2020 dari asset (file terverifikasi).
Future<PermenkesReferenceTables> loadPermenkesTables() async {
  final json =
      await rootBundle.loadString('assets/reference/permenkes_2_2020_sd.json');
  return PermenkesReferenceTables.fromJsonString(json);
}
