import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/app_localizations.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});
  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pc = PageController();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pages = [
      _Slide(
        emoji: '🌿',
        title: l.onboardingTitle1,
        body: l.onboardingBody1,
      ),
      _Slide(
        emoji: '🔔',
        title: l.onboardingTitle2,
        body: l.onboardingBody2,
      ),
      _Slide(
        emoji: '🧾',
        title: l.onboardingTitle3,
        body: l.onboardingBody3,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: TextButton(
                onPressed: _finish,
                child: Text(l.skip),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (i) => setState(() => _index = i),
                children: pages,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: ElevatedButton(
                onPressed: () {
                  if (_index == pages.length - 1) {
                    _finish();
                  } else {
                    _pc.nextPage(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Text(
                  _index == pages.length - 1 ? l.getStarted : l.next,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(AppConstants.prefOnboarded, true);
    ref.read(hasOnboardedProvider.notifier).state = true;
    if (mounted) context.go('/dashboard');
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.emoji, required this.title, required this.body});
  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 88))
              .animate()
              .fadeIn(duration: 350.ms)
              .scale(begin: const Offset(0.85, 0.85)),
          const SizedBox(height: 32),
          Text(
            title,
            style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          Text(
            body,
            style: t.bodyLarge?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}
