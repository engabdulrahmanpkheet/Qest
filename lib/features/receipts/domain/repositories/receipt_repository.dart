import '../entities/receipt.dart';

abstract class ReceiptRepository {
  Future<void> upsert(Receipt receipt);
  Future<Receipt?> getByUuid(String uuid);
  Future<List<Receipt>> forInstallment(String installmentUuid);
  Future<void> delete(String uuid);
}
