import 'package:flutter/material.dart';

import '../../../../core/utils/money.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../installments/domain/entities/installment.dart';

class InstallmentTile extends StatelessWidget {
  const InstallmentTile({
    super.key,
    required this.installment,
    this.onTap,
    this.onLongPress,
  });

  final Installment installment;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final days = installment.daysUntilDue();
    final overdue = installment.isOverdue;

    final relative = switch (days) {
      0 => l.today,
      1 => l.tomorrow,
      _ when days > 0 => l.inDays(days),
      _ => l.daysAgo(-days),
    };

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: overdue
              ? Border.all(color: scheme.error.withOpacity(0.4))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (overdue ? scheme.error : scheme.primary)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                installment.isPaid
                    ? Icons.check_rounded
                    : Icons.calendar_today_rounded,
                color: overdue ? scheme.error : scheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    installment.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    relative,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: overdue
                              ? scheme.error
                              : scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              formatMoney(installment.amount),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
