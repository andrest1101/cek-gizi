import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Sumber foto profil anak.
enum ChildPhotoSource { camera, gallery }

/// Galat ramah untuk foto profil. UI memetakan kode ini ke copy Indonesia.
final class ChildPhotoException implements Exception {
  const ChildPhotoException(this.code);

  final String code;

  @override
  String toString() => 'ChildPhotoException($code)';
}

/// Memilih foto dari kamera/galeri lalu mengompresnya menjadi JPEG kecil
/// tanpa EXIF/GPS.
abstract interface class ChildPhotoPicker {
  /// Null bila pengguna membatalkan pemilihan.
  Future<Uint8List?> pick(ChildPhotoSource source);
}

final class ImagePickerChildPhotoPicker implements ChildPhotoPicker {
  const ImagePickerChildPhotoPicker();

  /// Foto hanya dipakai sebagai avatar; 512px sudah lebih dari cukup untuk
  /// layar 3x dan menjaga file tetap kecil.
  static const int _maxSide = 512;
  static const int _quality = 82;

  @override
  Future<Uint8List?> pick(ChildPhotoSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source == ChildPhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: _maxSide.toDouble(),
      maxHeight: _maxSide.toDouble(),
      imageQuality: 90,
      // Jangan minta metadata lengkap; tetap di-strip lagi oleh compressor.
      requestFullMetadata: false,
    );
    if (picked == null) return null;

    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        picked.path,
        minWidth: _maxSide,
        minHeight: _maxSide,
        quality: _quality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );
      if (compressed == null || compressed.isEmpty) {
        throw const ChildPhotoException('compress_failed');
      }
      return Uint8List.fromList(compressed);
    } on ChildPhotoException {
      rethrow;
    } catch (_) {
      throw const ChildPhotoException('compress_failed');
    } finally {
      // File sementara dari picker masih membawa EXIF asli - hapus.
      try {
        await File(picked.path).delete();
      } catch (_) {
        // File sementara bisa sudah dibersihkan sistem; abaikan.
      }
    }
  }
}
