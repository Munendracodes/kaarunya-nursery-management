import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';

// Anatomy locked: full-width summary card
// title + BIG colored score + condition text + delta + wave line chart + 2 bottom stats

class ReportSummaryCardWidget extends StatelessWidget {
  final String title;
  final String score;
  final String condition;
  final String delta;
  final bool deltaPositive;

  const ReportSummaryCardWidget({
    required this.title,
    required this.score,
    required this.condition,
    required this.delta,
    required this.deltaPositive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Wave-like line chart data
    final spots = [
      FlSpot(0, 2.8),
      FlSpot(1, 3.5),
      FlSpot(2, 2.2),
      FlSpot(3, 4.1),
      FlSpot(4, 3.0),
      FlSpot(5, 4.8),
      FlSpot(6, 3.6),
      FlSpot(7, 5.1),
      FlSpot(8, 4.2),
      FlSpot(9, 5.5),
    ];
    final spots2 = [
      FlSpot(0, 1.5),
      FlSpot(1, 2.8),
      FlSpot(2, 1.8),
      FlSpot(3, 3.2),
      FlSpot(4, 2.4),
      FlSpot(5, 3.8),
      FlSpot(6, 2.9),
      FlSpot(7, 4.2),
      FlSpot(8, 3.5),
      FlSpot(9, 4.6),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      condition,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          deltaPositive
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 12,
                          color: deltaPositive
                              ? AppTheme.success
                              : AppTheme.error,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          delta,
                          style: TextStyle(
                            fontSize: 11,
                            color: deltaPositive
                                ? AppTheme.success
                                : AppTheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Wave line chart
          SizedBox(
            height: 80,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 9,
                minY: 0,
                maxY: 6,
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: AppTheme.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withAlpha(51),
                          AppTheme.primary.withAlpha(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  LineChartBarData(
                    spots: spots2,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: AppTheme.warning,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                    dashArray: [4, 4],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bottom stats row
          Row(
            children: [
              _BottomStat(
                label: 'Orders',
                value: '189',
                icon: Icons.receipt_long_rounded,
              ),
              const SizedBox(width: 16),
              _BottomStat(
                label: 'Recovery',
                value: '73%',
                icon: Icons.account_balance_wallet_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BottomStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
