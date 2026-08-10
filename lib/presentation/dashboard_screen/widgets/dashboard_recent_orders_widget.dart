import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';
import '../../../services/firestore_repository.dart';

class DashboardRecentOrdersWidget extends StatelessWidget {
  final VoidCallback onViewAll;

  const DashboardRecentOrdersWidget({required this.onViewAll, super.key});

  // Dummy orders shown when Firebase is unavailable.
  static const List<Map<String, dynamic>> _dummyOrders = [
    {
      'id': 'ORD-001',
      'customerName': 'Ravi Kumar',
      'villageName': 'Medchal',
      'itemCount': 4,
      'totalAmount': 3200,
      'pendingAmount': 1200,
      'status': 'confirmed',
    },
    {
      'id': 'ORD-002',
      'customerName': 'Lakshmi Devi',
      'villageName': 'Shamirpet',
      'itemCount': 2,
      'totalAmount': 1800,
      'pendingAmount': 0,
      'status': 'delivered',
    },
    {
      'id': 'ORD-003',
      'customerName': 'Suresh Reddy',
      'villageName': 'Ghatkesar',
      'itemCount': 6,
      'totalAmount': 5400,
      'pendingAmount': 2400,
      'status': 'pending',
    },
    {
      'id': 'ORD-004',
      'customerName': 'Anitha Rao',
      'villageName': 'Keesara',
      'itemCount': 3,
      'totalAmount': 2700,
      'pendingAmount': 0,
      'status': 'paid',
    },
    {
      'id': 'ORD-005',
      'customerName': 'Venkat Naidu',
      'villageName': 'Bibinagar',
      'itemCount': 5,
      'totalAmount': 4500,
      'pendingAmount': 1500,
      'status': 'purchased',
    },
  ];

  OrderStatus _statusFromString(String s) {
    switch (s) {
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'purchased':
        return OrderStatus.purchased;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'paid':
        return OrderStatus.paid;
      default:
        return OrderStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _safeRecentOrdersStream(),
      builder: (context, snapshot) {
        // Always show content — use dummy orders when Firebase has no data.
        final orders = (snapshot.data != null && snapshot.data!.isNotEmpty)
            ? snapshot.data!
            : _dummyOrders;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Recent Orders',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (snapshot.connectionState == ConnectionState.active &&
                        snapshot.hasData)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppTheme.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(orders.length, (i) {
              final order = orders[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OrderListItem(
                  order: order,
                  status: _statusFromString(
                    order['status'] as String? ?? 'pending',
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Stream<List<Map<String, dynamic>>> _safeRecentOrdersStream() async* {
    try {
      yield* FirestoreRepository.instance
          .watchRecentOrders(limit: 5)
          .handleError((_) {});
    } catch (_) {
      // Firebase not available — yield nothing; widget uses _dummyOrders.
    }
  }
}

class _OrderListItem extends StatelessWidget {
  final Map<String, dynamic> order;
  final OrderStatus status;

  const _OrderListItem({required this.order, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending = (order['pendingAmount'] as num?)?.toDouble() ?? 0.0;
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: pending > 0
            ? Border(left: BorderSide(color: AppTheme.warning, width: 3))
            : Border(left: BorderSide(color: AppTheme.success, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order['customerName'] as String? ?? '',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              StatusBadgeWidget(status: status, compact: true),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                order['villageName'] as String? ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.eco_outlined,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${order['itemCount'] ?? 0} item(s)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '₹${total.toStringAsFixed(0)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              if (pending > 0)
                Text(
                  '· ₹${pending.toStringAsFixed(0)} pending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.warning,
                  ),
                ),
              const Spacer(),
              Text(
                order['id'] as String? ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
