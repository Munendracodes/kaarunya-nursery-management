import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/firestore_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge_widget.dart';
import './widgets/assign_orders_sheet_widget.dart';
import './widgets/create_delivery_sheet_widget.dart';
import './widgets/delivery_card_widget.dart';

class DeliveryManagementScreen extends StatefulWidget {
  const DeliveryManagementScreen({super.key});

  @override
  State<DeliveryManagementScreen> createState() =>
      _DeliveryManagementScreenState();
}

class _DeliveryManagementScreenState extends State<DeliveryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _deliveries = [];
  List<Map<String, dynamic>> _unassignedOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final deliveries = await FirestoreRepository.instance.getDeliveries();
      final allOrders = await FirestoreRepository.instance.getRecentOrders(
        limit: 100,
      );
      final unassigned = allOrders
          .where(
            (o) =>
                (o['deliveryId'] == null ||
                    (o['deliveryId'] as String?) == '') &&
                o['status'] != 'delivered' &&
                o['status'] != 'cancelled',
          )
          .toList();
      if (mounted) {
        setState(() {
          _deliveries = deliveries;
          _unassignedOrders = unassigned;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _activeDeliveries => _deliveries
      .where((d) => d['status'] == 'in_transit' || d['status'] == 'pending')
      .toList();

  List<Map<String, dynamic>> get _completedDeliveries =>
      _deliveries.where((d) => d['status'] == 'delivered').toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Delivery Management',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(
              text: 'Active (${_activeDeliveries.length})',
              icon: const Icon(Icons.local_shipping_rounded, size: 18),
            ),
            Tab(
              text: 'Unassigned (${_unassignedOrders.length})',
              icon: const Icon(Icons.pending_actions_rounded, size: 18),
            ),
            Tab(
              text: 'Completed',
              icon: const Icon(Icons.check_circle_rounded, size: 18),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _ActiveDeliveriesTab(
                  deliveries: _activeDeliveries,
                  onRefresh: _loadData,
                ),
                _UnassignedOrdersTab(
                  orders: _unassignedOrders,
                  deliveries: _deliveries,
                  onRefresh: _loadData,
                ),
                _CompletedDeliveriesTab(deliveries: _completedDeliveries),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => CreateDeliverySheetWidget(onCreated: _loadData),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Delivery'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─── Active Deliveries Tab ─────────────────────────────────────────────────

class _ActiveDeliveriesTab extends StatelessWidget {
  final List<Map<String, dynamic>> deliveries;
  final VoidCallback onRefresh;

  const _ActiveDeliveriesTab({
    required this.deliveries,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (deliveries.isEmpty) {
      return _EmptyState(
        icon: Icons.local_shipping_outlined,
        message: 'No active deliveries',
        subtitle: 'Create a new delivery to get started',
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreRepository.instance.watchDeliveries(),
      builder: (context, snapshot) {
        final liveDeliveries =
            snapshot.data
                ?.where(
                  (d) =>
                      d['status'] == 'in_transit' || d['status'] == 'pending',
                )
                .toList() ??
            deliveries;

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: liveDeliveries.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DeliveryCardWidget(
                  delivery: liveDeliveries[index],
                  onStatusUpdate: onRefresh,
                  onAssignOrders: (deliveryId) async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AssignOrdersSheetWidget(
                        deliveryId: deliveryId,
                        onAssigned: onRefresh,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Unassigned Orders Tab ─────────────────────────────────────────────────

class _UnassignedOrdersTab extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> deliveries;
  final VoidCallback onRefresh;

  const _UnassignedOrdersTab({
    required this.orders,
    required this.deliveries,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (orders.isEmpty) {
      return _EmptyState(
        icon: Icons.check_circle_outline_rounded,
        message: 'All orders assigned',
        subtitle: 'No pending orders waiting for delivery',
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreRepository.instance.watchOrders(),
      builder: (context, snapshot) {
        final liveOrders =
            snapshot.data
                ?.where(
                  (o) =>
                      (o['deliveryId'] == null ||
                          (o['deliveryId'] as String?) == '') &&
                      o['status'] != 'delivered' &&
                      o['status'] != 'cancelled',
                )
                .toList() ??
            orders;

        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: liveOrders.length,
            itemBuilder: (context, index) {
              final order = liveOrders[index];
              final pending =
                  (order['pendingAmount'] as num?)?.toDouble() ?? 0.0;
              final total = (order['totalAmount'] as num?)?.toDouble() ?? 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border(
                    left: BorderSide(color: AppTheme.warning, width: 3),
                  ),
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
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        StatusBadgeWidget(
                          status: _statusFromString(
                            order['status'] as String? ?? 'pending',
                          ),
                          compact: true,
                        ),
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
                        Text(
                          '${order['itemCount'] ?? 0} item(s)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '₹${total.toStringAsFixed(0)}',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (pending > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '· ₹${pending.toStringAsFixed(0)} pending',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.warning,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (deliveries.isNotEmpty)
                          _QuickAssignButton(
                            orderId: order['id'] as String,
                            deliveries: deliveries
                                .where(
                                  (d) =>
                                      d['status'] == 'pending' ||
                                      d['status'] == 'in_transit',
                                )
                                .toList(),
                            onAssigned: onRefresh,
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

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
}

class _QuickAssignButton extends StatelessWidget {
  final String orderId;
  final List<Map<String, dynamic>> deliveries;
  final VoidCallback onAssigned;

  const _QuickAssignButton({
    required this.orderId,
    required this.deliveries,
    required this.onAssigned,
  });

  @override
  Widget build(BuildContext context) {
    if (deliveries.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      onSelected: (deliveryId) async {
        try {
          await FirestoreRepository.instance.assignOrderToDelivery(
            orderId,
            deliveryId,
          );
          onAssigned();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Order assigned to delivery'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (_) {}
      },
      itemBuilder: (_) => deliveries
          .map(
            (d) => PopupMenuItem<String>(
              value: d['id'] as String,
              child: Text(
                d['driverName'] as String? ?? 'Delivery ${d['id']}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primary.withAlpha(80)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 14, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              'Assign',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Completed Deliveries Tab ──────────────────────────────────────────────

class _CompletedDeliveriesTab extends StatelessWidget {
  final List<Map<String, dynamic>> deliveries;

  const _CompletedDeliveriesTab({required this.deliveries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (deliveries.isEmpty) {
      return _EmptyState(
        icon: Icons.history_rounded,
        message: 'No completed deliveries',
        subtitle: 'Completed deliveries will appear here',
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirestoreRepository.instance.watchDeliveries(),
      builder: (context, snapshot) {
        final completed =
            snapshot.data?.where((d) => d['status'] == 'delivered').toList() ??
            deliveries;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: completed.length,
          itemBuilder: (context, index) {
            final d = completed[index];
            final orderIds = List<String>.from(d['orderIds'] as List? ?? []);
            final deliveredAt = d['deliveredAt'];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border(
                  left: BorderSide(color: AppTheme.success, width: 3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.success,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['driverName'] as String? ?? 'Driver',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${orderIds.length} order(s) · ${d['routeName'] ?? 'Route'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (deliveredAt != null)
                    Text(
                      'Delivered',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppTheme.primaryLight),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
