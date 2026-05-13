import '../entities/installment.dart';

abstract class InstallmentRepository {
  Future<List<Installment>> getAll();
  Stream<List<Installment>> watchAll();

  Future<Installment?> getByUuid(String uuid);
  Future<void> upsert(Installment installment);
  Future<void> delete(String uuid);

  Future<void> markPaid(String uuid, {DateTime? at});
  Future<void> snooze(String uuid, Duration by);
  Future<void> attachReceipt(String installmentUuid, String receiptUuid);

  Future<List<Installment>> upcoming({int withinDays = 30});
  Future<List<Installment>> overdue();
  Future<List<Installment>> dueOn(DateTime date);
  Future<double> monthlyTotal(DateTime month);
}
