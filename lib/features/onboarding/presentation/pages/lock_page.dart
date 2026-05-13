import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers.dart';
import '../../../../l10n/app_localizations.dart';

class LockPage extends ConsumerStatefulWidget {
  const LockPage({super.key});
  @override
  ConsumerState<LockPage> createState() => _LockPageState();
}

class _LockPageState extends ConsumerState<LockPage> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l = AppLocalizations.of(context);
    final ok = await ref.read(biometricServiceProvider).authenticate(
          l.unlockReason,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 64),
            const SizedBox(height: 16),
            Text(l.unlockApp, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _busy ? null : _unlock,
              child: Text(l.unlockApp),
            ),
          ],
        ),
      ),
    );
  }
}
