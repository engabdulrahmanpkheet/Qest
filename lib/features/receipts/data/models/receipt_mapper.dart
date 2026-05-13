import '../../domain/entities/receipt.dart';
import 'receipt_model.dart';

extension ReceiptModelX on ReceiptModel {
  Receipt toDomain() => Receipt(
        uuid: uuid,
        installmentUuid: installmentUuid,
        filePath: filePath,
        mimeKind: mimeKind,
        extractedAmount: extractedAmount,
        extractedDate: extractedDate,
        extractedMerchant: extractedMerchant,
        rawOcrText: rawOcrText,
        createdAt: createdAt,
      );
}

extension ReceiptX on Receipt {
  ReceiptModel toModel([ReceiptModel? existing]) {
    final m = existing ?? ReceiptModel();
    m.uuid = uuid;
    m.installmentUuid = installmentUuid;
    m.filePath = filePath;
    m.mimeKind = mimeKind;
    m.extractedAmount = extractedAmount;
    m.extractedDate = extractedDate;
    m.extractedMerchant = extractedMerchant;
    m.rawOcrText = rawOcrText;
    if (createdAt != null) m.createdAt = createdAt!;
    return m;
  }
}
