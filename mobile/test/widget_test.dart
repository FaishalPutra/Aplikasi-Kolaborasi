import 'package:flutter_test/flutter_test.dart';
import 'package:collab_platform/main.dart';

void main() {
  testWidgets('App memuat halaman login', (WidgetTester tester) async {
    await tester.pumpWidget(const CollabApp());
    expect(find.text('Collab Platform'), findsOneWidget);
  });
}
