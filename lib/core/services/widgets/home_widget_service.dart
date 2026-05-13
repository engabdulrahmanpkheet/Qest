import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../../features/installments/domain/repositories/installment_repository.dart';
import '../../constants/app_constants.dart';

class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  /// Pushes the latest summary to the home-screen widget.
  /// Safe to call at any time; silently no-ops if widget unavailable.
  Future<void> refresh(InstallmentRepository repo) async {
    try {
      final upcoming = await repo.upcoming(withinDays: 60);
      final overdue = await repo.overdue();
      final today = await repo.dueOn(DateTime.now());
      final next = upcoming.isNotEmpty ? upcoming.first : null;

      await HomeWidget.saveWidgetData<String>(
        AppConstants.widgetNextTitle,
        next?.title ?? '',
      );
      await HomeWidget.saveWidgetData<String>(
        AppConstants.widgetNextAmount,
        next == null ? '' : next.amount.toStringAsFixed(2),
      );
      await HomeWidget.saveWidgetData<String>(
        AppConstants.widgetNextDue,
        next == null ? '' : DateFormat.yMMMd().format(next.dueDate),
      );
      await HomeWidget.saveWidgetData<int>(
        AppConstants.widgetOverdueCount,
        overdue.length,
      );
      await HomeWidget.saveWidgetData<int>(
        AppConstants.widgetTodayCount,
        today.length,
      );

      await HomeWidget.updateWidget(
        name: AppConstants.widgetAndroidName,
        iOSName: AppConstants.widgetIosName,
      );
    } catch (_) {
      // Widget integration is best-effort.
    }
  }
}
