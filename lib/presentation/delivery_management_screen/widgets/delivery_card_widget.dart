import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/firestore_repository.dart';
import '../../../theme/app_theme.dart';

class DeliveryCardWidget extends StatelessWidget {
  final Map<String, dynamic> delivery;
  final VoidCallback onStatusUpdate;
  final void Function(String deliveryId) onAssignOrders;

  const DeliveryCardWidget({
    required this.delivery,
    required this.onStatusUpdate,
    required this.onAssignOrders,
    super.key,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'in_transit':
        return AppTheme.info;
      case 'delivered':
        return AppTheme.success;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'in_transit':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = delivery['status'] as String? ?? 'pending';
    final orderIds = List<String>.from(delivery['orderIds'] as List? ?? []);
    final driverName = delivery['driverName'] as String? ?? 'Unassigned';
    final routeName = delivery['routeName'] as String? ?? 'No route';
    final vehicle = delivery['vehicle'] as String? ?? '';
    final lastLocation = delivery['lastLocation'] as Map<String, dynamic>?;
    final statusColor = _statusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withAlpha(60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _statusIcon(status),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        vehicle.isNotEmpty
                            ? '$routeName · $vehicle'
                            : routeName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withAlpha(80)),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _StatChip(
                  icon: Icons.receipt_long_rounded,
                  label: '${orderIds.length} Orders',
                  color: AppTheme.info,
                ),
                const SizedBox(width: 8),
                if (lastLocation != null)
                  _StatChip(
                    icon: Icons.location_on_rounded,
                    label: lastLocation['area'] as String? ?? 'En route',
                    color: AppTheme.primary,
                  ),
              ],
            ),
          ),

          // Real-time location indicator
          if (status == 'in_transit')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.info.withAlpha(12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.info.withAlpha(40)),
                ),
                child: Row(
                  children: [
                    _PulsingDot(color: AppTheme.info),
                    const SizedBox(width: 8),
                    Text(
                      lastLocation != null
                          ? 'Last seen: ${lastLocation['area'] ?? 'En route'}'
                          : 'Tracking active — awaiting location update',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.info,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Action buttons
          if (status != 'delivered' && status != 'cancelled')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => onAssignOrders(delivery['id'] as String),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Assign Orders'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide(color: AppTheme.primary.withAlpha(80)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatusActionButton(
                      currentStatus: status,
                      deliveryId: delivery['id'] as String,
                      onUpdated: onStatusUpdate,
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color.withOpacity(_anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _StatusActionButton extends StatelessWidget {
  final String currentStatus;
  final String deliveryId;
  final VoidCallback onUpdated;

  const _StatusActionButton({
    required this.currentStatus,
    required this.deliveryId,
    required this.onUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final isTransit = currentStatus == 'in_transit';
    final label = isTransit ? 'Mark Delivered' : 'Start Transit';
    final nextStatus = isTransit ? 'delivered' : 'in_transit';
    final color = isTransit ? AppTheme.success : AppTheme.info;

    return ElevatedButton.icon(
      onPressed: () async {
        try {
          await FirestoreRepository.instance.updateDeliveryStatus(
            deliveryId,
            nextStatus,
          );
          onUpdated();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  isTransit
                      ? 'Delivery marked as delivered!'
                      : 'Delivery started!',
                ),
                backgroundColor: color,
              ),
            );
          }
        } catch (_) {}
      },
      icon: Icon(
        isTransit ? Icons.check_rounded : Icons.play_arrow_rounded,
        size: 16,
      ),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    );
  }
}
