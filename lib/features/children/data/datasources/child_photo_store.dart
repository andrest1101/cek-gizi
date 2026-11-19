import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Penyimpanan foto profil anak yang **hanya ada di perangkat**.
///
/// Foto tidak pernah dikirim ke Supabase, Edge Function, atau Gemini. Folder
/// `child_photos/` juga dikecualikan dari backup otomatis Android (lihat
/// `res/xml/backup_rules.xml` dan `data_extraction_rules.xml`).
abstract interface class ChildPhotoStore {
  /// Path foto terbaru milik [childId], atau null bila belum ada.
  Future<String?> pathFor(String childId);

  /// Simpan foto baru dan hapus versi lama. Mengembalikan path file.
  Future<String> save(String childId, Uint8List bytes);

  /// Hapus semua foto milik [childId].
  Future<void> delete(String childId);
}

/// Resolver direktori dasar - dapat diganti di tes agar tidak memanggil
/// plugin `path_provider`.
typedef ChildPhotoDirectoryResolver = Future<Directory> Function();

final class LocalChildPhotoStore implements ChildPhotoStore {
  LocalChildPhotoStore({ChildPhotoDirectoryResolver? directoryResolver})
    : _resolveDirectory = directoryResolver;

  static const _folder = 'child_photos';
  static const _extension = '.jpg';

  final ChildPhotoDirectoryResolver? _resolveDirectory;
  final Map<String, String?> _cache = {};
  Directory? _root;

  Future<Directory> _directory() async {
    final cached = _root;
    if (cached != null) return cached;
    final base = _resolveDirectory == null
        ? await getApplicationSupportDirectory()
        : await _resolveDirectory();
    final directory = Directory(
      '${base.path}${Platform.pathSeparator}$_folder',
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    _root = directory;
    return directory;
  }

  @override
  Future<String?> pathFor(String childId) async {
    if (_cache.containsKey(childId)) return _cache[childId];
    final directory = await _directory();
    final prefix = '${_safe(childId)}-';
    String? newest;
    DateTime? newestAt;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.startsWith(prefix) || !name.endsWith(_extension)) continue;
      final stat = await entity.stat();
      if (newestAt == null || stat.modified.isAfter(newestAt)) {
        newest = entity.path;
        newestAt = stat.modified;
      }
    }
    _cache[childId] = newest;
    return newest;
  }

  @override
  Future<String> save(String childId, Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'Foto kosong');
    }
    final directory = await _directory();
    await delete(childId);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final file = File(
      '${directory.path}${Platform.pathSeparator}'
      '${_safe(childId)}-$stamp$_extension',
    );
    await file.writeAsBytes(bytes, flush: true);
    _cache[childId] = file.path;
    return file.path;
  }

  @override
  Future<void> delete(String childId) async {
    final directory = await _directory();
    final prefix = '${_safe(childId)}-';
    if (await directory.exists()) {
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File) continue;
        if (entity.uri.pathSegments.last.startsWith(prefix)) {
          await entity.delete();
        }
      }
    }
    _cache[childId] = null;
  }

  /// ID anak berupa UUID; tetap dibersihkan agar tidak bisa keluar folder.
  String _safe(String childId) =>
      childId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}
