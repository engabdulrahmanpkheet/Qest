/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'Qest';
  static const String dbName = 'qest_db';

  // Notification channels.
  static const String channelReminders = 'qest_reminders';
  static const String channelDueDay = 'qest_due_day';
  static const String channelOverdue = 'qest_overdue';

  // Background task identifiers.
  static const String taskScheduleReminders = 'qest.scheduleReminders';
  static const String taskCheckOverdue = 'qest.checkOverdue';

  // Notification action ids.
  static const String actionPaid = 'ACTION_PAID';
  static const String actionNotYet = 'ACTION_NOT_YET';
  static const String actionOpenApp = 'ACTION_OPEN_APP';

  // Quiet-hours window (inclusive start, exclusive end).
  static const int quietHoursStart = 22; // 10 PM
  static const int quietHoursEnd = 10; // 10 AM

  // Reminder behaviour.
  static const int remindersDaysBeforeDue = 3;
  static const int remindersPerDay = 3;
  static const int snoozeDaysOnNoMoney = 2;

  // Home widget keys.
  static const String widgetNextTitle = 'next_title';
  static const String widgetNextAmount = 'next_amount';
  static const String widgetNextDue = 'next_due';
  static const String widgetOverdueCount = 'overdue_count';
  static const String widgetTodayCount = 'today_count';
  static const String widgetAndroidName = 'QestHomeWidgetProvider';
  static const String widgetIosName = 'QestHomeWidget';

  // Shared preferences keys.
  static const String prefThemeMode = 'theme_mode';
  static const String prefLocale = 'locale';
  static const String prefBiometric = 'biometric_lock';
  static const String prefOnboarded = 'onboarded';
  static const String prefCalendarSync = 'calendar_sync';
}
