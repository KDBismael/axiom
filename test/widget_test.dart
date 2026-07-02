import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AxiomApp());
    expect(find.byType(AxiomApp), findsOneWidget);
  });
}
