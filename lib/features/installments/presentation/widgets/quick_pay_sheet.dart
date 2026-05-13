import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/utils/money.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/installment.dart';

/// One-tap confirmation surfaced from the dashboard tile via long-press.
/// Big "Paid" button, secondary "Open app". Haptic on present.
class QuickPaySheet {
  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    Installment i,
  ) async {
    HapticFeedback.mediumImpact();
    final l = AppLocalizations.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  i.title,
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMoney(i.amount),
                  style: Theme.of(ctx).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_rounded),
                  label: Text(l.yesPaid),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    HapticFeedback.lightImpact();
                    final next = await ref
                        .read(markPaidAndAdvanceProvider)
                        .call(i);
                    if (context.mounted) {
                      final msg = next == null
                          ? '${l.paid}: ${i.title}'
                          : '${l.paid} · ${l.recurring}';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(l.openPaymentApp),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(paymentLauncherProvider).launch(
                          i.paymentApp,
                          customUrl: i.customDeeplink,
                        );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
