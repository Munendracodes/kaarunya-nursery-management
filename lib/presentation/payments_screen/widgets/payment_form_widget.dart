import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_theme.dart';
import '../../../services/firestore_repository.dart';

class PaymentFormWidget extends StatefulWidget {
  final List<Map<String, dynamic>> orders;
  final void Function(Map<String, dynamic> receipt) onPaymentRecorded;

  const PaymentFormWidget({
    required this.orders,
    required this.onPaymentRecorded,
    super.key,
  });

  @override
  State<PaymentFormWidget> createState() => _PaymentFormWidgetState();
}

class _PaymentFormWidgetState extends State<PaymentFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  Map<String, dynamic>? _selectedOrder;
  String _paymentMethod = 'cash';
  bool _isSubmitting = false;
  String _searchQuery = '';

  static const List<Map<String, dynamic>> _paymentMethods = [
    {'value': 'cash', 'label': 'Cash', 'icon': Icons.payments_rounded},
    {'value': 'upi', 'label': 'UPI', 'icon': Icons.phone_android_rounded},
    {
      'value': 'bank_transfer',
      'label': 'Bank Transfer',
      'icon': Icons.account_balance_rounded,
    },
    {'value': 'cheque', 'label': 'Cheque', 'icon': Icons.receipt_rounded},
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    if (_searchQuery.isEmpty) return widget.orders;
    final q = _searchQuery.toLowerCase();
    return widget.orders.where((o) {
      final name = (o['customerName'] as String? ?? '').toLowerCase();
      final id = (o['id'] as String? ?? '').toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  double get _pendingAmount {
    if (_selectedOrder == null) return 0;
    return (_selectedOrder!['pendingAmount'] as num?)?.toDouble() ?? 0;
  }

  double get _totalAmount {
    if (_selectedOrder == null) return 0;
    return (_selectedOrder!['totalAmount'] as num?)?.toDouble() ?? 0;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _recordPayment() async {
    if (_selectedOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an order first'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final amount = double.parse(_amountController.text.trim());
      final paymentData = {
        'orderId': _selectedOrder!['id'],
        'customerId': _selectedOrder!['customerId'] ?? '',
        'customerName': _selectedOrder!['customerName'] ?? '',
        'amount': amount,
        'paymentMode': _paymentMethod,
        'notes': _notesController.text.trim(),
        'type': 'payment',
        'status': 'completed',
        'orderTotal': _totalAmount,
        'pendingBefore': _pendingAmount,
        'pendingAfter': (_pendingAmount - amount).clamp(0, double.infinity),
      };

      final paymentId = await FirestoreRepository.instance.recordPayment(
        paymentData,
        _selectedOrder!['id'] as String,
        amount,
      );

      final receipt = {
        ...paymentData,
        'id': paymentId,
        'paidAt': DateTime.now(),
      };

      if (mounted) {
        setState(() => _isSubmitting = false);
        _amountController.clear();
        _notesController.clear();
        setState(() {
          _selectedOrder = null;
          _paymentMethod = 'cash';
        });
        widget.onPaymentRecorded(receipt);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record payment: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Selection
            _SectionHeader(
              title: 'Select Order',
              icon: Icons.receipt_long_rounded,
            ),
            const SizedBox(height: 10),
            _buildOrderSearch(theme),
            const SizedBox(height: 8),
            if (_filteredOrders.isNotEmpty) _buildOrderList(theme),
            if (_selectedOrder != null) ...[
              const SizedBox(height: 16),
              _buildOrderSummaryCard(theme),
            ],
            const SizedBox(height: 20),

            // Amount Entry
            _SectionHeader(
              title: 'Payment Amount',
              icon: Icons.currency_rupee_rounded,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Amount (₹) *',
                hintText: _pendingAmount > 0
                    ? 'Pending: ₹${_pendingAmount.toStringAsFixed(2)}'
                    : 'Enter amount',
                prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
                suffixIcon: _pendingAmount > 0
                    ? TextButton(
                        onPressed: () {
                          _amountController.text = _pendingAmount
                              .toStringAsFixed(2);
                        },
                        child: Text(
                          'Full',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Payment amount is required';
                }
                final amt = double.tryParse(v.trim());
                if (amt == null) return 'Enter a valid numeric amount';
                if (amt <= 0) return 'Amount must be greater than zero';
                if (_selectedOrder != null &&
                    _pendingAmount > 0 &&
                    amt > _pendingAmount) {
                  return 'Amount (₹${amt.toStringAsFixed(2)}) exceeds pending ₹${_pendingAmount.toStringAsFixed(2)}';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Payment Method
            _SectionHeader(
              title: 'Payment Method',
              icon: Icons.payment_rounded,
            ),
            const SizedBox(height: 10),
            _buildPaymentMethodGrid(theme),
            const SizedBox(height: 20),

            // Notes
            _SectionHeader(
              title: 'Notes (Optional)',
              icon: Icons.notes_rounded,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Add any notes about this payment...',
                prefixIcon: Icon(Icons.notes_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _recordPayment,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded),
                label: Text(_isSubmitting ? 'Recording...' : 'Record Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSearch(ThemeData theme) {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Search by customer name or order ID...',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
      ),
    );
  }

  Widget _buildOrderList(ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _filteredOrders.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final order = _filteredOrders[i];
          final pending = (order['pendingAmount'] as num?)?.toDouble() ?? 0;
          final isSelected = _selectedOrder?['id'] == order['id'];

          return ListTile(
            dense: true,
            selected: isSelected,
            selectedTileColor: AppTheme.secondaryContainer,
            onTap: () {
              setState(() {
                _selectedOrder = order;
                _searchQuery = '';
                _searchController.clear();
              });
            },
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: isSelected
                  ? AppTheme.primary
                  : AppTheme.primaryContainer,
              child: Icon(
                Icons.receipt_rounded,
                size: 16,
                color: isSelected ? Colors.white : AppTheme.primary,
              ),
            ),
            title: Text(
              order['customerName'] as String? ?? 'Unknown',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Pending: ₹${pending.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: pending > 0 ? AppTheme.warning : AppTheme.success,
              ),
            ),
            trailing: pending > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warningContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${pending.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warning,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.success,
                    size: 18,
                  ),
          );
        },
      ),
    );
  }

  Widget _buildOrderSummaryCard(ThemeData theme) {
    final order = _selectedOrder!;
    final total = (order['totalAmount'] as num?)?.toDouble() ?? 0;
    final advance = (order['advanceAmount'] as num?)?.toDouble() ?? 0;
    final pending = (order['pendingAmount'] as num?)?.toDouble() ?? 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primaryContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_rounded,
                size: 16,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order['customerName'] as String? ?? '',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order['status'] as String? ?? 'pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _AmountChip(label: 'Total', amount: total, color: AppTheme.info),
              const SizedBox(width: 8),
              _AmountChip(
                label: 'Paid',
                amount: advance,
                color: AppTheme.success,
              ),
              const SizedBox(width: 8),
              _AmountChip(
                label: 'Pending',
                amount: pending,
                color: pending > 0 ? AppTheme.warning : AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodGrid(ThemeData theme) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.8,
      children: _paymentMethods.map((method) {
        final isSelected = _paymentMethod == method['value'];
        return GestureDetector(
          onTap: () =>
              setState(() => _paymentMethod = method['value'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primary : const Color(0xFFE0E0E0),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withAlpha(40),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  method['icon'] as IconData,
                  size: 18,
                  color: isSelected ? Colors.white : const Color(0xFF757575),
                ),
                const SizedBox(width: 8),
                Text(
                  method['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _AmountChip({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
