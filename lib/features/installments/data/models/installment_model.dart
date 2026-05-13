import 'package:isar/isar.dart';

import '../../domain/entities/payment_app.dart';
import '../../domain/entities/recurring_type.dart';

part 'installment_model.g.dart';

@collection
class InstallmentModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  late String title;
  late double amount;

  /// Stored in UTC, but represents the user's wall-clock due moment.
  late DateTime dueDate;

  /// Original due date for the *first* occurrence — used so recurring
  /// payments can roll forward without drift.
  late DateTime originalDueDate;

  @enumerated
  RecurringType recurring = RecurringType.none;

  @enumerated
  PaymentApp paymentApp = PaymentApp.none;

  String? customDeeplink;
  String? notes;

  bool isPaid = false;
  DateTime? paidAt;

  /// Receipt linkage; receipts are a separate collection.
  List<String> receiptIds = const [];

  /// If snoozed (e.g. user said "no money"), pause reminders until this.
  DateTime? snoozedUntil;

  DateTime createdAt = DateTime.now();
  DateTime updatedAt = DateTime.now();

  /// Optional native calendar event id (so we can update / delete on edit).
  String? calendarEventId;
}
