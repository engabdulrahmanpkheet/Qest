import 'payment_app.dart';
import 'recurring_type.dart';

/// A one-tap starting template for the add-installment flow. Title and
/// payment app are pre-filled; the user supplies the amount and date.
class InstallmentPreset {
  const InstallmentPreset({
    required this.id,
    required this.emoji,
    required this.titleEn,
    required this.titleAr,
    required this.paymentApp,
    required this.recurring,
  });

  final String id;
  final String emoji;
  final String titleEn;
  final String titleAr;
  final PaymentApp paymentApp;
  final RecurringType recurring;

  static const List<InstallmentPreset> defaults = [
    InstallmentPreset(
      id: 'rent',
      emoji: '🏠',
      titleEn: 'Rent',
      titleAr: 'الإيجار',
      paymentApp: PaymentApp.none,
      recurring: RecurringType.monthly,
    ),
    InstallmentPreset(
      id: 'valu',
      emoji: '💳',
      titleEn: 'valU installment',
      titleAr: 'قسط valU',
      paymentApp: PaymentApp.valu,
      recurring: RecurringType.monthly,
    ),
    InstallmentPreset(
      id: 'vodafone',
      emoji: '📱',
      titleEn: 'Vodafone bill',
      titleAr: 'فاتورة فودافون',
      paymentApp: PaymentApp.vodafoneCash,
      recurring: RecurringType.monthly,
    ),
    InstallmentPreset(
      id: 'electricity',
      emoji: '⚡',
      titleEn: 'Electricity',
      titleAr: 'فاتورة الكهرباء',
      paymentApp: PaymentApp.fawry,
      recurring: RecurringType.monthly,
    ),
    InstallmentPreset(
      id: 'gas',
      emoji: '🔥',
      titleEn: 'Gas',
      titleAr: 'فاتورة الغاز',
      paymentApp: PaymentApp.fawry,
      recurring: RecurringType.monthly,
    ),
    InstallmentPreset(
      id: 'internet',
      emoji: '🌐',
      titleEn: 'Internet',
      titleAr: 'فاتورة الإنترنت',
      paymentApp: PaymentApp.fawry,
      recurring: RecurringType.monthly,
    ),
    InstallmentPreset(
      id: 'netflix',
      emoji: '🎬',
      titleEn: 'Netflix',
      titleAr: 'Netflix',
      paymentApp: PaymentApp.none,
      recurring: RecurringType.monthly,
    ),
    InstallmentPreset(
      id: 'spotify',
      emoji: '🎧',
      titleEn: 'Spotify',
      titleAr: 'Spotify',
      paymentApp: PaymentApp.none,
      recurring: RecurringType.monthly,
    ),
  ];

  String titleFor(String localeCode) =>
      localeCode == 'ar' ? titleAr : titleEn;
}
