import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cekgizi/core/theme/app_theme.dart';
import 'package:cekgizi/features/growth/domain/entities/sex.dart';
import 'package:cekgizi/shared/widgets/child_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<String?> assetOf(WidgetTester tester, Sex sex) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: ChildAvatar(sex: sex, size: 80)),
      ),
    );
    await tester.pump();
    final image = tester.widget<Image>(find.byType(Image));
    return (image.image as AssetImage?)?.assetName;
  }

  testWidgets('avatar default laki-laki memakai aset avatar_boy', (
    tester,
  ) async {
    expect(await assetOf(tester, Sex.male), 'assets/avatars/avatar_boy.png');
  });

  testWidgets('avatar default perempuan memakai aset avatar_girl', (
    tester,
  ) async {
    expect(await assetOf(tester, Sex.female), 'assets/avatars/avatar_girl.png');
  });
}
