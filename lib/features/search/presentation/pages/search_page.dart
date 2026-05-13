import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dashboard/presentation/widgets/empty_state.dart';
import '../../../dashboard/presentation/widgets/installment_tile.dart';
import '../../../installments/domain/entities/installment.dart';

enum _Filter { all, upcoming, overdue, paid }

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  _Filter _filter = _Filter.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(Installment i) {
    final q = _query.toLowerCase().trim();
    final hits = q.isEmpty ||
        i.title.toLowerCase().contains(q) ||
        (i.notes ?? '').toLowerCase().contains(q);
    if (!hits) return false;
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.upcoming:
        return !i.isPaid && !i.isOverdue;
      case _Filter.overdue:
        return i.isOverdue;
      case _Filter.paid:
        return i.isPaid;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final all = ref.watch(allInstallmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l.search,
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip(l.all, _Filter.all),
                _chip(l.upcoming, _Filter.upcoming),
                _chip(l.overdue, _Filter.overdue),
                _chip(l.paid, _Filter.paid),
              ],
            ),
          ),
          Expanded(
            child: all.when(
              data: (items) {
                final filtered = items.where(_matches).toList();
                if (filtered.isEmpty) {
                  return EmptyState(emoji: '🔎', message: l.search);
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => InstallmentTile(
                    installment: filtered[i],
                    onTap: () => context
                        .push('/dashboard/detail/${filtered[i].uuid}'),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _Filter f) {
    final selected = _filter == f;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = f),
      ),
    );
  }
}
