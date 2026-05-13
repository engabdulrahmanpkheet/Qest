import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/app_localizations.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final biometric = ref.watch(biometricEnabledProvider);
    final calendar = ref.watch(calendarSyncEnabledProvider);
    final prefs = ref.watch(sharedPrefsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(l.appearance),
          ListTile(
            title: Text(l.themeSystem),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.system,
              groupValue: mode,
              onChanged: (v) => ref.read(themeModeProvider.notifier).set(v!),
            ),
          ),
          ListTile(
            title: Text(l.themeLight),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.light,
              groupValue: mode,
              onChanged: (v) => ref.read(themeModeProvider.notifier).set(v!),
            ),
          ),
          ListTile(
            title: Text(l.themeDark),
            trailing: Radio<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: mode,
              onChanged: (v) => ref.read(themeModeProvider.notifier).set(v!),
            ),
          ),

          _SectionHeader(l.language),
          RadioListTile<Locale?>(
            title: const Text('System'),
            value: null,
            groupValue: locale,
            onChanged: (v) => ref.read(localeProvider.notifier).set(v),
          ),
          RadioListTile<Locale?>(
            title: const Text('العربية'),
            value: const Locale('ar'),
            groupValue: locale,
            onChanged: (v) => ref.read(localeProvider.notifier).set(v),
          ),
          RadioListTile<Locale?>(
            title: const Text('English'),
            value: const Locale('en'),
            groupValue: locale,
            onChanged: (v) => ref.read(localeProvider.notifier).set(v),
          ),

          _SectionHeader(l.notifications),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: Text(l.notificationsHint),
          ),

          _SectionHeader(l.biometricLock),
          SwitchListTile(
            title: Text(l.biometricLock),
            value: biometric,
            onChanged: (v) async {
              await prefs.setBool(AppConstants.prefBiometric, v);
              ref.read(biometricEnabledProvider.notifier).state = v;
            },
          ),

          SwitchListTile(
            title: Text(l.calendarSync),
            value: calendar,
            onChanged: (v) async {
              await prefs.setBool(AppConstants.prefCalendarSync, v);
              ref.read(calendarSyncEnabledProvider.notifier).state = v;
              if (v) {
                await ref.read(calendarServiceProvider).ensurePermission();
              }
            },
          ),

          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: Text(l.exportBackup),
            onTap: () async {
              final f = await ref.read(backupServiceProvider).exportToJson();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(f.path)),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l.importBackup),
            onTap: () async {
              final n = await ref.read(backupServiceProvider).importFromJson();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$n imported')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
