import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/installment.dart';
import '../../domain/entities/installment_preset.dart';
import '../../domain/entities/payment_app.dart';
import '../../domain/entities/recurring_type.dart';

class AddEditInstallmentPage extends ConsumerStatefulWidget {
  const AddEditInstallmentPage({super.key, this.uuid, this.presetId});
  final String? uuid;
  final String? presetId;

  @override
  ConsumerState<AddEditInstallmentPage> createState() =>
      _AddEditInstallmentPageState();
}

class _AddEditInstallmentPageState
    extends ConsumerState<AddEditInstallmentPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  final _customDeeplink = TextEditingController();

  DateTime _due = DateTime.now().add(const Duration(days: 7));
  RecurringType _recurring = RecurringType.none;
  PaymentApp _app = PaymentApp.none;
  bool _loaded = false;
  Installment? _existing;

  @override
  void initState() {
    super.initState();
    if (widget.uuid != null) {
      Future.microtask(_load);
    } else {
      _applyPreset();
      _loaded = true;
    }
  }

  void _applyPreset() {
    final id = widget.presetId;
    if (id == null) return;
    final preset = InstallmentPreset.defaults.firstWhere(
      (p) => p.id == id,
      orElse: () => InstallmentPreset.defaults.first,
    );
    final locale =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    _title.text = preset.titleFor(locale);
    _recurring = preset.recurring;
    _app = preset.paymentApp;
  }

  Future<void> _load() async {
    final repo = ref.read(installmentRepositoryProvider);
    final i = await repo.getByUuid(widget.uuid!);
    if (i == null) return;
    setState(() {
      _existing = i;
      _title.text = i.title;
      _amount.text = i.amount.toStringAsFixed(2);
      _notes.text = i.notes ?? '';
      _customDeeplink.text = i.customDeeplink ?? '';
      _due = i.dueDate;
      _recurring = i.recurring;
      _app = i.paymentApp;
      _loaded = true;
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _notes.dispose();
    _customDeeplink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? l.addInstallment : l.edit),
        actions: [
          if (_existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextFormField(
              controller: _title,
              decoration: InputDecoration(labelText: l.title),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '—' : null,
              textInputAction: TextInputAction.next,
              autofocus: _existing == null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              decoration: InputDecoration(labelText: l.amount),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                return (n == null || n <= 0) ? '—' : null;
              },
            ),
            const SizedBox(height: 12),
            _DueDateField(
              value: _due,
              onChanged: (d) => setState(() => _due = d),
              label: l.dueDate,
            ),
            const SizedBox(height: 12),
            _DropdownField<RecurringType>(
              label: l.recurring,
              value: _recurring,
              items: RecurringType.values,
              labelOf: (r) => switch (r) {
                RecurringType.none => l.recurringNone,
                RecurringType.daily => l.recurringDaily,
                RecurringType.weekly => l.recurringWeekly,
                RecurringType.monthly => l.recurringMonthly,
                RecurringType.yearly => l.recurringYearly,
              },
              onChanged: (v) => setState(() => _recurring = v),
            ),
            const SizedBox(height: 12),
            _DropdownField<PaymentApp>(
              label: l.paymentApp,
              value: _app,
              items: PaymentApp.values,
              labelOf: (a) => a.label,
              onChanged: (v) => setState(() => _app = v),
            ),
            if (_app == PaymentApp.custom) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customDeeplink,
                decoration: const InputDecoration(
                  labelText: 'Deeplink (e.g. myapp://pay)',
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.notes),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: Text(l.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(installmentRepositoryProvider);
    final amount = double.parse(_amount.text.replaceAll(',', '.'));
    final i = Installment(
      uuid: _existing?.uuid ?? const Uuid().v4(),
      title: _title.text.trim(),
      amount: amount,
      dueDate: _due,
      originalDueDate: _existing?.originalDueDate ?? _due,
      recurring: _recurring,
      paymentApp: _app,
      customDeeplink: _customDeeplink.text.trim().isEmpty
          ? null
          : _customDeeplink.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      isPaid: _existing?.isPaid ?? false,
      paidAt: _existing?.paidAt,
      receiptIds: _existing?.receiptIds ?? const [],
      snoozedUntil: _existing?.snoozedUntil,
      calendarEventId: _existing?.calendarEventId,
      createdAt: _existing?.createdAt,
    );
    await repo.upsert(i);
    await ref.read(notificationServiceProvider).scheduleForInstallment(i);

    final calOn = ref.read(calendarSyncEnabledProvider);
    if (calOn) {
      final eventId = await ref.read(calendarServiceProvider).upsertEvent(i);
      if (eventId != null && eventId != i.calendarEventId) {
        await repo.upsert(i.copyWith(calendarEventId: eventId));
      }
    }
    await ref.read(homeWidgetServiceProvider).refresh(repo);

    if (mounted) context.pop();
  }

  Future<void> _confirmDelete() async {
    if (_existing == null) return;
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteConfirmTitle),
        content: Text(l.deleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final repo = ref.read(installmentRepositoryProvider);
    await ref
        .read(notificationServiceProvider)
        .cancelForInstallment(_existing!.uuid);
    if (_existing!.calendarEventId != null) {
      await ref.read(calendarServiceProvider).deleteEvent(_existing!);
    }
    await repo.delete(_existing!.uuid);
    await ref.read(homeWidgetServiceProvider).refresh(repo);
    if (mounted) context.pop();
  }
}

class _DueDateField extends StatelessWidget {
  const _DueDateField({
    required this.value,
    required this.onChanged,
    required this.label,
  });
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
        );
        if (picked != null) {
          final time = await showTimePicker(
            // ignore: use_build_context_synchronously
            context: context,
            initialTime: TimeOfDay.fromDateTime(value),
          );
          onChanged(DateTime(
            picked.year,
            picked.month,
            picked.day,
            time?.hour ?? 10,
            time?.minute ?? 0,
          ));
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}'
          '   ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(labelOf(e))))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
