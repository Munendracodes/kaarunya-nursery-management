import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

// Anatomy locked: icon + title + body text, full-width card
// Maps to AI Recommendation card from reference image Tasks screen

class OrderSummaryBannerWidget extends StatelessWidget {
  final int pendingCount;
  final int totalOrders;
  final int totalPending;

  const OrderSummaryBannerWidget({
    required this.pendingCount,
    required this.totalOrders,
    required this.totalPending,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPending = pendingCount > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasPending
            ? AppTheme.warningContainer
            : AppTheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasPending
              ? AppTheme.warning.withAlpha(102)
              : AppTheme.primary.withAlpha(77),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hasPending
                  ? AppTheme.warning.withAlpha(38)
                  : AppTheme.primary.withAlpha(38),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              hasPending
                  ? Icons.pending_actions_rounded
                  : Icons.check_circle_rounded,
              color: hasPending ? AppTheme.warning : AppTheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPending ? 'Action Required' : 'All Clear Today',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasPending ? AppTheme.warning : AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasPending
                      ? '$pendingCount of $totalOrders orders pending collection. ₹$totalPending outstanding — follow up today.'
                      : '$totalOrders orders scheduled today. All payments collected. Great work!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
