import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/features/children/data/datasources/child_photo_store.dart';

/// Unit test untuk penyimpanan foto profil lokal. Memakai folder sementara
/// nyata agar path, penggantian foto, dan penghapusan benar-benar diuji.
void main() {
  late Directory tempDir;
  late LocalChildPhotoStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('child_photo_store_test');
    store = LocalChildPhotoStore(directoryResolver: () async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('pathFor null sebelum ada foto disimpan', () async {
    expect(await store.pathFor('child-1'), isNull);
  });

  test('save menulis file & pathFor mengembalikannya', () async {
    const bytes = [11, 22, 33, 44];
    final path = await store.save('child-1', Uint8List.fromList(bytes));
    final file = File(path);
    expect(await file.exists(), isTrue);
    expect(await file.readAsBytes(), equals(bytes));
    expect(await store.pathFor('child-1'), path);
  });

  test('save mengganti foto lama', () async {
    final first = await store.save('child-1', Uint8List.fromList([1]));
    final second = await store.save('child-1', Uint8List.fromList([2, 2]));
    expect(await File(first).exists(), isFalse);
    expect(await File(second).readAsBytes(), equals([2, 2]));
    expect(await store.pathFor('child-1'), second);
  });

  test(
    'foto terisolasi per anak - menghapus satu tidak menghapus yang lain',
    () async {
      final first = await store.save('child-1', Uint8List.fromList([1]));
      final second = await store.save('child-2', Uint8List.fromList([2]));
      await store.delete('child-1');
      expect(await store.pathFor('child-1'), isNull);
      expect(await File(second).exists(), isTrue);
      expect(await store.pathFor('child-2'), second);
      expect(await File(first).exists(), isFalse);
    },
  );

  test('tolak bytes kosong', () async {
    expect(() => store.save('child-1', Uint8List(0)), throwsArgumentError);
  });

  test('ID aneh dibersihkan agar tidak keluar folder', () async {
    final path = await store.save('../evil/child-1', Uint8List.fromList([7]));
    expect(File(path).parent.path, endsWith('child_photos'));
    expect(path.contains('..'), isFalse);
    expect(await store.pathFor('../evil/child-1'), path);
  });
}
