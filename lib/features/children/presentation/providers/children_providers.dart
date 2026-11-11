import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cekgizi/core/supabase/supabase_client_provider.dart';
import 'package:cekgizi/features/children/data/repositories/child_repository_impl.dart';
import 'package:cekgizi/features/children/domain/entities/child_profile.dart';
import 'package:cekgizi/features/children/domain/repositories/child_repository.dart';
import 'package:cekgizi/features/children/domain/use_cases/child_use_cases.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';

final childRepositoryProvider = Provider<ChildRepository>(
  (ref) => ChildRepositoryImpl(ref.watch(supabaseClientProvider)),
);

final childrenListProvider =
    AsyncNotifierProvider<ChildrenListNotifier, List<ChildProfile>>(
  ChildrenListNotifier.new,
);

class ChildrenListNotifier extends AsyncNotifier<List<ChildProfile>> {
  @override
  Future<List<ChildProfile>> build() =>
      ref.watch(childRepositoryProvider).listChildren();

  Future<ChildProfile> addChild({
    required String nickname,
    required DateTime birthDate,
    required Sex sex,
    required String avatarKey,
  }) async {
    final profile = await ChildUseCases.add(
      ref.read(childRepositoryProvider),
      nickname: nickname,
      birthDate: birthDate,
      sex: sex,
      avatarKey: avatarKey,
    );
    final current = state.value ?? const [];
    state = AsyncData([...current, profile]);
    return profile;
  }

  Future<ChildProfile> updateChild(ChildProfile updated) async {
    final saved = await ref.read(childRepositoryProvider).updateChild(updated);
    final current = state.value ?? const [];
    state = AsyncData([
      for (final child in current)
        if (child.id == saved.id) saved else child,
    ]);
    return saved;
  }

  Future<void> deleteChild(String id) async {
    await ref.read(childRepositoryProvider).deleteChild(id);
    final current = state.value ?? const [];
    state = AsyncData([
      for (final child in current)
        if (child.id != id) child,
    ]);
  }
}

final selectedChildIdProvider =
    NotifierProvider<SelectedChildIdNotifier, String?>(SelectedChildIdNotifier.new);

class SelectedChildIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;
}

/// Anak yang sedang dipilih; fallback ke anak pertama. AsyncValue membungkus
/// error/loading daftar agar UI bisa menampilkannya.
final selectedChildProvider = Provider<AsyncValue<ChildProfile?>>((ref) {
  final list = ref.watch(childrenListProvider);
  final selectedId = ref.watch(selectedChildIdProvider);
  return list.whenData((children) {
    if (children.isEmpty) return null;
    return children.where((c) => c.id == selectedId).firstOrNull ??
        children.first;
  });
});
