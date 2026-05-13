import 'package:isar/isar.dart';

part 'receipt_model.g.dart';

@collection
class ReceiptModel {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  /// uuid of the installment this receipt belongs to.
  @Index()
  late String installmentUuid;

  /// Local file path under app documents.
  late String filePath;

  /// 'image' | 'pdf'
  late String mimeKind;

  // OCR-extracted fields (nullable: may not be discoverable).
  double? extractedAmount;
  DateTime? extractedDate;
  String? extractedMerchant;
  String? rawOcrText;

  DateTime createdAt = DateTime.now();
}
