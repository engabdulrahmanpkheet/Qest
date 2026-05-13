import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../core/services/backup/backup_service.dart';
import '../core/services/biometric/biometric_service.dart';
import '../core/services/calendar/calendar_service.dart';
import '../core/services/isar_service.dart';
import '../core/services/launcher/payment_launcher.dart';
import '../core/services/notifications/notification_service.dart';
import '../core/services/ocr/ocr_service.dart';
import '../core/services/widgets/home_widget_service.dart';
import '../features/installments/data/repositories/installment_repository_impl.dart';
import '../features/installments/domain/entities/installment.dart';
import '../features/installments/domain/repositories/installment_repository.dart';
import '../features/receipts/data/repositories/receipt_repository_impl.dart';
import '../features/receipts/domain/repositories/receipt_repository.dart';

// ---- Singletons ----------------------------------------------------------

final isarServiceProvider = Provider<IsarService>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService.instance,
);

final ocrServiceProvider =
    Provider<OcrService>((ref) => OcrService.instance);

final paymentLauncherProvider =
    Provider<PaymentLauncher>((ref) => PaymentLauncher.instance);

final calendarServiceProvider =
    Provider<CalendarService>((ref) => CalendarService.instance);

final biometricServiceProvider =
    Provider<BiometricService>((ref) => BiometricService.instance);

final backupServiceProvider =
    Provider<BackupService>((ref) => BackupService.instance);

final homeWidgetServiceProvider =
    Provider<HomeWidgetService>((ref) => HomeWidgetService.instance);

// ---- Repositories --------------------------------------------------------

final installmentRepositoryProvider = Provider<InstallmentRepository>(
  (ref) => InstallmentRepositoryImpl(ref.watch(isarServiceProvider)),
);

final receiptRepositoryProvider = Provider<ReceiptRepository>(
  (ref) => ReceiptRepositoryImpl(ref.watch(isarServiceProvider)),
);

// ---- Streams / data ------------------------------------------------------

final allInstallmentsProvider = StreamProvider<List<Installment>>((ref) {
  return ref.watch(installmentRepositoryProvider).watchAll();
});

final upcomingInstallmentsProvider =
    FutureProvider<List<Installment>>((ref) async {
  ref.watch(allInstallmentsProvider);
  return ref.watch(installmentRepositoryProvider).upcoming();
});

final overdueInstallmentsProvider =
    FutureProvider<List<Installment>>((ref) async {
  ref.watch(allInstallmentsProvider);
  return ref.watch(installmentRepositoryProvider).overdue();
});

final monthlyTotalProvider = FutureProvider<double>((ref) async {
  ref.watch(allInstallmentsProvider);
  return ref.watch(installmentRepositoryProvider).monthlyTotal(DateTime.now());
});

// ---- Settings ------------------------------------------------------------

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_load(_prefs));
  final SharedPreferences _prefs;

  static ThemeMode _load(SharedPreferences p) {
    final v = p.getString(AppConstants.prefThemeMode);
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(AppConstants.prefThemeMode, mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPrefsProvider));
});

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._prefs) : super(_load(_prefs));
  final SharedPreferences _prefs;

  static Locale? _load(SharedPreferences p) {
    final v = p.getString(AppConstants.prefLocale);
    if (v == null) return null;
    return Locale(v);
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _prefs.remove(AppConstants.prefLocale);
    } else {
      await _prefs.setString(AppConstants.prefLocale, locale.languageCode);
    }
  }
}

final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref.watch(sharedPrefsProvider));
});

final biometricEnabledProvider = StateProvider<bool>((ref) {
  return ref
          .watch(sharedPrefsProvider)
          .getBool(AppConstants.prefBiometric) ??
      false;
});

final calendarSyncEnabledProvider = StateProvider<bool>((ref) {
  return ref
          .watch(sharedPrefsProvider)
          .getBool(AppConstants.prefCalendarSync) ??
      false;
});

final hasOnboardedProvider = StateProvider<bool>((ref) {
  return ref
          .watch(sharedPrefsProvider)
          .getBool(AppConstants.prefOnboarded) ??
      false;
});
