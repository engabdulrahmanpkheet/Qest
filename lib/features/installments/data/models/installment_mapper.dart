import '../../domain/entities/installment.dart';
import 'installment_model.dart';

extension InstallmentModelX on InstallmentModel {
  Installment toDomain() => Installment(
        uuid: uuid,
        title: title,
        amount: amount,
        dueDate: dueDate,
        originalDueDate: originalDueDate,
        recurring: recurring,
        paymentApp: paymentApp,
        customDeeplink: customDeeplink,
        notes: notes,
        isPaid: isPaid,
        paidAt: paidAt,
        receiptIds: List<String>.from(receiptIds),
        snoozedUntil: snoozedUntil,
        calendarEventId: calendarEventId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

extension InstallmentX on Installment {
  InstallmentModel toModel([InstallmentModel? existing]) {
    final m = existing ?? InstallmentModel();
    m.uuid = uuid;
    m.title = title;
    m.amount = amount;
    m.dueDate = dueDate;
    m.originalDueDate = originalDueDate;
    m.recurring = recurring;
    m.paymentApp = paymentApp;
    m.customDeeplink = customDeeplink;
    m.notes = notes;
    m.isPaid = isPaid;
    m.paidAt = paidAt;
    m.receiptIds = List<String>.from(receiptIds);
    m.snoozedUntil = snoozedUntil;
    m.calendarEventId = calendarEventId;
    if (createdAt != null) m.createdAt = createdAt!;
    m.updatedAt = DateTime.now();
    return m;
  }
}
