import 'package:cekgizi/app.dart';
import 'package:cekgizi/core/config/app_config.dart';
import 'package:cekgizi/core/constants/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots and renders app name and disclaimer', (
    tester,
  ) async {
    await tester.pumpWidget(const CekGiziApp());

    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(find.text(AppStrings.disclaimer), findsOneWidget);
  });
}
