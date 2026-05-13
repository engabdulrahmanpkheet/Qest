import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/installments/data/models/installment_model.dart';
import '../../features/receipts/data/models/receipt_model.dart';
import '../constants/app_constants.dart';

/// Single-instance Isar wrapper. Opened once per process.
class IsarService {
  IsarService._(this.isar);
  final Isar isar;

  static IsarService? _instance;
  static IsarService get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('IsarService not initialised — call IsarService.init() first.');
    }
    return i;
  }

  static Future<IsarService> init() async {
    if (_instance != null) return _instance!;
    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
      [InstallmentModelSchema, ReceiptModelSchema],
      directory: dir.path,
      name: AppConstants.dbName,
      inspector: false,
    );
    _instance = IsarService._(isar);
    return _instance!;
  }

  Future<void> close() async {
    await isar.close();
    _instance = null;
  }
}
