import 'package:flutter_test/flutter_test.dart';
import 'package:familia_financas/models.dart';

void main() {
  test('monthDistance calculates month intervals', () {
    expect(monthDistance('2026-08', '2026-08'), 0);
    expect(monthDistance('2026-08', '2026-09'), 1);
    expect(monthDistance('2026-12', '2027-02'), 2);
  });

  test('fixed bill applies to future months', () {
    final bill = Bill(id: '1', title: 'Internet', amount: 100, dueDay: 10, category: 'Casa', recurrence: 'fixed', startMonth: '2026-08');
    expect(bill.appliesTo('2026-07'), false);
    expect(bill.appliesTo('2026-08'), true);
    expect(bill.appliesTo('2027-01'), true);
  });

  test('installment bill stops after duration', () {
    final bill = Bill(id: '1', title: 'Geladeira', amount: 200, dueDay: 10, category: 'Casa', recurrence: 'installments', startMonth: '2026-08', durationMonths: 3);
    expect(bill.appliesTo('2026-08'), true);
    expect(bill.installmentNumber('2026-08'), 1);
    expect(bill.appliesTo('2026-10'), true);
    expect(bill.installmentNumber('2026-10'), 3);
    expect(bill.appliesTo('2026-11'), false);
  });
}
