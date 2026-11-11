/// Cara ukur panjang/tinggi (PRD §3.2). Serialisasi DB memakai
/// 'lying'/'standing' (PRD §5.2).
enum MeasureMode {
  lying('lying'),
  standing('standing');

  const MeasureMode(this.dbValue);

  final String dbValue;

  static MeasureMode fromDbValue(String value) => switch (value) {
    'lying' => MeasureMode.lying,
    'standing' => MeasureMode.standing,
    _ => throw ArgumentError.value(
        value, 'measure_mode', 'Cara ukur tidak dikenal'),
  };
}
