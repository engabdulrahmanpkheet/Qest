import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../features/installments/data/repositories/installment_repository_impl.dart';
import '../../../features/installments/domain/entities/installment.dart';
import '../../../features/installments/domain/entities/payment_app.dart';
import '../../../features/installments/domain/entities/recurring_type.dart';
import '../../../features/receipts/data/repositories/receipt_repository_impl.dart';
import '../../../features/receipts/domain/entities/receipt.dart';
import '../isar_service.dart';

/// Local JSON backup / restore. Receipts are referenced by file path —
/// the user keeps responsibility for transferring those files.
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  Future<File> exportToJson() async {
    final isar = IsarService.instance;
    final installments = await InstallmentRepositoryImpl(isar).getAll();
    final receipts = <Map<String, dynamic>>[];
    final receiptRepo = ReceiptRepositoryImpl(isar);
    for (final i in installments) {
      for (final rid in i.receiptIds) {
        final r = await receiptRepo.getByUuid(rid);
        if (r != null) receipts.add(_receiptToJson(r));
      }
    }

    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'installments': installments.map(_installmentToJson).toList(),
      'receipts': receipts,
    };

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      '${dir.path}/qest_backup_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(jsonEncode(payload));
    return file;
  }

  Future<int> importFromJson() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (res == null || res.files.isEmpty) return 0;
    final f = File(res.files.single.path!);
    final text = await f.readAsString();
    final data = jsonDecode(text) as Map<String, dynamic>;
    final isar = IsarService.instance;
    final iRepo = InstallmentRepositoryImpl(isar);
    final rRepo = ReceiptRepositoryImpl(isar);

    int count = 0;
    for (final m in (data['installments'] as List? ?? [])) {
      final i = _installmentFromJson(m as Map<String, dynamic>);
      await iRepo.upsert(i);
      count++;
    }
    for (final m in (data['receipts'] as List? ?? [])) {
      final r = _receiptFromJson(m as Map<String, dynamic>);
      await rRepo.upsert(r);
    }
    return count;
  }

  Map<String, dynamic> _installmentToJson(Installment i) => {
        'uuid': i.uuid,
        'title': i.title,
        'amount': i.amount,
        'dueDate': i.dueDate.toIso8601String(),
        'originalDueDate': i.originalDueDate.toIso8601String(),
        'recurring': i.recurring.name,
        'paymentApp': i.paymentApp.name,
        'customDeeplink': i.customDeeplink,
        'notes': i.notes,
        'isPaid': i.isPaid,
        'paidAt': i.paidAt?.toIso8601String(),
        'receiptIds': i.receiptIds,
        'snoozedUntil': i.snoozedUntil?.toIso8601String(),
        'calendarEventId': i.calendarEventId,
      };

  Installment _installmentFromJson(Map<String, dynamic> m) => Installment(
        uuid: m['uuid'] as String,
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        dueDate: DateTime.parse(m['dueDate'] as String),
        originalDueDate: DateTime.parse(m['originalDueDate'] as String),
        recurring: RecurringType.values.byName(m['recurring'] as String),
        paymentApp: PaymentApp.values.byName(m['paymentApp'] as String),
        customDeeplink: m['customDeeplink'] as String?,
        notes: m['notes'] as String?,
        isPaid: m['isPaid'] as bool? ?? false,
        paidAt: (m['paidAt'] as String?) != null
            ? DateTime.parse(m['paidAt'] as String)
            : null,
        receiptIds: List<String>.from(m['receiptIds'] as List? ?? []),
        snoozedUntil: (m['snoozedUntil'] as String?) != null
            ? DateTime.parse(m['snoozedUntil'] as String)
            : null,
        calendarEventId: m['calendarEventId'] as String?,
      );

  Map<String, dynamic> _receiptToJson(Receipt r) => {
        'uuid': r.uuid,
        'installmentUuid': r.installmentUuid,
        'filePath': r.filePath,
        'mimeKind': r.mimeKind,
        'extractedAmount': r.extractedAmount,
        'extractedDate': r.extractedDate?.toIso8601String(),
        'extractedMerchant': r.extractedMerchant,
        'rawOcrText': r.rawOcrText,
      };

  Receipt _receiptFromJson(Map<String, dynamic> m) => Receipt(
        uuid: m['uuid'] as String,
        installmentUuid: m['installmentUuid'] as String,
        filePath: m['filePath'] as String,
        mimeKind: m['mimeKind'] as String,
        extractedAmount: (m['extractedAmount'] as num?)?.toDouble(),
        extractedDate: (m['extractedDate'] as String?) != null
            ? DateTime.parse(m['extractedDate'] as String)
            : null,
        extractedMerchant: m['extractedMerchant'] as String?,
        rawOcrText: m['rawOcrText'] as String?,
      );
}
