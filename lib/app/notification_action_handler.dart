import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/services/notifications/notification_service.dart';
import '../features/installments/domain/entities/installment.dart';
import 'providers.dart';

/// Subscribes to the [NotificationService] event stream and applies the
/// behaviour configured for each action button:
///   - PAID  → mark paid + cancel future reminders + refresh widget.
///   - NOT_YET → no-op here; UI surfaces the bottom sheet on tap.
///   - OPEN_APP → launch the configured payment app.
class NotificationActionHandler {
  NotificationActionHandler(this._ref) {
    _sub = _ref
        .read(notificationServiceProvider)
        .events
        .listen(_onEvent);
  }

  final Ref _ref;
  late final StreamSubscription<NotificationEvent> _sub;

  void dispose() => _sub.cancel();

  Future<void> _onEvent(NotificationEvent e) async {
    final repo = _ref.read(installmentRepositoryProvider);
    final i = await repo.getByUuid(e.payload.installmentUuid);
    if (i == null) return;

    switch (e.actionId) {
      case AppConstants.actionPaid:
        await _markPaid(i);
        break;
      case AppConstants.actionOpenApp:
        await _ref.read(paymentLauncherProvider).launch(
              i.paymentApp,
              customUrl: i.customDeeplink,
            );
        break;
      case AppConstants.actionNotYet:
      default:
        // Tap (no action) → the UI router will navigate; we don't
        // mutate state here.
        break;
    }
  }

  Future<void> _markPaid(Installment i) async {
    final repo = _ref.read(installmentRepositoryProvider);
    await repo.markPaid(i.uuid);
    await _ref
        .read(notificationServiceProvider)
        .cancelForInstallment(i.uuid);
    await _ref.read(homeWidgetServiceProvider).refresh(repo);
  }
}

final notificationActionHandlerProvider =
    Provider<NotificationActionHandler>((ref) {
  final h = NotificationActionHandler(ref);
  ref.onDispose(h.dispose);
  return h;
});
