import 'package:cekgizi/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots and renders token gallery', (
    tester,
  ) async {
    await tester.pumpWidget(const CekGiziApp());

    expect(find.text('Token Galeri (Batch 1)'), findsOneWidget);
    expect(find.text('Tema Light'), findsOneWidget);
    expect(find.text('Tema Dark'), findsOneWidget);
  });

  testWidgets('Gallery renders all token sections in both themes', (
    tester,
  ) async {
    await tester.pumpWidget(const CekGiziApp());

    // Section headers render once per theme preview (Light + Dark).
    expect(find.text('Warna'), findsNWidgets(2));
    expect(find.text('Tipografi'), findsNWidgets(2));
    expect(find.text('Spacing (4pt)'), findsNWidgets(2));
    expect(find.text('Radius'), findsNWidgets(2));
    expect(find.text('Motion'), findsNWidgets(2));
    expect(find.text('Tombol'), findsNWidgets(2));
    expect(find.text('Komponen'), findsNWidgets(2));
  });
}
