import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

// Anatomy locked: icon + label + colored value + subtitle, 2-col grid
// D3 Informational: show all meaningful metrics

class DashboardKpiGridWidget extends StatelessWidget {
  final Map<String, dynamic> kpiData;
  final int columns;

  const DashboardKpiGridWidget({
    required this.kpiData,
    this.columns = 2,
    super.key,
  });

  String _formatCurrency(dynamic value) {
    final v = value is int ? value : (value as double).toInt();
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹$v';
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiItem(
        icon: Icons.receipt_long_rounded,
        label: 'Total Orders',
        value: '${kpiData['totalOrders']}',
        subtitle: 'All statuses',
        color: AppTheme.info,
        bgColor: const Color(0xFFE3F2FD),
      ),
      _KpiItem(
        icon: Icons.currency_rupee_rounded,
        label: 'Revenue',
        value: kpiData['revenue'] is int && kpiData['revenue'] > 1000
            ? _formatCurrency(kpiData['revenue'])
            : '₹${kpiData['revenue']}L',
        subtitle: 'Gross total',
        color: AppTheme.primary,
        bgColor: AppTheme.secondaryContainer,
        isAlert: false,
      ),
      _KpiItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Collected',
        value: _formatCurrency(kpiData['collected']),
        subtitle: 'Payments received',
        color: AppTheme.success,
        bgColor: AppTheme.secondaryContainer,
      ),
      _KpiItem(
        icon: Icons.pending_actions_rounded,
        label: 'Pending',
        value: _formatCurrency(kpiData['pending']),
        subtitle: 'Outstanding balance',
        color: AppTheme.warning,
        bgColor: AppTheme.warningContainer,
        isAlert: true,
      ),

    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 1.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        return _KpiCardWidget(item: cards[index], index: index);
      },
    );
  }
}

class _KpiItem {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final Color bgColor;
  final bool isAlert;

  const _KpiItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.bgColor,
    this.isAlert = false,
  });
}

class _KpiCardWidget extends StatefulWidget {
  final _KpiItem item;
  final int index;

  const _KpiCardWidget({required this.item, required this.index});

  @override
  State<_KpiCardWidget> createState() => _KpiCardWidgetState();
}

class _KpiCardWidgetState extends State<_KpiCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 50),
    );
    _scaleAnim = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: Opacity(opacity: _fadeAnim.value, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: widget.item.isAlert
              ? Border.all(color: widget.item.color.withAlpha(102), width: 1)
              : null,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.item.bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.item.icon,
                    color: widget.item.color,
                    size: 18,
                  ),
                ),
                const Spacer(),
                if (widget.item.isAlert)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: widget.item.color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  widget.item.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
