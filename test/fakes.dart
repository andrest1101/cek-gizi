import 'package:cekgizi/domain_ref/nutrition_rules.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/domain/repositories/child_repository.dart';
import 'package:cekgizi/features/growth/domain/entities/growth_measurement.dart';
import 'package:cekgizi/features/growth/domain/entities/measure_mode.dart';
import 'package:cekgizi/features/growth/domain/entities/sd_columns.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/features/growth/domain/repositories/anthropometry_reference_tables.dart';
import 'package:cekgizi/features/growth/domain/repositories/growth_repository.dart';
import 'package:cekgizi/features/meals/domain/entities/food_log.dart';
import 'package:cekgizi/features/meals/domain/repositories/food_log_repository.dart';
import 'package:cekgizi/features/meals/domain/services/dietary_diversity.dart';

/// Fake repositories IN-MEMORY untuk widget test (tanpa jaringan).
final class FakeChildRepository implements ChildRepository {
  FakeChildRepository([List<ChildProfile>? seed])
      : _children = [...?seed];

  final List<ChildProfile> _children;
  int _counter = 1000;

  @override
  Future<List<ChildProfile>> listChildren() async => List.of(_children);

  @override
  Future<ChildProfile> addChild({
    required String nickname,
    required DateTime birthDate,
    required Sex sex,
    required String avatarKey,
  }) async {
    final profile = ChildProfile(
      id: 'fake-child-${_counter++}',
      nickname: nickname,
      birthDate: birthDate,
      sex: sex,
      avatarKey: avatarKey,
    );
    _children.add(profile);
    return profile;
  }

  @override
  Future<ChildProfile> updateChild(ChildProfile child) async {
    final index = _children.indexWhere((c) => c.id == child.id);
    _children[index] = child;
    return child;
  }

  @override
  Future<void> deleteChild(String id) async {
    _children.removeWhere((c) => c.id == id);
  }
}

final class FakeGrowthRepository implements GrowthRepository {
  FakeGrowthRepository([List<GrowthMeasurement>? seed])
      : _measurements = [...?seed];

  final List<GrowthMeasurement> _measurements;
  int _counter = 2000;

  @override
  Future<List<GrowthMeasurement>> listMeasurements(String childId) async =>
      _measurements.where((m) => m.childId == childId).toList();

  @override
  Future<GrowthMeasurement?> findOnDate({
    required String childId,
    required DateTime date,
  }) async {
    for (final m in _measurements) {
      if (m.childId == childId &&
          m.measuredOn.year == date.year &&
          m.measuredOn.month == date.month &&
          m.measuredOn.day == date.day) {
        return m;
      }
    }
    return null;
  }

  @override
  Future<GrowthMeasurement> insert(GrowthMeasurement measurement) async {
    final stored = GrowthMeasurement(
      id: 'fake-measurement-${_counter++}',
      childId: measurement.childId,
      measuredOn: measurement.measuredOn,
      weightKg: measurement.weightKg,
      lengthHeightCm: measurement.lengthHeightCm,
      measureMode: measurement.measureMode,
      ageMonths: measurement.ageMonths,
      haz: measurement.haz,
      waz: measurement.waz,
      whz: measurement.whz,
      statusHaz: measurement.statusHaz,
      statusWaz: measurement.statusWaz,
      statusWhz: measurement.statusWhz,
      refVersion: measurement.refVersion,
      note: measurement.note,
    );
    _measurements.add(stored);
    return stored;
  }

  @override
  Future<GrowthMeasurement> update(GrowthMeasurement measurement) async {
    final index = _measurements.indexWhere((m) => m.id == measurement.id);
    _measurements[index] = measurement;
    return measurement;
  }

  @override
  Future<void> delete(String id) async {
    _measurements.removeWhere((m) => m.id == id);
  }
}

/// Tabel SD deterministik untuk widget test (bukan Permenkes asli).
final class FakeAnthropometryTables implements AnthropometryReferenceTables {
  const FakeAnthropometryTables();

  /// HAZ kisaran tinggi badan (~70s cm).
  static const SdColumns hazFixture = SdColumns(
    sdNeg3: 55,
    sdNeg2: 62,
    sdNeg1: 68,
    median: 75,
    sdPos1: 82,
    sdPos2: 88,
    sdPos3: 94,
  );

  /// WAZ / WHZ kisaran berat badan (~8 kg).
  static const SdColumns wazFixture = SdColumns(
    sdNeg3: 2,
    sdNeg2: 3,
    sdNeg1: 5,
    median: 8,
    sdPos1: 11,
    sdPos2: 13,
    sdPos3: 15,
  );

  @override
  SdColumns haz({required Sex sex, required int ageMonths}) => hazFixture;

  @override
  SdColumns waz({required Sex sex, required int ageMonths}) => wazFixture;

  @override
  SdColumns whz({
    required Sex sex,
    required double lengthHeightCmStep,
    required int ageMonths,
  }) =>
      wazFixture;

  @override
  ({double start, double step, int length}) whzTableInfo({
    required Sex sex,
    required int ageMonths,
  }) =>
      (start: 45.0, step: 0.5, length: 131);
}

GrowthMeasurement fakeMeasurement({
  required String id,
  required String childId,
  DateTime? measuredOn,
  double weightKg = 8.2,
  double lengthHeightCm = 72.0,
  int ageMonths = 11,
  MeasureMode measureMode = MeasureMode.lying,
  String? haz = 'normal',
  String? waz = 'normal',
  String? whz = 'normal',
}) {
  return GrowthMeasurement(
    id: id,
    childId: childId,
    measuredOn: measuredOn ?? DateTime(2026, 10, 18),
    weightKg: weightKg,
    lengthHeightCm: lengthHeightCm,
    measureMode: measureMode,
    ageMonths: ageMonths,
    haz: 0.5,
    waz: 0.3,
    whz: 0.1,
    statusHaz: haz,
    statusWaz: waz,
    statusWhz: whz,
    refVersion: 'permenkes-2-2020',
  );
}

ChildProfile fakeChild({
  String id = 'fake-child-1',
  String nickname = 'Arka',
  Sex sex = Sex.male,
  String avatarKey = 'sprout',
  DateTime? birthDate,
}) {
  return ChildProfile(
    id: id,
    nickname: nickname,
    birthDate: birthDate ?? DateTime(2025, 11, 20),
    sex: sex,
    avatarKey: avatarKey,
  );
}

FoodLog fakeFoodLog({
  String id = 'log-1',
  String childId = 'fake-child-1',
  DateTime? eatenAt,
  MealType mealType = MealType.snack,
  FoodLogSource source = FoodLogSource.manual,
  List<String> groups = const ['grains_tubers'],
  List<FoodLogItem>? items,
}) {
  return FoodLog(
    id: id,
    childId: childId,
    eatenAt: eatenAt ?? DateTime.now(),
    mealType: mealType,
    source: source,
    items: items ??
        [
          for (final group in groups)
            FoodLogItem(name: group, groups: [group]),
        ],
    groups: groups,
  );
}

/// Fake repository catatan makan in-memory (tanpa jaringan).
final class FakeFoodLogRepository implements FoodLogRepository {
  FakeFoodLogRepository([List<FoodLog>? seed]) : _logs = [...?seed];

  final List<FoodLog> _logs;
  int _counter = 1000;

  /// Rentang terakhir yang diminta (untuk menguji batas query).
  DateTime? lastFrom;
  DateTime? lastTo;
  int listCalls = 0;

  int get logCount => _logs.length;

  List<FoodLog> logs(String childId) => [
        for (final log in _logs)
          if (log.childId == childId) log,
      ];

  @override
  Future<List<FoodLog>> listLogs(
    String childId, {
    DateTime? from,
    DateTime? to,
  }) async {
    listCalls++;
    lastFrom = from;
    lastTo = to;
    return [
      for (final log in _logs)
        if (log.childId == childId &&
            (from == null || !log.eatenAt.isBefore(from)) &&
            (to == null || log.eatenAt.isBefore(to)))
          log,
    ]..sort((a, b) => a.eatenAt.compareTo(b.eatenAt));
  }

  @override
  Future<FoodLog> addLog(FoodLog log) async {
    final saved = log.copyWith(id: 'log-${_counter++}');
    _logs.add(saved);
    return saved;
  }

  @override
  Future<void> deleteLog(String id) async {
    _logs.removeWhere((log) => log.id == id);
  }
}

/// Aturan keragaman PALSU untuk tes (bukan `nutrition_rules.json`).
/// Tips memakai contoh jelas "CONTOH" agar mudah dikenali.
NutritionRules fakeNutritionRules({bool reviewed = true}) {
  return NutritionRules(
    version: 'test',
    groups: FoodGroup.allCodes.toSet(),
    animalSource: FoodGroup.animalProteinCodes.toSet(),
    profiles: const [
      DiversityProfile(
        minAgeMonths: 6,
        maxAgeMonths: 23,
        targetGroups: 5,
        countWithoutBreastMilk: false,
      ),
      DiversityProfile(
        minAgeMonths: 24,
        maxAgeMonths: 59,
        targetGroups: 5,
        countWithoutBreastMilk: true,
      ),
    ],
    tips: const {
      'breast_milk': 'Ayo beri ASI lebih sering hari ini.',
      'grains_tubers': 'Tambahkan makanan pokok seperti nasi atau bubur.',
      'legumes_nuts': 'Tambahkan tahu atau tempe hari ini.',
      'dairy': 'Tambahkan susu atau yogurt hari ini.',
      'flesh': 'Tambahkan lauk hewani hari ini.',
      'eggs': 'Tambahkan telur hari ini.',
      'vit_a_fruit_veg': 'Tambahkan sayuran atau buah kaya vitamin A.',
      'other_fruit_veg': 'Tambahkan buah atau sayur lainnya.',
    },
    reviewedBy: reviewed ? 'Test Ahli Gizi' : null,
    reviewedOn: reviewed ? '2026-11-11' : null,
  );
}
