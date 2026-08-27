import 'package:flutter_test/flutter_test.dart';
import 'package:fpg/main.dart';

void main() {
  testWidgets('FPG app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const FPGApp());
    expect(find.byType(FPGApp), findsOneWidget);
  });
}
