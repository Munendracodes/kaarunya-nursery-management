import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../theme/app_theme.dart';
import './payment_receipt_widget.dart';

class PaymentHistoryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> payments;
  final VoidCallback onRefresh;

  const PaymentHistoryWidget({
    required this.payments,
    required this.onRefresh,
    super.key,
  });

  static const Map<String, Map<String, dynamic>> _methodMeta = {
    'cash': {
      'label': 'Cash',
      'icon': Icons.payments_rounded,
      'color': Color(0xFF2E7D32),
    },
    'upi': {
      'label': 'UPI',
      'icon': Icons.phone_android_rounded,
      'color': Color(0xFF1565C0),
    },
    'bank_transfer': {
      'label': 'Bank',
      'icon': Icons.account_balance_rounded,
      'color': Color(0xFF6A1B9A),
    },
    'cheque': {
      'label': 'Cheque',
      'icon': Icons.receipt_rounded,
      'color': Color(0xFFF57F17),
    },
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payments_outlined,
              size: 64,
              color: AppTheme.primaryContainer,
            ),
            const SizedBox(height: 16),
            Text(
              'No payments recorded yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: const Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Record a payment from the first tab',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFBDBDBD),
              ),
            ),
          ],
        ),
      );
    }

    // Summary stats
    final totalCollected = payments.fold<double>(
      0,
      (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0),
    );

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppTheme.primary,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _buildSummaryBanner(theme, totalCollected),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, i) {
                final payment = payments[i];
                return _PaymentHistoryCard(
                  payment: payment,
                  methodMeta: _methodMeta,
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => PaymentReceiptWidget(
                      receipt: {
                        ...payment,
                        'paidAt': _parseDate(payment['paidAt']),
                      },
                    ),
                  ),
                );
              }, childCount: payments.length),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _parseDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    return DateTime.now();
  }

  Widget _buildSummaryBanner(ThemeData theme, double totalCollected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Collected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
              Text(
                '₹${totalCollected.toStringAsFixed(2)}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payments.length}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Transactions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentHistoryCard extends StatelessWidget {
  final Map<String, dynamic> payment;
  final Map<String, Map<String, dynamic>> methodMeta;
  final VoidCallback onTap;

  const _PaymentHistoryCard({
    required this.payment,
    required this.methodMeta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final method = payment['paymentMode'] as String? ?? 'cash';
    final meta = methodMeta[method] ?? methodMeta['cash']!;
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
    final paidAt = _parseDate(payment['paidAt']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0F0F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (meta['color'] as Color).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                meta['icon'] as IconData,
                color: meta['color'] as Color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment['customerName'] as String? ?? 'Unknown',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (meta['color'] as Color).withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          meta['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: meta['color'] as Color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(paidAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppTheme.success,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFFBDBDBD),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DateTime _parseDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    return DateTime.now();
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return 'Today ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
