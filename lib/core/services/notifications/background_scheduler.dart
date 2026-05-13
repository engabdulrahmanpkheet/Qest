import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../../../features/installments/data/repositories/installment_repository_impl.dart';
import '../../constants/app_constants.dart';
import '../isar_service.dart';
import '../widgets/home_widget_service.dart';
import 'notification_service.dart';

/// Top-level dispatcher invoked by Workmanager in a background isolate.
///
/// On each periodic run we:
///   1. open Isar in this isolate,
///   2. (re)hydrate the notification ladder for unpaid installments,
///   3. roll forward recurring payments whose due date passed,
///   4. push fresh content to the home-screen widget.
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, _) async {
    try {
      final isar = await IsarService.init();
      await NotificationService.instance.init();

      final repo = InstallmentRepositoryImpl(isar);
      final all = await repo.getAll();
      for (final i in all) {
        if (i.isPaid) continue;
        await NotificationService.instance.scheduleForInstallment(i);
      }
      await HomeWidgetService.instance.refresh(repo);
      return true;
    } catch (e, st) {
      if (kDebugMode) debugPrint('bg task $task failed: $e\n$st');
      return false;
    }
  });
}

class BackgroundScheduler {
  BackgroundScheduler._();
  static final BackgroundScheduler instance = BackgroundScheduler._();

  Future<void> init() async {
    await Workmanager().initialize(
      backgroundDispatcher,
      isInDebugMode: false,
    );
    await Workmanager().registerPeriodicTask(
      AppConstants.taskScheduleReminders,
      AppConstants.taskScheduleReminders,
      frequency: const Duration(hours: 6),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(networkType: NetworkType.notRequired),
    );
  }
}
