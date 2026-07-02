import 'package:flutter_test/flutter_test.dart';
import 'package:axiom/core/routes/app_routes.dart';
import 'package:axiom/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AxiomApp(initialRoute: AppRoutes.home));
    // Let the shell's initial quest fetch (mocked with a 300ms delay) settle
    // so no timer is left pending when the test tears down.
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.byType(AxiomApp), findsOneWidget);
  });
}
