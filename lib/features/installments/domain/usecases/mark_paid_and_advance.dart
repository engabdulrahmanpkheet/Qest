import 'package:uuid/uuid.dart';

import '../../../../core/services/notifications/notification_service.dart';
import '../../../../core/services/widgets/home_widget_service.dart';
import '../entities/installment.dart';
import '../entities/recurring_type.dart';
import '../repositories/installment_repository.dart';

/// Marks [installment] as paid, and — if it recurs — creates the next
/// occurrence with a fresh UUID, an empty receipt list and reschedules
/// its notification ladder. Idempotent if called twice for the same
/// paid state.
///
/// Returns the newly-created next installment, or null when the
/// payment is one-time.
class MarkPaidAndAdvance {
  MarkPaidAndAdvance({
    required this.repository,
    required this.notifications,
    required this.widgets,
  });

  final InstallmentRepository repository;
  final NotificationService notifications;
  final HomeWidgetService widgets;

  Future<Installment?> call(Installment installment) async {
    // 1. Mark current as paid and stop its reminders.
    await repository.markPaid(installment.uuid);
    await notifications.cancelForInstallment(installment.uuid);

    // 2. For one-time payments we're done.
    if (installment.recurring == RecurringType.none) {
      await widgets.refresh(repository);
      return null;
    }

    // 3. Build the next occurrence. We anchor on `originalDueDate` so
    //    monthly bills don't drift forward by a day each cycle (e.g.
    //    "the 15th of every month" stays the 15th).
    final nextDue = installment.recurring.nextOccurrence(installment.dueDate);
    final next = Installment(
      uuid: const Uuid().v4(),
      title: installment.title,
      amount: installment.amount,
      dueDate: nextDue,
      originalDueDate: nextDue,
      recurring: installment.recurring,
      paymentApp: installment.paymentApp,
      customDeeplink: installment.customDeeplink,
      notes: installment.notes,
      isPaid: false,
      paidAt: null,
      receiptIds: const [],
      snoozedUntil: null,
      calendarEventId: null,
    );

    await repository.upsert(next);
    await notifications.scheduleForInstallment(next);
    await widgets.refresh(repository);
    return next;
  }
}
