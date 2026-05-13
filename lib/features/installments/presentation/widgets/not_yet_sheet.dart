import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/installment.dart';

/// Bottom sheet asking *why* the user hasn't paid yet, with branched
/// behaviour (e.g. "no money" snoozes reminders for 2 days).
class NotYetSheet {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    Installment installment,
  ) async {
    final l = AppLocalizations.of(context);
    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final options = [
          ('no_money', l.reasonNoMoney),
          ('later_today', l.reasonLater),
          ('forgot', l.reasonForgot),
          ('app_issue', l.reasonAppIssue),
          ('other', l.reasonOther),
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.whyNotPaid,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                ...options.map((o) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(o.$2),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(ctx, o.$1),
                    )),
              ],
            ),
          ),
        );
      },
    );
    if (reason == null) return;

    final repo = ref.read(installmentRepositoryProvider);
    final notif = ref.read(notificationServiceProvider);

    if (reason == 'no_money') {
      await repo.snooze(
        installment.uuid,
        const Duration(days: AppConstants.snoozeDaysOnNoMoney),
      );
      final updated = await repo.getByUuid(installment.uuid);
      if (updated != null) {
        await notif.scheduleForInstallment(updated);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.snoozedTwoDays)),
        );
      }
    } else if (reason == 'later_today') {
      // Resurface this evening at 8pm if still unpaid.
      final now = DateTime.now();
      final later = DateTime(now.year, now.month, now.day, 20);
      await repo.snooze(
        installment.uuid,
        later.isAfter(now) ? later.difference(now) : const Duration(hours: 2),
      );
      final updated = await repo.getByUuid(installment.uuid);
      if (updated != null) await notif.scheduleForInstallment(updated);
    }
    // For "forgot", "app_issue", "other" — keep the schedule as-is so
    // the next reminder still fires.
  }
}
