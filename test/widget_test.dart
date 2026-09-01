import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:familia_financas/main.dart';

void main() {
  testWidgets('app opens the dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({
      'updateChecks': false,
      'soundEnabled': false,
    });

    await tester.pumpWidget(const FamiliaFinancasApp());
    await tester.pumpAndSettle();

    expect(find.text('Família Finanças'), findsWidgets);
    expect(find.text('Sobra prevista'), findsOneWidget);
  });
}
