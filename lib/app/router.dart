import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/installments/presentation/pages/add_edit_installment_page.dart';
import '../features/installments/presentation/pages/installment_detail_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/onboarding/presentation/pages/lock_page.dart';
import '../features/receipts/presentation/pages/receipt_upload_page.dart';
import '../features/search/presentation/pages/search_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import 'providers.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final hasOnboarded = ref.watch(hasOnboardedProvider);
  final biometricOn = ref.watch(biometricEnabledProvider);

  return GoRouter(
    initialLocation: hasOnboarded
        ? (biometricOn ? '/lock' : '/dashboard')
        : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/lock',
        builder: (_, __) => const LockPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardPage(),
        routes: [
          GoRoute(
            path: 'add',
            builder: (ctx, state) => AddEditInstallmentPage(
              presetId: state.uri.queryParameters['preset'],
            ),
          ),
          GoRoute(
            path: 'edit/:uuid',
            builder: (ctx, state) => AddEditInstallmentPage(
              uuid: state.pathParameters['uuid'],
            ),
          ),
          GoRoute(
            path: 'detail/:uuid',
            builder: (ctx, state) => InstallmentDetailPage(
              uuid: state.pathParameters['uuid']!,
            ),
          ),
          GoRoute(
            path: 'detail/:uuid/receipt',
            builder: (ctx, state) => ReceiptUploadPage(
              installmentUuid: state.pathParameters['uuid']!,
            ),
          ),
          GoRoute(
            path: 'search',
            builder: (_, __) => const SearchPage(),
          ),
          GoRoute(
            path: 'settings',
            builder: (_, __) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
