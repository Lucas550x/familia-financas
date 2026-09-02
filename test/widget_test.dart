import 'package:familia_financas/main.dart';
import 'package:familia_financas/supabase_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
    );
  });

  testWidgets('app opens the sign-in screen without a session', (tester) async {
    SharedPreferences.setMockInitialValues({
      'updateChecks': false,
      'soundEnabled': false,
    });

    await tester.pumpWidget(const FamiliaFinancasApp());
    await tester.pumpAndSettle();

    expect(find.text('Família Finanças'), findsWidgets);
    expect(find.text('Entre para acessar a sua família.'), findsOneWidget);
  });
}
