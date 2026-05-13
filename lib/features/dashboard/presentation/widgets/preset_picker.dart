import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../installments/domain/entities/installment_preset.dart';

/// Eight one-tap presets surfaced in the dashboard empty state.
/// Tapping a chip opens the add flow with title / payment app prefilled.
class PresetPicker extends StatelessWidget {
  const PresetPicker({super.key, this.compact = false});

  /// When true, renders as a single horizontal strip (used above the FAB).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final presets = InstallmentPreset.defaults;

    if (compact) {
      return SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: presets.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => _chip(context, presets[i], locale),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Text(
            '✨',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 12),
          Text(
            l.noUpcoming,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < presets.length; i++)
                _chip(context, presets[i], locale)
                    .animate()
                    .fadeIn(delay: (i * 40).ms)
                    .scale(begin: const Offset(0.9, 0.9)),
            ],
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push('/dashboard/add'),
            label: Text(l.addInstallment),
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext ctx, InstallmentPreset p, String locale) {
    return ActionChip(
      avatar: Text(p.emoji, style: const TextStyle(fontSize: 16)),
      label: Text(p.titleFor(locale)),
      onPressed: () => ctx.push('/dashboard/add?preset=${p.id}'),
    );
  }
}
