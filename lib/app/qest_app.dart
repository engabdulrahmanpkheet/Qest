import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'notification_action_handler.dart';
import 'providers.dart';
import 'router.dart';

class QestApp extends ConsumerWidget {
  const QestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activate the notification-action handler subscription.
    ref.watch(notificationActionHandlerProvider);

    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        // Force RTL for Arabic regardless of platform direction quirks.
        final dir = Localizations.localeOf(context).languageCode == 'ar'
            ? TextDirection.rtl
            : TextDirection.ltr;
        return Directionality(textDirection: dir, child: child!);
      },
    );
  }
}
