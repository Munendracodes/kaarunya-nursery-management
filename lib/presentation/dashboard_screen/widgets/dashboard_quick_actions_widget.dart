import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class DashboardQuickActionsWidget extends StatelessWidget {
  final VoidCallback onAddOrder;
  final VoidCallback onCollectPayment;
  final VoidCallback onReports;
  final VoidCallback onManage;
  final bool vertical;

  const DashboardQuickActionsWidget({
    required this.onAddOrder,
    required this.onCollectPayment,
    required this.onReports,
    required this.onManage,
    this.vertical = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = [
      _ActionItem(
        icon: Icons.add_shopping_cart_rounded,
        label: 'Add Order',
        color: AppTheme.primary,
        bgColor: AppTheme.secondaryContainer,
        onTap: onAddOrder,
      ),
      _ActionItem(
        icon: Icons.payments_rounded,
        label: 'Collect Payment',
        color: const Color(0xFF1565C0),
        bgColor: const Color(0xFFE3F2FD),
        onTap: onCollectPayment,
      ),
      _ActionItem(
        icon: Icons.grid_view_rounded,
        label: 'Manage',
        color: const Color(0xFF00897B),
        bgColor: const Color(0xFFE0F2F1),
        onTap: onManage,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        vertical
            ? Column(
                children: actions
                    .map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildActionButton(a, context, full: true),
                      ),
                    )
                    .toList(),
              )
            : Row(
                children: actions
                    .map(
                      (a) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildActionButton(a, context),
                        ),
                      ),
                    )
                    .toList(),
              ),
      ],
    );
  }

  Widget _buildActionButton(
    _ActionItem item,
    BuildContext context, {
    bool full = false,
  }) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(14),
      splashColor: item.color.withAlpha(26),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: full ? 16 : 8, vertical: 12),
        decoration: BoxDecoration(
          color: item.bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: item.color.withAlpha(51), width: 1),
        ),
        child: full
            ? Row(
                children: [
                  Icon(item.icon, color: item.color, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: item.color,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, color: item.color, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: item.color,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}
