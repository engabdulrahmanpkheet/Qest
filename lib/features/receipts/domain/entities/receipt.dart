class Receipt {
  const Receipt({
    required this.uuid,
    required this.installmentUuid,
    required this.filePath,
    required this.mimeKind,
    this.extractedAmount,
    this.extractedDate,
    this.extractedMerchant,
    this.rawOcrText,
    DateTime? createdAt,
  }) : createdAt = createdAt;

  final String uuid;
  final String installmentUuid;
  final String filePath;
  final String mimeKind;
  final double? extractedAmount;
  final DateTime? extractedDate;
  final String? extractedMerchant;
  final String? rawOcrText;
  final DateTime? createdAt;
}
