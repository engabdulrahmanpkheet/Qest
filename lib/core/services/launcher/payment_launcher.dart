import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import '../../../features/installments/domain/entities/payment_app.dart';

/// Opens a payment app: prefer native scheme/package, fall back to web.
class PaymentLauncher {
  PaymentLauncher._();
  static final PaymentLauncher instance = PaymentLauncher._();

  Future<bool> launch(PaymentApp app, {String? customUrl}) async {
    if (app == PaymentApp.custom && customUrl != null && customUrl.isNotEmpty) {
      return _tryUrl(customUrl);
    }

    if (Platform.isAndroid && app.androidPackage != null) {
      final intent = Uri.parse('android-app://${app.androidPackage}');
      if (await canLaunchUrl(intent)) {
        if (await launchUrl(intent, mode: LaunchMode.externalApplication)) {
          return true;
        }
      }
      // Fall back to Play Store if app isn't installed.
      final play = Uri.parse('market://details?id=${app.androidPackage}');
      if (await canLaunchUrl(play)) {
        return launchUrl(play, mode: LaunchMode.externalApplication);
      }
    }

    if (Platform.isIOS && app.iosScheme != null) {
      final scheme = Uri.parse(app.iosScheme!);
      if (await canLaunchUrl(scheme)) {
        return launchUrl(scheme, mode: LaunchMode.externalApplication);
      }
    }

    if (app.webFallback != null) return _tryUrl(app.webFallback!);
    return false;
  }

  Future<bool> _tryUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
