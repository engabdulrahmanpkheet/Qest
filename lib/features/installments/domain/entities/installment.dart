import 'payment_app.dart';
import 'recurring_type.dart';

/// Domain-layer immutable view of an installment / subscription / bill.
class Installment {
  const Installment({
    required this.uuid,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.originalDueDate,
    required this.recurring,
    required this.paymentApp,
    this.customDeeplink,
    this.notes,
    this.isPaid = false,
    this.paidAt,
    this.receiptIds = const [],
    this.snoozedUntil,
    this.calendarEventId,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt,
        updatedAt = updatedAt;

  final String uuid;
  final String title;
  final double amount;
  final DateTime dueDate;
  final DateTime originalDueDate;
  final RecurringType recurring;
  final PaymentApp paymentApp;
  final String? customDeeplink;
  final String? notes;
  final bool isPaid;
  final DateTime? paidAt;
  final List<String> receiptIds;
  final DateTime? snoozedUntil;
  final String? calendarEventId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isOverdue {
    if (isPaid) return false;
    final now = DateTime.now();
    return dueDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  int daysUntilDue() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.difference(today).inDays;
  }

  Installment copyWith({
    String? title,
    double? amount,
    DateTime? dueDate,
    DateTime? originalDueDate,
    RecurringType? recurring,
    PaymentApp? paymentApp,
    String? customDeeplink,
    String? notes,
    bool? isPaid,
    DateTime? paidAt,
    List<String>? receiptIds,
    DateTime? snoozedUntil,
    String? calendarEventId,
  }) {
    return Installment(
      uuid: uuid,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      originalDueDate: originalDueDate ?? this.originalDueDate,
      recurring: recurring ?? this.recurring,
      paymentApp: paymentApp ?? this.paymentApp,
      customDeeplink: customDeeplink ?? this.customDeeplink,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      receiptIds: receiptIds ?? this.receiptIds,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
