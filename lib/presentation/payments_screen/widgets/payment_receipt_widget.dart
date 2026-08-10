import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';

class PaymentReceiptWidget extends StatelessWidget {
  final Map<String, dynamic> receipt;

  const PaymentReceiptWidget({required this.receipt, super.key});

  static const Map<String, String> _methodLabels = {
    'cash': 'Cash',
    'upi': 'UPI',
    'bank_transfer': 'Bank Transfer',
    'cheque': 'Cheque',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = (receipt['amount'] as num?)?.toDouble() ?? 0;
    final paidAt = receipt['paidAt'] is DateTime
        ? receipt['paidAt'] as DateTime
        : DateTime.now();
    final method = receipt['paymentMode'] as String? ?? 'cash';
    final methodLabel = _methodLabels[method] ?? method;
    final receiptId = (receipt['id'] as String? ?? '')
        .substring(0, 8)
        .toUpperCase();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.primary,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Payment Recorded!',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Receipt #$receiptId',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Amount highlight
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Amount Paid',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Receipt details
                  _buildReceiptCard(theme, [
                    _ReceiptRow(
                      label: 'Customer',
                      value: receipt['customerName'] as String? ?? '-',
                      icon: Icons.person_rounded,
                    ),
                    _ReceiptRow(
                      label: 'Payment Method',
                      value: methodLabel,
                      icon: Icons.payment_rounded,
                    ),
                    _ReceiptRow(
                      label: 'Date & Time',
                      value: _formatDateTime(paidAt),
                      icon: Icons.calendar_today_rounded,
                    ),
                    _ReceiptRow(
                      label: 'Order Total',
                      value:
                          '₹${((receipt['orderTotal'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                      icon: Icons.receipt_long_rounded,
                    ),
                    _ReceiptRow(
                      label: 'Remaining Balance',
                      value:
                          '₹${((receipt['pendingAfter'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet_rounded,
                      valueColor:
                          ((receipt['pendingAfter'] as num?)?.toDouble() ?? 0) >
                              0
                          ? AppTheme.warning
                          : AppTheme.success,
                    ),
                    if ((receipt['notes'] as String? ?? '').isNotEmpty)
                      _ReceiptRow(
                        label: 'Notes',
                        value: receipt['notes'] as String,
                        icon: Icons.notes_rounded,
                      ),
                  ]),
                  const SizedBox(height: 20),

                  // Dashed divider (receipt style)
                  _DashedDivider(),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Kaarunya Nursery Management',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF9E9E9E),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: _buildReceiptText(
                                  receiptId,
                                  amount,
                                  methodLabel,
                                  paidAt,
                                  receipt,
                                ),
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Receipt copied to clipboard'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copy'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Close'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptCard(ThemeData theme, List<_ReceiptRow> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(row.icon, size: 16, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      row.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF757575),
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        row.value,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: row.valueColor,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }

  String _buildReceiptText(
    String id,
    double amount,
    String method,
    DateTime paidAt,
    Map<String, dynamic> receipt,
  ) {
    return '''
--- PAYMENT RECEIPT ---
Receipt #$id
Customer: ${receipt['customerName'] ?? '-'}
Amount: ₹${amount.toStringAsFixed(2)}
Method: $method
Date: ${_formatDateTime(paidAt)}
Order Total: ₹${((receipt['orderTotal'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}
Remaining: ₹${((receipt['pendingAfter'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}
-----------------------
Kaarunya Nursery Management
''';
  }
}

class _ReceiptRow {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _ReceiptRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });
}

class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final dashCount = (constraints.maxWidth / 10).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => Container(
              width: 6,
              height: 1.5,
              color: const Color(0xFFE0E0E0),
            ),
          ),
        );
      },
    );
  }
}
