/// Jenis kelamin anak. Serialisasi DB memakai 'male'/'female' (PRD §5.2).
enum Sex {
  male('male'),
  female('female');

  const Sex(this.dbValue);

  final String dbValue;

  static Sex fromDbValue(String value) => switch (value) {
    'male' => Sex.male,
    'female' => Sex.female,
    _ => throw ArgumentError.value(value, 'sex', 'Nilai jenis kelamin tidak dikenal'),
  };
}
