import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/features/children/data/services/child_photo_editor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('crop null bila RepaintBoundary belum terpasang', () async {
    const editor = RepaintBoundaryChildPhotoEditor();
    final key = GlobalKey();
    expect(await editor.crop(key), isNull);
  });
}
