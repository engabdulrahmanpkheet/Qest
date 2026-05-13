import 'package:isar/isar.dart';

import '../../../../core/services/isar_service.dart';
import '../../domain/entities/receipt.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../models/receipt_mapper.dart';
import '../models/receipt_model.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  ReceiptRepositoryImpl(this._isar);

  final IsarService _isar;
  Isar get _db => _isar.isar;

  @override
  Future<void> upsert(Receipt receipt) async {
    final existing = await _db.receiptModels
        .filter()
        .uuidEqualTo(receipt.uuid)
        .findFirst();
    final model = receipt.toModel(existing);
    await _db.writeTxn(() => _db.receiptModels.put(model));
  }

  @override
  Future<Receipt?> getByUuid(String uuid) async {
    final r = await _db.receiptModels.filter().uuidEqualTo(uuid).findFirst();
    return r?.toDomain();
  }

  @override
  Future<List<Receipt>> forInstallment(String installmentUuid) async {
    final rows = await _db.receiptModels
        .filter()
        .installmentUuidEqualTo(installmentUuid)
        .sortByCreatedAtDesc()
        .findAll();
    return rows.map((e) => e.toDomain()).toList();
  }

  @override
  Future<void> delete(String uuid) async {
    await _db.writeTxn(() async {
      final r = await _db.receiptModels.filter().uuidEqualTo(uuid).findFirst();
      if (r != null) await _db.receiptModels.delete(r.id);
    });
  }
}
