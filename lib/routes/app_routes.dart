import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/manage_screen/manage_screen.dart';
import '../presentation/order_management_screen/order_management_screen.dart';
import '../presentation/payments_screen/payments_screen.dart';
import '../presentation/place_order_screen/place_order_screen.dart';
import '../presentation/reports_screen/reports_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/delivery_management_screen/delivery_management_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRoutes {
  static const String initial = '/';
  static const String loginScreen = '/login-screen';
  static const String dashboardScreen = '/dashboard-screen';
  static const String placeOrderScreen = '/place-order-screen';
  static const String manageScreen = '/manage-screen';
  static const String reportsScreen = '/reports-screen';
  static const String orderManagementScreen = '/order-management-screen';
  static const String paymentsScreen = '/payments-screen';
  static const String settingsScreen = '/settings-screen';
  static const String deliveryManagementScreen = '/delivery-management-screen';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  routes: [
    // Root route — redirects to login
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),

    // Auth screen — outside shell
    GoRoute(
      path: AppRoutes.loginScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),

    // Place Order — outside shell (full-screen form)
    GoRoute(
      path: AppRoutes.placeOrderScreen,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PlaceOrderScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // Shell — bottom navigation tabs
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffold(navigationShell: navigationShell),
      branches: [
        // Branch 0: Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboardScreen,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const DashboardScreen(),
              ),
            ),
          ],
        ),
        // Branch 1: Order Management
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.orderManagementScreen,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const OrderManagementScreen(),
              ),
            ),
          ],
        ),
        // Branch 2: Delivery Management
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.deliveryManagementScreen,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const DeliveryManagementScreen(),
              ),
            ),
          ],
        ),
        // Branch 3: Manage
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.manageScreen,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const ManageScreen(),
              ),
            ),
          ],
        ),
        // Branch 4: Reports
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.reportsScreen,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const ReportsScreen(),
              ),
            ),
          ],
        ),
        // Branch 5: Payments
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.paymentsScreen,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const PaymentsScreen(),
              ),
            ),
          ],
        ),
        // Branch 6: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settingsScreen,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: const SettingsScreen(),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
