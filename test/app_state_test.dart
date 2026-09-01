import 'package:familia_financas/app_state.dart';
import 'package:familia_financas/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('restore keeps the current state when a backup is invalid', () async {
    final state = AppState()
      ..profiles = [FamilyProfile(id: '1', name: 'Lucas', emoji: 'P')]
      ..bills = [
        Bill(
          id: 'bill-1',
          title: 'Internet',
          amount: 100,
          dueDay: 10,
          category: 'Casa',
          recurrence: 'once',
          startMonth: '2026-09',
        ),
      ];

    await expectLater(
      state.restore(
        '{"profiles": [], "bills": [{"id": "incomplete"}]}',
      ),
      throwsA(isA<FormatException>()),
    );

    expect(state.profiles.single.name, 'Lucas');
    expect(state.bills.single.title, 'Internet');
  });

  test('load preserves readable data when another collection is corrupted', () async {
    SharedPreferences.setMockInitialValues({
      'profiles_v2': '[{"id":"1","name":"Lucas","emoji":"P"}]',
      'bills_v2': '{invalid json',
      'incomes_v2': '[{"id":"income-1","title":"Salario","amount":1000,"profileId":"1","category":"Renda","recurrence":"once","startMonth":"2026-09"}]',
      'goals_v2': '[]',
    });
    final state = AppState();

    await state.load();

    expect(state.profiles.single.name, 'Lucas');
    expect(state.bills, isEmpty);
    expect(state.incomes.single.title, 'Salario');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('bills_v2'), '{invalid json');
  });
}
