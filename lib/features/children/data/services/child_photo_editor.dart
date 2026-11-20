import 'dart:typed_data';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Menangkap hasil pemotongan foto profil dan mengompresnya menjadi JPEG
/// kecil tanpa EXIF. Foto tidak pernah keluar dari perangkat.
abstract interface class ChildPhotoEditor {
  /// [boundaryKey] adalah `GlobalKey` dari `RepaintBoundary` yang membungkus
  /// gambar di dalam area lingkaran. Null bila widget belum siap.
  Future<Uint8List?> crop(GlobalKey boundaryKey);
}

final class RepaintBoundaryChildPhotoEditor implements ChildPhotoEditor {
  const RepaintBoundaryChildPhotoEditor();

  static const int _outputSize = 512;
  static const int _quality = 82;
  static const double _capturePixelRatio = 2;

  @override
  Future<Uint8List?> crop(GlobalKey boundaryKey) async {
    final context = boundaryKey.currentContext;
    if (context == null) return null;
    final boundary = context.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return null;

    final image = await boundary.toImage(pixelRatio: _capturePixelRatio);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData == null) return null;

    return FlutterImageCompress.compressWithList(
      Uint8List.sublistView(byteData),
      minWidth: _outputSize,
      minHeight: _outputSize,
      quality: _quality,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
  }
}
