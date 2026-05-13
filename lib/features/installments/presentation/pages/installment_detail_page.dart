import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/utils/money.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../receipts/domain/entities/receipt.dart';
import '../../domain/entities/installment.dart';
import '../widgets/not_yet_sheet.dart';

class InstallmentDetailPage extends ConsumerStatefulWidget {
  const InstallmentDetailPage({super.key, required this.uuid});
  final String uuid;
  @override
  ConsumerState<InstallmentDetailPage> createState() =>
      _InstallmentDetailPageState();
}

class _InstallmentDetailPageState extends ConsumerState<InstallmentDetailPage> {
  Installment? _i;
  List<Receipt> _receipts = const [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final repo = ref.read(installmentRepositoryProvider);
    final i = await repo.getByUuid(widget.uuid);
    final receipts = i == null
        ? <Receipt>[]
        : await ref
            .read(receiptRepositoryProvider)
            .forInstallment(widget.uuid);
    if (!mounted) return;
    setState(() {
      _i = i;
      _receipts = receipts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final i = _i;
    if (i == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(i.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () =>
                context.push('/dashboard/edit/${i.uuid}').then((_) => _refresh()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _AmountCard(installment: i),
          const SizedBox(height: 16),
          if (!i.isPaid) _ActionButtons(installment: i, onChange: _refresh),
          if (i.isPaid)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(l.paid),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (i.notes != null && i.notes!.isNotEmpty) ...[
            Text(l.notes,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 8),
            Text(i.notes!),
            const SizedBox(height: 24),
          ],
          Text(l.uploadReceipt,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context
                .push('/dashboard/detail/${i.uuid}/receipt')
                .then((_) => _refresh()),
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(l.uploadReceipt),
          ),
          const SizedBox(height: 12),
          ..._receipts.map((r) => ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(r.extractedMerchant ?? r.filePath.split('/').last),
                subtitle: Text(
                  [
                    if (r.extractedAmount != null)
                      formatMoney(r.extractedAmount!),
                    if (r.extractedDate != null)
                      r.extractedDate!.toIso8601String().split('T').first,
                  ].join(' · '),
                ),
              )),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.installment});
  final Installment installment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formatMoney(installment.amount),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            installment.dueDate.toIso8601String().split('T').first,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.installment, required this.onChange});
  final Installment installment;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.check_rounded),
            label: Text(l.yesPaid),
            onPressed: () async {
              await ref.read(markPaidAndAdvanceProvider).call(installment);
              onChange();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.access_time_rounded),
            label: Text(l.notYet),
            onPressed: () async {
              await NotYetSheet.show(context, ref, installment);
              onChange();
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          icon: const Icon(Icons.open_in_new_rounded),
          onPressed: () => ref.read(paymentLauncherProvider).launch(
                installment.paymentApp,
                customUrl: installment.customDeeplink,
              ),
        ),
      ],
    );
  }
}
