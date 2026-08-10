import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_repository.dart';
import './widgets/dashboard_app_bar_widget.dart';
import './widgets/dashboard_filter_chips_widget.dart';
import './widgets/dashboard_hero_widget.dart';
import './widgets/dashboard_kpi_grid_widget.dart';
import './widgets/dashboard_quick_actions_widget.dart';
import './widgets/dashboard_recent_orders_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedFilter = 'Today';
  final List<String> _filters = [
    'Today',
    'This Week',
    'This Month',
    'All Time',
  ];

  // Dummy KPI data used when Firebase is unavailable.
  static const Map<String, dynamic> _dummyKpi = {
    'totalOrders': 24,
    'revenue': 87500,
    'collected': 62000,
    'pending': 25500,

  };

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.placeOrderScreen),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Order'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _safeStatsStream(),
      builder: (context, snapshot) {
        // Use dummy data immediately — never show a blank/loading screen.
        final kpiData = snapshot.data ?? _dummyKpi;

        return CustomScrollView(
          slivers: [
            DashboardAppBarWidget(onNotificationTap: () {}, onAvatarTap: () {}),


            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: DashboardKpiGridWidget(kpiData: kpiData),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: DashboardQuickActionsWidget(
                  onAddOrder: () => context.push(AppRoutes.placeOrderScreen),
                  onCollectPayment: () {},
                  onReports: () => context.go(AppRoutes.reportsScreen),
                  onManage: () => context.go(AppRoutes.manageScreen),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                child: DashboardRecentOrdersWidget(
                  onViewAll: () => context.go(AppRoutes.orderManagementScreen),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabletLayout() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _safeStatsStream(),
      builder: (context, snapshot) {
        final kpiData = snapshot.data ?? _dummyKpi;

        return Row(
          children: [
            Expanded(
              flex: 6,
              child: CustomScrollView(
                slivers: [
                  DashboardAppBarWidget(
                    onNotificationTap: () {},
                    onAvatarTap: () {},
                  ),
                  SliverToBoxAdapter(
                    child: DashboardFilterChipsWidget(
                      filters: _filters,
                      selected: _selectedFilter,
                      onSelected: (f) => setState(() => _selectedFilter = f),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: DashboardHeroWidget(
                        score: kpiData['healthScore'] as int,
                        label: kpiData['healthLabel'] as String,
                        filter: _selectedFilter,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
                      child: DashboardRecentOrdersWidget(
                        onViewAll: () =>
                            context.go(AppRoutes.orderManagementScreen),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 320,
              padding: const EdgeInsets.fromLTRB(0, 24, 20, 24),
              child: Column(
                children: [
                  DashboardKpiGridWidget(kpiData: kpiData, columns: 2),
                  const SizedBox(height: 16),
                  DashboardQuickActionsWidget(
                    onAddOrder: () => context.push(AppRoutes.placeOrderScreen),
                    onCollectPayment: () {},
                    onReports: () => context.go(AppRoutes.reportsScreen),
                    onManage: () => context.go(AppRoutes.manageScreen),
                    vertical: true,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Returns the Firestore stats stream, but catches any errors so the
  /// StreamBuilder always falls back to [_dummyKpi] instead of hanging.
  Stream<Map<String, dynamic>> _safeStatsStream() async* {
    try {
      yield* FirestoreRepository.instance
          .watchDashboardStats(_selectedFilter)
          .handleError((_) {});
    } catch (_) {
      // Firebase not available — yield nothing; StreamBuilder uses _dummyKpi.
    }
  }
}
