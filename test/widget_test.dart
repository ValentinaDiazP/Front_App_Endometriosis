import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application/main.dart';

void main() {
  testWidgets('FlorecerApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FlorecerApp());
    expect(find.byType(FlorecerApp), findsOneWidget);
  });
}
