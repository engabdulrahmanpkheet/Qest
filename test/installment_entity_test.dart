import 'package:flutter_test/flutter_test.dart';
import 'package:qest/features/installments/domain/entities/installment.dart';
import 'package:qest/features/installments/domain/entities/payment_app.dart';
import 'package:qest/features/installments/domain/entities/recurring_type.dart';

Installment _make({DateTime? due, bool paid = false}) {
  final d = due ?? DateTime.now().add(const Duration(days: 5));
  return Installment(
    uuid: 'u',
    title: 'Rent',
    amount: 100,
    dueDate: d,
    originalDueDate: d,
    recurring: RecurringType.monthly,
    paymentApp: PaymentApp.none,
    isPaid: paid,
  );
}

void main() {
  test('isOverdue is false for future unpaid', () {
    expect(_make().isOverdue, false);
  });

  test('isOverdue is true for past unpaid', () {
    final i = _make(due: DateTime.now().subtract(const Duration(days: 2)));
    expect(i.isOverdue, true);
  });

  test('isOverdue is false when paid', () {
    final i = _make(
      due: DateTime.now().subtract(const Duration(days: 2)),
      paid: true,
    );
    expect(i.isOverdue, false);
  });

  test('daysUntilDue counts whole days', () {
    final i = _make(due: DateTime.now().add(const Duration(days: 3)));
    expect(i.daysUntilDue(), inInclusiveRange(2, 3));
  });

  test('RecurringType rolls forward correctly', () {
    final base = DateTime(2026, 1, 31, 10);
    expect(RecurringType.daily.nextOccurrence(base),
        base.add(const Duration(days: 1)));
    expect(RecurringType.weekly.nextOccurrence(base),
        base.add(const Duration(days: 7)));
    expect(RecurringType.monthly.nextOccurrence(base).month, 2);
    expect(RecurringType.yearly.nextOccurrence(base).year, 2027);
  });
}
