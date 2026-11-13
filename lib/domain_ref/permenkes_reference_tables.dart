import 'dart:convert';

import 'package:cekgizi/core/errors/domain_exceptions.dart';
import 'package:cekgizi/features/growth/domain/entities/sd_columns.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/features/growth/domain/repositories/anthropometry_reference_tables.dart';

/// Tabel referensi Permenkes 2/2020 yang diekstrak dari PDF resmi
/// (`assets/reference/permenkes_2_2020_sd.json`) - menjalankan validasi saat
/// parse (jumlah baris, kontinuitas kunci, monotonicity). Jika berkas rusak,
/// lempar [InvalidReferenceDataException], jangan diam-diam lanjut.
///
/// Semua nilai bersumber dari lampiran resmi; kolom −3/−2/+2/+3 boleh null
/// (satu sel di sumber cacat; rujukan saja, bukan input rumus z).
final class PermenkesReferenceTables implements AnthropometryReferenceTables {
  PermenkesReferenceTables._(
    this.version,
    this._haz,
    this._waz,
    this._whz,
  );

  /// Versi referensi yang tertanam di AppConfig.permenkesRefVersion.
  final String version;

  // haz: per sex {pb_u: rows(index = bulan), tb_u: rows(index = bulan − 24)}
  final Map<String, Map<String, List<SdColumns>>> _haz;

  // waz: per sex, index = bulan (0–60)
  final Map<String, List<SdColumns>> _waz;

  // whz: per sex {pb/tb: (start, step, rows(index = (cm − start) / step))}
  final Map<String, Map<String, _WhzTable>> _whz;

  factory PermenkesReferenceTables.fromJsonString(String contents) {
    final decoded = jsonDecode(contents) as Map<String, dynamic>;
    return PermenkesReferenceTables.fromJson(decoded);
  }

  factory PermenkesReferenceTables.fromJson(Map<String, dynamic> json) {
    final tables = json['tables'] as Map<String, dynamic>;
    final version = json['version'] as String?;
    if (version == null || version.isEmpty) {
      throw const InvalidReferenceDataException(
        'Berkas referensi tidak memiliki "version".',
      );
    }

    final haz = <String, Map<String, List<SdColumns>>>{};
    final waz = <String, List<SdColumns>>{};
    final whz = <String, Map<String, _WhzTable>>{};

    for (final sex in ['male', 'female']) {
      haz[sex] = {
        'pb_u': _parseRowList(
          tables['haz'][sex]['pb_u'] as List<dynamic>,
          expectedLength: 25,
          label: 'haz.$sex.pb_u',
        ),
        'tb_u': _parseRowList(
          tables['haz'][sex]['tb_u'] as List<dynamic>,
          expectedLength: 37,
          label: 'haz.$sex.tb_u',
        ),
      };
      waz[sex] = _parseRowList(
        tables['waz'][sex] as List<dynamic>,
        expectedLength: 61,
        label: 'waz.$sex',
      );
      whz[sex] = {
        'pb': _parseWhzTable(
          tables['whz'][sex]['pb'] as Map<String, dynamic>,
          label: 'whz.$sex.pb',
        ),
        'tb': _parseWhzTable(
          tables['whz'][sex]['tb'] as Map<String, dynamic>,
          label: 'whz.$sex.tb',
        ),
      };
    }

    return PermenkesReferenceTables._(version, haz, waz, whz);
  }

  static List<SdColumns> _parseRowList(
    List<dynamic> rows, {
    required int expectedLength,
    required String label,
  }) {
    if (rows.length != expectedLength) {
      throw InvalidReferenceDataException(
        '$label: jumlah baris ${rows.length}, seharusnya $expectedLength.',
      );
    }
    return [
      for (final row in rows) _parseRow(row as List<dynamic>, label),
    ]..forEach(_assertMonotonic);
  }

  static _WhzTable _parseWhzTable(
    Map<String, dynamic> json, {
    required String label,
  }) {
    final start = (json['start'] as num).toDouble();
    final step = (json['step'] as num).toDouble();
    final rows = (json['rows'] as List<dynamic>)
        .map((row) => _parseRow(row as List<dynamic>, label))
        .toList();
    if (rows.length < 2) {
      throw InvalidReferenceDataException('$label: jumlah baris tidak wajar.');
    }
    rows.forEach(_assertMonotonic);
    return _WhzTable(start: start, step: step, rows: rows);
  }

  static SdColumns _parseRow(List<dynamic> row, String label) {
    if (row.length != 7) {
      throw InvalidReferenceDataException(
        '$label: baris memiliki ${row.length} kolom, seharusnya 7.',
      );
    }
    final cells = [
      for (final cell in row)
        if (cell == null) null else (cell as num).toDouble(),
    ];
    final sdNeg3 = cells[0];
    final sdNeg2 = cells[1];
    final sdNeg1 = cells[2];
    final median = cells[3];
    final sdPos1 = cells[4];
    final sdPos2 = cells[5];
    final sdPos3 = cells[6];

    // Kolom wajib untuk rumus z (PRD §3.3): −1, median, +1.
    if (sdNeg1 == null || median == null || sdPos1 == null) {
      throw InvalidReferenceDataException(
        '$label: kolom wajib (−1 SD, median, +1 SD) tidak boleh null.',
      );
    }
    return SdColumns(
      sdNeg3: sdNeg3,
      sdNeg2: sdNeg2,
      sdNeg1: sdNeg1,
      median: median,
      sdPos1: sdPos1,
      sdPos2: sdPos2,
      sdPos3: sdPos3,
    );
  }

  static void _assertMonotonic(SdColumns sd) {
    final seq = [sd.sdNeg3, sd.sdNeg2, sd.sdNeg1, sd.median, sd.sdPos1, sd.sdPos2, sd.sdPos3];
    for (var i = 0; i < seq.length - 1; i++) {
      final a = seq[i];
      final b = seq[i + 1];
      if (a == null || b == null) continue; // sel cacat di sumber (rujukan)
      if (!(a < b)) {
        throw const InvalidReferenceDataException(
          'Kolom SD tidak monoton naik pada satu baris tabel.',
        );
      }
    }
    if (sd.median <= sd.sdNeg1 || sd.sdPos1 <= sd.median) {
      throw const InvalidReferenceDataException(
        'Tabel SD tidak valid: median harus di atas SD(−1) dan di bawah SD(+1).',
      );
    }
  }

  String _sexKey(Sex sex) => sex == Sex.male ? 'male' : 'female';

  /// Informasi rentang tabel WHZ (start, step, jumlah baris) - untuk grafik.
  @override
  ({double start, double step, int length}) whzTableInfo({
    required Sex sex,
    required int ageMonths,
  }) {
    final table = _whz[_sexKey(sex)]![ageMonths < 24 ? 'pb' : 'tb']!;
    return (start: table.start, step: table.step, length: table.rows.length);
  }

  @override
  SdColumns haz({required Sex sex, required int ageMonths}) {
    if (ageMonths < 0 || ageMonths > 60) {
      throw OutOfSupportedRangeException(
        'Usia $ageMonths bulan di luar rentang tabel (0–60).',
      );
    }
    final tables = _haz[_sexKey(sex)]!;
    if (ageMonths < 24) {
      return tables['pb_u']![ageMonths];
    }
    return tables['tb_u']![ageMonths - 24];
  }

  @override
  SdColumns waz({required Sex sex, required int ageMonths}) {
    if (ageMonths < 0 || ageMonths > 60) {
      throw OutOfSupportedRangeException(
        'Usia $ageMonths bulan di luar rentang tabel (0–60).',
      );
    }
    return _waz[_sexKey(sex)]![ageMonths];
  }

  @override
  SdColumns whz({
    required Sex sex,
    required double lengthHeightCmStep,
    required int ageMonths,
  }) {
    final table = _whz[_sexKey(sex)]![ageMonths < 24 ? 'pb' : 'tb']!;
    final index = ((lengthHeightCmStep - table.start) / table.step).round();
    if (index < 0 || index >= table.rows.length) {
      throw OutOfSupportedRangeException(
        'Panjang/tinggi $lengthHeightCmStep cm di luar cakupan tabel '
        '(${table.start}–${table.start + table.step * (table.rows.length - 1)} cm).',
      );
    }
    return table.rows[index];
  }
}

final class _WhzTable {
  const _WhzTable({
    required this.start,
    required this.step,
    required this.rows,
  });

  final double start;
  final double step;
  final List<SdColumns> rows;
}
