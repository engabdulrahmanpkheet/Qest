import 'package:isar/isar.dart';

import '../../../../core/services/isar_service.dart';
import '../../domain/entities/installment.dart';
import '../../domain/repositories/installment_repository.dart';
import '../models/installment_mapper.dart';
import '../models/installment_model.dart';

class InstallmentRepositoryImpl implements InstallmentRepository {
  InstallmentRepositoryImpl(this._isar);

  final IsarService _isar;

  Isar get _db => _isar.isar;

  @override
  Future<List<Installment>> getAll() async {
    final rows = await _db.installmentModels.where().sortByDueDate().findAll();
    return rows.map((e) => e.toDomain()).toList();
  }

  @override
  Stream<List<Installment>> watchAll() {
    return _db.installmentModels
        .where()
        .sortByDueDate()
        .watch(fireImmediately: true)
        .map((rows) => rows.map((e) => e.toDomain()).toList());
  }

  @override
  Future<Installment?> getByUuid(String uuid) async {
    final row = await _db.installmentModels
        .filter()
        .uuidEqualTo(uuid)
        .findFirst();
    return row?.toDomain();
  }

  @override
  Future<void> upsert(Installment installment) async {
    final existing = await _db.installmentModels
        .filter()
        .uuidEqualTo(installment.uuid)
        .findFirst();
    final model = installment.toModel(existing);
    await _db.writeTxn(() => _db.installmentModels.put(model));
  }

  @override
  Future<void> delete(String uuid) async {
    await _db.writeTxn(() async {
      final row = await _db.installmentModels
          .filter()
          .uuidEqualTo(uuid)
          .findFirst();
      if (row != null) await _db.installmentModels.delete(row.id);
    });
  }

  @override
  Future<void> markPaid(String uuid, {DateTime? at}) async {
    final row = await _db.installmentModels
        .filter()
        .uuidEqualTo(uuid)
        .findFirst();
    if (row == null) return;
    row.isPaid = true;
    row.paidAt = at ?? DateTime.now();
    row.updatedAt = DateTime.now();
    await _db.writeTxn(() => _db.installmentModels.put(row));
  }

  @override
  Future<void> snooze(String uuid, Duration by) async {
    final row = await _db.installmentModels
        .filter()
        .uuidEqualTo(uuid)
        .findFirst();
    if (row == null) return;
    row.snoozedUntil = DateTime.now().add(by);
    row.updatedAt = DateTime.now();
    await _db.writeTxn(() => _db.installmentModels.put(row));
  }

  @override
  Future<void> attachReceipt(String installmentUuid, String receiptUuid) async {
    final row = await _db.installmentModels
        .filter()
        .uuidEqualTo(installmentUuid)
        .findFirst();
    if (row == null) return;
    final next = List<String>.from(row.receiptIds);
    if (!next.contains(receiptUuid)) next.add(receiptUuid);
    row.receiptIds = next;
    row.updatedAt = DateTime.now();
    await _db.writeTxn(() => _db.installmentModels.put(row));
  }

  @override
  Future<List<Installment>> upcoming({int withinDays = 30}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final until = today.add(Duration(days: withinDays));
    final rows = await _db.installmentModels
        .filter()
        .isPaidEqualTo(false)
        .and()
        .dueDateGreaterThan(today)
        .and()
        .dueDateLessThan(until)
        .sortByDueDate()
        .findAll();
    return rows.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Installment>> overdue() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rows = await _db.installmentModels
        .filter()
        .isPaidEqualTo(false)
        .and()
        .dueDateLessThan(today)
        .sortByDueDate()
        .findAll();
    return rows.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Installment>> dueOn(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _db.installmentModels
        .filter()
        .dueDateGreaterThan(start.subtract(const Duration(seconds: 1)))
        .and()
        .dueDateLessThan(end)
        .findAll();
    return rows.map((e) => e.toDomain()).toList();
  }

  @override
  Future<double> monthlyTotal(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);
    final rows = await _db.installmentModels
        .filter()
        .dueDateGreaterThan(start.subtract(const Duration(seconds: 1)))
        .and()
        .dueDateLessThan(end)
        .findAll();
    return rows.fold<double>(0, (s, r) => s + r.amount);
  }
}
