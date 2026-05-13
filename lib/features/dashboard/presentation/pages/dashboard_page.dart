import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../core/utils/money.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/empty_state.dart';
import '../widgets/installment_tile.dart';
import '../widgets/summary_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final upcomingAsync = ref.watch(upcomingInstallmentsProvider);
    final overdueAsync = ref.watch(overdueInstallmentsProvider);
    final monthly = ref.watch(monthlyTotalProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/dashboard/add'),
        icon: const Icon(Icons.add),
        label: Text(l.addInstallment),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(upcomingInstallmentsProvider);
            ref.invalidate(overdueInstallmentsProvider);
            ref.invalidate(monthlyTotalProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.dashboardTitle,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.search_rounded),
                        onPressed: () => context.push('/dashboard/search'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () => context.push('/dashboard/settings'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    SummaryCard(
                      label: l.monthlyTotal,
                      value: formatMoney(monthly.value ?? 0.0),
                      icon: Icons.show_chart_rounded,
                    ),
                    SummaryCard(
                      label: l.overdue,
                      value: '${overdueAsync.value?.length ?? 0}',
                      icon: Icons.warning_amber_rounded,
                      tone: Theme.of(context).colorScheme.error,
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    l.overdue,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              _list(context, ref, overdueAsync, emptyEmoji: '✨', emptyText: l.noOverdue),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    l.upcoming,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              _list(context, ref, upcomingAsync, emptyEmoji: '🌤', emptyText: l.noUpcoming),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    WidgetRef ref,
    AsyncValue list, {
    required String emptyEmoji,
    required String emptyText,
  }) {
    return list.when(
      data: (items) {
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: EmptyState(emoji: emptyEmoji, message: emptyText),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => InstallmentTile(
              installment: items[i],
              onTap: () =>
                  context.push('/dashboard/detail/${items[i].uuid}'),
            ).animate().fadeIn(delay: (i * 30).ms).slideY(begin: 0.05),
          ),
        );
      },
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('$e'),
        ),
      ),
    );
  }
}
