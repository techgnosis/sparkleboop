import 'package:flutter_test/flutter_test.dart';
import 'package:sparkleboop/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SparkleBoopApp());
    expect(find.text('SPARKLEBOOP'), findsOneWidget);
    expect(find.text('New Game'), findsOneWidget);
  });
}
