import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

// Anatomy locked from reference image Tasks screen timeline:
// [time label LEFT] + [vertical line connector] + [icon circle] + [card RIGHT]
// Card: time range + title + metadata + checkbox trailing

class OrderTimelineItemWidget extends StatelessWidget {
  final String time;
  final String timeRange;
  final String orderId;
  final String customerName;
  final String village;
  final String plants;
  final int total;
  final int pending;
  final OrderStatus status;
  final String avatarUrl;
  final String avatarSemanticLabel;
  final bool isLast;
  final VoidCallback onTap;

  const OrderTimelineItemWidget({
    required this.time,
    required this.timeRange,
    required this.orderId,
    required this.customerName,
    required this.village,
    required this.plants,
    required this.total,
    required this.pending,
    required this.status,
    required this.avatarUrl,
    required this.avatarSemanticLabel,
    required this.isLast,
    required this.onTap,
    super.key,
  });

  Color _timelineIconColor() {
    switch (status) {
      case OrderStatus.paid:
        return AppTheme.success;
      case OrderStatus.delivered:
        return AppTheme.primary;
      case OrderStatus.confirmed:
        return AppTheme.info;
      case OrderStatus.cancelled:
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  IconData _timelineIcon() {
    switch (status) {
      case OrderStatus.paid:
        return Icons.check_circle_rounded;
      case OrderStatus.delivered:
        return Icons.local_shipping_rounded;
      case OrderStatus.confirmed:
        return Icons.thumb_up_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
      default:
        return Icons.pending_actions_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = _timelineIconColor();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT: time label column
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                time,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),

          // MIDDLE: vertical line + icon circle
          SizedBox(
            width: 40,
            child: Column(
              children: [
                const SizedBox(height: 4),
                // Icon circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(38),
                    shape: BoxShape.circle,
                    border: Border.all(color: iconColor, width: 1.5),
                  ),
                  child: Icon(_timelineIcon(), color: iconColor, size: 16),
                ),
                // Vertical connector line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            iconColor.withAlpha(102),
                            iconColor.withAlpha(13),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
          ),

          // RIGHT: order card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                splashColor: iconColor.withAlpha(20),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time range + status badge row
                      Row(
                        children: [
                          Text(
                            timeRange,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const Spacer(),
                          StatusBadgeWidget(status: status, compact: true),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Customer name + avatar row
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: iconColor.withAlpha(102),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: CustomImageWidget(
                                imageUrl: avatarUrl,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                semanticLabel: avatarSemanticLabel,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customerName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      village,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Trailing checkbox
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color:
                                  status == OrderStatus.paid ||
                                      status == OrderStatus.delivered
                                  ? iconColor.withAlpha(38)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    status == OrderStatus.paid ||
                                        status == OrderStatus.delivered
                                    ? iconColor
                                    : theme.colorScheme.outline,
                                width: 1.5,
                              ),
                            ),
                            child:
                                status == OrderStatus.paid ||
                                    status == OrderStatus.delivered
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: iconColor,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Plants info
                      Row(
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 12,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              plants,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Amount row
                      Row(
                        children: [
                          Text(
                            '₹$total',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          if (pending > 0) ...[
                            const SizedBox(width: 8),
                            Text(
                              '· ₹$pending due',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.warning,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            orderId,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
