import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import './widgets/insight_metric_row_widget.dart';
import './widgets/report_metric_card_widget.dart';
import './widgets/report_summary_card_widget.dart';

// TODO: Replace with Riverpod providers for production

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  final List<String> _periods = [
    'This Week',
    'This Month',
    'Last 3 Months',
    'This Year',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Complete overview of your business',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Reports',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: () {},
            tooltip: 'Export PDF',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {},
            tooltip: 'Share via WhatsApp',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: const Color(0xFF9E9E9E),
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Revenue'),
            Tab(text: 'Customers'),
            Tab(text: 'Plants'),
            Tab(text: 'Payments'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Period filter
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _periods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final p = _periods[i];
                  final isSelected = p == _selectedPeriod;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedPeriod = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _RevenueTab(period: _selectedPeriod),
                  _CustomersTab(period: _selectedPeriod),
                  _PlantsTab(period: _selectedPeriod),
                  _PaymentsTab(period: _selectedPeriod),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueTab extends StatelessWidget {
  final String period;

  const _RevenueTab({required this.period});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 2-col metric row (from reference image Insights screen)
          InsightMetricRowWidget(
            leftLabel: 'Total Revenue',
            leftValue: '₹5.3L',
            leftValueColor: AppTheme.primary,
            leftDelta: '+18% vs last month',
            leftDeltaPositive: true,
            rightLabel: 'Collection Rate',
            rightScore: 73,
            rightDelta: '+5 vs last month',
            rightDeltaPositive: true,
          ),
          const SizedBox(height: 16),

          // Full-width summary card with line chart
          ReportSummaryCardWidget(
            title: 'Revenue Trend',
            score: '₹5.3L',
            condition: 'Growing Steadily',
            delta:
                '+18% vs ${period == 'This Month' ? 'last month' : 'previous period'}',
            deltaPositive: true,
          ),
          const SizedBox(height: 16),

          // Metric detail cards (reference image Health detail style)
          ReportMetricCardWidget(
            icon: Icons.trending_up_rounded,
            iconBgColor: AppTheme.secondaryContainer,
            iconColor: AppTheme.primary,
            title: 'Daily Revenue',
            period: 'Last 7 days',
            bigValue: '₹17,640',
            chartType: 'bar',
            chartData: [12000, 18000, 9500, 21000, 16000, 24000, 17640],
          ),
          const SizedBox(height: 12),
          ReportMetricCardWidget(
            icon: Icons.pending_actions_rounded,
            iconBgColor: AppTheme.warningContainer,
            iconColor: AppTheme.warning,
            title: 'Pending Collections',
            period: 'Last 7 days',
            bigValue: '₹1.43L',
            chartType: 'bar',
            chartData: [180000, 165000, 172000, 158000, 149000, 143000, 143000],
            chartColor: AppTheme.warning,
          ),
          const SizedBox(height: 12),
          ReportMetricCardWidget(
            icon: Icons.receipt_long_rounded,
            iconBgColor: const Color(0xFFE3F2FD),
            iconColor: AppTheme.info,
            title: 'Order Volume',
            period: 'Last 7 days',
            bigValue: '189 orders',
            chartType: 'line',
            chartData: [22, 31, 18, 27, 34, 29, 28],
            chartColor: AppTheme.info,
          ),
        ],
      ),
    );
  }
}

class _CustomersTab extends StatelessWidget {
  final String period;
  const _CustomersTab({required this.period});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          InsightMetricRowWidget(
            leftLabel: 'Active Customers',
            leftValue: '142',
            leftValueColor: AppTheme.primary,
            leftDelta: '+8 new this month',
            leftDeltaPositive: true,
            rightLabel: 'Retention Rate',
            rightScore: 88,
            rightDelta: '+3 vs last month',
            rightDeltaPositive: true,
          ),
          const SizedBox(height: 16),
          ReportSummaryCardWidget(
            title: 'Customer Overview',
            score: '142',
            condition: 'Strong Retention',
            delta: '+8 new customers this month',
            deltaPositive: true,
          ),
          const SizedBox(height: 16),
          ReportMetricCardWidget(
            icon: Icons.person_add_rounded,
            iconBgColor: AppTheme.secondaryContainer,
            iconColor: AppTheme.primary,
            title: 'New Customers',
            period: 'Last 7 days',
            bigValue: '8 new',
            chartType: 'bar',
            chartData: [1, 2, 0, 3, 1, 0, 1],
          ),
          const SizedBox(height: 12),
          ReportMetricCardWidget(
            icon: Icons.warning_amber_rounded,
            iconBgColor: AppTheme.warningContainer,
            iconColor: AppTheme.warning,
            title: 'Customers with Pending',
            period: 'Current',
            bigValue: '67 customers',
            chartType: 'bar',
            chartData: [55, 62, 58, 70, 64, 67, 67],
            chartColor: AppTheme.warning,
          ),
        ],
      ),
    );
  }
}

class _PlantsTab extends StatelessWidget {
  final String period;
  const _PlantsTab({required this.period});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          InsightMetricRowWidget(
            leftLabel: 'Plants Sold',
            leftValue: '2,847',
            leftValueColor: AppTheme.primary,
            leftDelta: '+23% vs last month',
            leftDeltaPositive: true,
            rightLabel: 'Variety Coverage',
            rightScore: 76,
            rightDelta: '+4 new varieties',
            rightDeltaPositive: true,
          ),
          const SizedBox(height: 16),
          ReportSummaryCardWidget(
            title: 'Plant Sales Overview',
            score: '2,847',
            condition: 'Mango Leading',
            delta: '+23% volume growth this month',
            deltaPositive: true,
          ),
          const SizedBox(height: 16),
          ReportMetricCardWidget(
            icon: Icons.eco_rounded,
            iconBgColor: AppTheme.secondaryContainer,
            iconColor: AppTheme.primary,
            title: 'Top Plant: Mango',
            period: 'Last 7 days',
            bigValue: '847 units',
            chartType: 'bar',
            chartData: [110, 145, 98, 132, 120, 118, 124],
          ),
          const SizedBox(height: 12),
          ReportMetricCardWidget(
            icon: Icons.inventory_2_rounded,
            iconBgColor: AppTheme.warningContainer,
            iconColor: AppTheme.warning,
            title: 'Out of Stock',
            period: 'Current',
            bigValue: '3 varieties',
            chartType: 'bar',
            chartData: [1, 2, 1, 3, 2, 3, 3],
            chartColor: AppTheme.warning,
          ),
        ],
      ),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final String period;
  const _PaymentsTab({required this.period});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          InsightMetricRowWidget(
            leftLabel: 'Total Collected',
            leftValue: '₹3.87L',
            leftValueColor: AppTheme.success,
            leftDelta: '+12% vs last month',
            leftDeltaPositive: true,
            rightLabel: 'Recovery Rate',
            rightScore: 73,
            rightDelta: '+5 vs last month',
            rightDeltaPositive: true,
          ),
          const SizedBox(height: 16),
          ReportSummaryCardWidget(
            title: 'Payment Health',
            score: '₹3.87L',
            condition: 'Good Recovery',
            delta: '+12% collections this month',
            deltaPositive: true,
          ),
          const SizedBox(height: 16),
          ReportMetricCardWidget(
            icon: Icons.payments_rounded,
            iconBgColor: AppTheme.secondaryContainer,
            iconColor: AppTheme.primary,
            title: 'Daily Collections',
            period: 'Last 7 days',
            bigValue: '₹12,800',
            chartType: 'bar',
            chartData: [8000, 15000, 6000, 18000, 11000, 20000, 12800],
          ),
          const SizedBox(height: 12),
          ReportMetricCardWidget(
            icon: Icons.pending_outlined,
            iconBgColor: AppTheme.errorContainer,
            iconColor: AppTheme.error,
            title: 'Overdue > 30 days',
            period: 'Current',
            bigValue: '₹53K',
            chartType: 'line',
            chartData: [42000, 46000, 48000, 51000, 49000, 53000, 53000],
            chartColor: AppTheme.error,
          ),
        ],
      ),
    );
  }
}
