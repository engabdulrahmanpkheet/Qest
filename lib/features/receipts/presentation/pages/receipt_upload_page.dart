import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/providers.dart';
import '../../../../core/utils/money.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/receipt.dart';

class ReceiptUploadPage extends ConsumerStatefulWidget {
  const ReceiptUploadPage({super.key, required this.installmentUuid});
  final String installmentUuid;

  @override
  ConsumerState<ReceiptUploadPage> createState() =>
      _ReceiptUploadPageState();
}

class _ReceiptUploadPageState extends ConsumerState<ReceiptUploadPage> {
  bool _scanning = false;
  Receipt? _result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.uploadReceipt)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_scanning) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
              Text(l.scanning),
            ],
            if (_result != null) _ResultCard(receipt: _result!),
            const Spacer(),
            _PickRow(
              label: l.fromCamera,
              icon: Icons.photo_camera_outlined,
              onTap: () => _pick(_PickKind.camera),
            ),
            const SizedBox(height: 8),
            _PickRow(
              label: l.fromGallery,
              icon: Icons.photo_library_outlined,
              onTap: () => _pick(_PickKind.gallery),
            ),
            const SizedBox(height: 8),
            _PickRow(
              label: l.fromFiles,
              icon: Icons.picture_as_pdf_outlined,
              onTap: () => _pick(_PickKind.file),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _result == null ? null : _confirm,
              child: Text(l.markAsPaid),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(_PickKind kind) async {
    File? f;
    String mime = 'image';
    switch (kind) {
      case _PickKind.camera:
        final x = await ImagePicker().pickImage(source: ImageSource.camera);
        if (x != null) f = File(x.path);
        break;
      case _PickKind.gallery:
        final x = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (x != null) f = File(x.path);
        break;
      case _PickKind.file:
        final r = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        );
        if (r != null && r.files.single.path != null) {
          f = File(r.files.single.path!);
          mime = f.path.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image';
        }
        break;
    }
    if (f == null) return;

    setState(() => _scanning = true);
    final stored = await _persist(f);

    final ocr = mime == 'image'
        ? await ref.read(ocrServiceProvider).extract(stored)
        : null;

    setState(() {
      _scanning = false;
      _result = Receipt(
        uuid: const Uuid().v4(),
        installmentUuid: widget.installmentUuid,
        filePath: stored.path,
        mimeKind: mime,
        extractedAmount: ocr?.amount,
        extractedDate: ocr?.date,
        extractedMerchant: ocr?.merchant,
        rawOcrText: ocr?.rawText,
      );
    });
  }

  Future<File> _persist(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${dir.path}/receipts');
    if (!await receiptsDir.exists()) await receiptsDir.create(recursive: true);
    final ext = source.path.split('.').last;
    final dest = File(
      '${receiptsDir.path}/${DateTime.now().millisecondsSinceEpoch}.$ext',
    );
    return source.copy(dest.path);
  }

  Future<void> _confirm() async {
    final r = _result;
    if (r == null) return;
    final receiptRepo = ref.read(receiptRepositoryProvider);
    final iRepo = ref.read(installmentRepositoryProvider);
    // 1. Persist receipt + attach to the just-paid installment.
    await receiptRepo.upsert(r);
    await iRepo.attachReceipt(widget.installmentUuid, r.uuid);
    // 2. Mark paid + advance recurring (creates next month's row).
    final current = await iRepo.getByUuid(widget.installmentUuid);
    if (current != null) {
      await ref.read(markPaidAndAdvanceProvider).call(current);
    }
    if (mounted) context.pop();
  }
}

enum _PickKind { camera, gallery, file }

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.receipt});
  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (receipt.extractedMerchant != null)
            Text(
              receipt.extractedMerchant!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          if (receipt.extractedAmount != null)
            Text(
              formatMoney(receipt.extractedAmount!),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          if (receipt.extractedDate != null)
            Text(receipt.extractedDate!.toIso8601String().split('T').first),
        ],
      ),
    );
  }
}
