import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/firebase_service.dart';
import '../../../theme/app_theme.dart';

class ViewOrderScreen extends StatefulWidget {
  final Map<String, dynamic> order;



  const ViewOrderScreen({
    super.key,
    required this.order,
  });

  @override
  State<ViewOrderScreen> createState() =>
      _ViewOrderScreenState();
}

class _ViewOrderScreenState
    extends State<ViewOrderScreen> {
  // ============================================================
  // SERVICES
  // ============================================================

  final FirebaseService _firebase =
      FirebaseService.instance;

  // ============================================================
  // STATE
  // ============================================================

  late Map<String, dynamic> _order;

  bool _isUpdating = false;

  // Customer details are collapsed by default.
  bool _showCustomerDetails = false;

  // Payment details are collapsed by default.
  bool _showPaymentDetails = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _order = Map<String, dynamic>.from(
      widget.order,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _toDouble(
      dynamic value,
      ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    ) ??
        0;
  }

  int _toInt(
      dynamic value,
      ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString().trim(),
    ) ??
        0;
  }

  String _string(
      dynamic value,
      ) {
    return value?.toString().trim() ?? '';
  }

  // ============================================================
  // ORDER ID
  // ============================================================

  String get _orderId {
    return _string(
      _order['id'],
    );
  }

  // ============================================================
  // ORDER NUMBER
  // ============================================================

  String get _orderNumber {
    final value = _string(
      _order['orderNumber'],
    );

    if (value.isNotEmpty) {
      return value;
    }

    return _orderId.isNotEmpty
        ? _orderId
        : 'Order';
  }

  // ============================================================
  // CUSTOMER
  // ============================================================

  String get _customerName {
    final value = _string(
      _order['customerName'],
    );

    return value.isEmpty
        ? 'Unknown Customer'
        : value;
  }

  String get _fatherName {
    return _string(
      _order['customerFatherName'],
    );
  }

  String get _mobile {
    return _string(
      _order['customerMobile'],
    );
  }

  String get _village {
    return _string(
      _order['customerVillage'],
    );
  }

  // ============================================================
  // AMOUNTS
  // ============================================================

  double get _total {
    return _toDouble(
      _order['total'],
    );
  }

  double get _totalPaid {
    return _toDouble(
      _order['totalPaid'],
    );
  }

  double get _balance {
    final firebaseBalance =
    _order['balance'];

    if (firebaseBalance != null) {
      final parsed =
      double.tryParse(
        firebaseBalance.toString(),
      );

      if (parsed != null) {
        return parsed < 0
            ? 0
            : parsed;
      }
    }

    final calculated =
        _total - _totalPaid;

    return calculated < 0
        ? 0
        : calculated;
  }

  // ============================================================
  // STATUS
  // ============================================================

  String get _status {
    final value = _string(
      _order['orderStatus'],
    );

    if (value.isNotEmpty) {
      return value;
    }

    // Backward compatibility.
    final oldStatus = _string(
      _order['status'],
    );

    return oldStatus.isEmpty
        ? 'Pending'
        : oldStatus;
  }

  String get _paymentStatus {
    final value = _string(
      _order['paymentStatus'],
    );

    if (value.isNotEmpty) {
      return value;
    }

    if (_balance <= 0) {
      return 'Paid';
    }

    if (_totalPaid > 0) {
      return 'Partially Paid';
    }

    return 'Pending';
  }

  // ============================================================
  // ITEMS
  // ============================================================

  List<Map<String, dynamic>> get _items {
    final raw = _order['items'];

    if (raw == null) {
      return [];
    }

    if (raw is List) {
      return raw
          .where(
            (item) => item is Map,
      )
          .map(
            (item) =>
        Map<String, dynamic>.from(
          Map<dynamic, dynamic>.from(
            item as Map,
          ),
        ),
      )
          .toList();
    }

    if (raw is Map) {
      return raw.entries
          .map(
            (entry) {
          final value =
              entry.value;

          if (value is Map) {
            return {
              'id':
              entry.key.toString(),
              ...Map<String, dynamic>.from(
                Map<dynamic, dynamic>.from(
                  value,
                ),
              ),
            };
          }

          return <String, dynamic>{
            'id':
            entry.key.toString(),
          };
        },
      )
          .toList();
    }

    return [];
  }

  // ============================================================
  // ORDER DATE
  // ============================================================

  DateTime? _orderDateValue() {
    dynamic value =
    _order['createdAt'];

    value ??= _order['orderDate'];

    if (value == null) {
      return null;
    }

    if (value is num) {
      return DateTime
          .fromMillisecondsSinceEpoch(
        value.toInt(),
      );
    }

    final numeric =
    int.tryParse(
      value.toString(),
    );

    if (numeric != null) {
      return DateTime
          .fromMillisecondsSinceEpoch(
        numeric,
      );
    }

    try {
      return DateTime.parse(
        value.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  String get _orderDate {
    final date =
    _orderDateValue();

    if (date == null) {
      return '-';
    }

    return _formatDate(date);
  }

  // ============================================================
  // GENERIC DATE FORMATTER
  // ============================================================

  String _formatDate(
      DateTime date,
      ) {
    final day =
    date.day.toString().padLeft(
      2,
      '0',
    );

    final month =
    date.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${date.year}';
  }

  // ============================================================
  // PAYMENT HISTORY
  // ============================================================

  List<Map<String, dynamic>>
  get _payments {
    final raw =
    _order['payments'];

    if (raw == null) {
      return _legacyPaymentList();
    }

    if (raw is List) {
      return raw
          .where(
            (payment) =>
        payment is Map,
      )
          .map(
            (payment) =>
        Map<String, dynamic>.from(
          Map<dynamic, dynamic>.from(
            payment as Map,
          ),
        ),
      )
          .toList()
          .reversed
          .toList();
    }

    if (raw is Map) {
      return raw.entries
          .map(
            (entry) {
          final value =
              entry.value;

          if (value is Map) {
            return {
              'id':
              entry.key.toString(),
              ...Map<String, dynamic>.from(
                Map<dynamic, dynamic>.from(
                  value,
                ),
              ),
            };
          }

          return <String, dynamic>{
            'id':
            entry.key.toString(),
          };
        },
      )
          .toList()
          .reversed
          .toList();
    }

    return _legacyPaymentList();
  }

  // ============================================================
  // BACKWARD COMPATIBILITY
  //
  // Older orders only contain:
  // lastPaymentAmount
  // lastPaymentMethod
  // lastPaymentAt
  //
  // Show that as one payment until the order starts
  // using the new payments list.
  // ============================================================

  List<Map<String, dynamic>>
  _legacyPaymentList() {
    final amount =
    _toDouble(
      _order['lastPaymentAmount'],
    );

    if (amount <= 0) {
      return [];
    }

    return [
      {
        'amount': amount,
        'method': _string(
          _order['lastPaymentMethod'],
        ),
        'date': _order[
        'lastPaymentAt'
        ],
      },
    ];
  }

  // ============================================================
  // PAYMENT DATE
  // ============================================================

  DateTime? _paymentDate(
      Map<String, dynamic> payment,
      ) {
    dynamic value =
    payment['date'];

    value ??=
    payment['paymentDate'];

    value ??=
    payment['createdAt'];

    value ??=
    payment['paidAt'];

    if (value == null) {
      return null;
    }

    if (value is num) {
      return DateTime
          .fromMillisecondsSinceEpoch(
        value.toInt(),
      );
    }

    final numeric =
    int.tryParse(
      value.toString(),
    );

    if (numeric != null) {
      return DateTime
          .fromMillisecondsSinceEpoch(
        numeric,
      );
    }

    try {
      return DateTime.parse(
        value.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // UPDATE FIREBASE
  // ============================================================

  Future<void> _updateOrder(
      Map<String, dynamic> updates,
      ) async {
    if (_orderId.isEmpty) {
      _showError(
        'Order ID is missing.',
      );
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final orderRef =
      _firebase.ordersRef.child(
        _orderId,
      );

      await orderRef.update(
        updates,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _order = {
          ..._order,
          ...updates,
        };

        _isUpdating = false;
      });

      _showSuccess(
        'Order updated successfully.',
      );
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdating = false;
      });

      _showError(
        'Firebase error: '
            '${e.message ?? e.code}',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdating = false;
      });

      _showError(
        'Unable to update order: $e',
      );
    }
  }

  // ============================================================
  // MARK DELIVERED
  // ============================================================

  Future<void> _markDelivered() async {
    if (_status.toLowerCase() ==
        'closed') {
      _showError(
        'Closed orders cannot be changed.',
      );
      return;
    }

    if (_status.toLowerCase() ==
        'delivered') {
      _showError(
        'Order is already delivered.',
      );
      return;
    }

    final confirmed =
    await _showConfirmationDialog(
      title:
      'Mark Order as Delivered?',
      message:
      'This will change the order status to Delivered.',
      confirmText:
      'Mark Delivered',
    );

    if (confirmed != true) {
      return;
    }

    await _updateOrder({
      'orderStatus':
      'Delivered',
      'status':
      'Delivered',
      'updatedAt':
      ServerValue.timestamp,
      'deliveredAt':
      ServerValue.timestamp,
    });
  }

  // ============================================================
  // ADD PAYMENT
  // ============================================================

  Future<void> _addPayment() async {
    if (_balance <= 0) {
      _showError(
        'This order is already fully paid.',
      );
      return;
    }

    if (_status.toLowerCase() ==
        'closed') {
      _showError(
        'Closed orders cannot be updated.',
      );
      return;
    }

    final result =
    await showDialog<
        _PaymentResult>(
      context: context,
      builder: (_) =>
          _PaymentDialog(
            total:
            _total,
            alreadyPaid:
            _totalPaid,
            balance:
            _balance,
          ),
    );

    if (result == null) {
      return;
    }

    final paymentAmount =
        result.amount;

    if (paymentAmount <= 0) {
      return;
    }

    if (paymentAmount >
        _balance) {
      _showError(
        'Payment cannot exceed '
            'the remaining balance.',
      );
      return;
    }

    final newPaid =
        _totalPaid +
            paymentAmount;

    final newBalance =
        _total -
            newPaid;

    final fullyPaid =
        newBalance <= 0.01;

    String newOrderStatus =
        _status;

    if (fullyPaid) {
      newOrderStatus =
      'Closed';
    }

    // ==========================================================
    // PAYMENT HISTORY
    // ==========================================================

    final paymentId =
    DateTime.now()
        .millisecondsSinceEpoch
        .toString();

    final payment =
    <String, dynamic>{
      'id': paymentId,
      'amount': paymentAmount,
      'method': result.method,
      'date':
      ServerValue.timestamp,
    };

    // Keep existing payment history.
    final existingPayments =
    _payments
        .map(
          (payment) =>
      Map<String, dynamic>.from(
        payment,
      ),
    )
        .toList();

    // Remove legacy timestamp-only field if present.
    // New payments will use the payments list.
    existingPayments.add(
      payment,
    );

    final updates =
    <String, dynamic>{
      'totalPaid':
      newPaid,
      'balance':
      fullyPaid
          ? 0
          : newBalance,
      'paymentStatus':
      fullyPaid
          ? 'Paid'
          : 'Partially Paid',

      // Latest payment information
      // retained for backward compatibility.
      'lastPaymentAmount':
      paymentAmount,
      'lastPaymentMethod':
      result.method,
      'lastPaymentAt':
      ServerValue.timestamp,

      // Complete payment history.
      'payments':
      existingPayments,

      'updatedAt':
      ServerValue.timestamp,

      'orderStatus':
      newOrderStatus,
      'status':
      newOrderStatus,
    };

    await _updateOrder(
      updates,
    );
  }

  // ============================================================
  // CONFIRMATION
  // ============================================================

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              20,
            ),
          ),
          title: Text(
            title,
            style:
            const TextStyle(
              fontWeight:
              FontWeight.w700,
            ),
          ),
          content:
          Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
              const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              style:
              ElevatedButton
                  .styleFrom(
                backgroundColor:
                AppTheme.primary,
                foregroundColor:
                Colors.white,
              ),
              child:
              Text(
                confirmText,
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  void _showSuccess(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(message),
        backgroundColor:
        Colors.green.shade700,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
      String message,
      ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(message),
        backgroundColor:
        AppTheme.error,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor() {
    switch (
    _status.toLowerCase()) {
      case 'closed':
        return Colors.green.shade700;

      case 'delivered':
        return Colors.blue.shade700;

      case 'pending':
      default:
        return Colors.orange.shade700;
    }
  }

  Color _statusBackground() {
    return _statusColor()
        .withAlpha(18);
  }

  // ============================================================
  // PAYMENT COLOR
  // ============================================================

  Color _paymentColor() {
    if (_balance <= 0) {
      return Colors.green.shade700;
    }

    if (_totalPaid > 0) {
      return Colors.orange.shade700;
    }

    return Colors.red.shade700;
  }


  String _formatAmount(double amount) {
    final roundedAmount = amount.round();

    return roundedAmount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
    );
  }


  // ============================================================
  // SHARE ORDER
  // ============================================================

  Future<void> _shareOrder() async {
    if (_mobile.isEmpty) {
      _showError('Customer mobile number is not available.');
      return;
    }

    // ============================================================
    // BUILD ORDER ITEMS
    // ============================================================

    final itemLines = <String>[];

    for (var index = 0; index < _items.length; index++) {
      final item = _items[index];

      final plantName = _string(item['plantName']);
      final varietyName = _string(item['varietyName']);
      final variantName = _string(item['variantName']);

      final quantity = _toInt(item['quantity']);
      final price = _toDouble(item['price']);

      final storedTotal = item['total'];

      final itemTotal = storedTotal != null
          ? _toDouble(storedTotal)
          : price * quantity;

      // Build:
      // Mango - Banginapalli
      // Mango - Banginapalli - 5 Years
      final itemNameParts = <String>[
        if (plantName.isNotEmpty) plantName,
        if (varietyName.isNotEmpty) varietyName,
        if (variantName.isNotEmpty) variantName,
      ];

      final itemName = itemNameParts.isEmpty
          ? 'Item ${index + 1}'
          : itemNameParts.join(' - ');

      itemLines.add(
        '${index + 1}. $itemName\n'
            '   $quantity × ₹${price.toStringAsFixed(0)} = '
            '₹${_formatAmount(itemTotal)}',
      );
    }

    final itemsText = itemLines.isEmpty
        ? 'No item details available.'
        : itemLines.join('\n\n');

    // ============================================================
    // PAYMENT HISTORY
    // ============================================================

    final paymentLines = <String>[];

    for (final payment in _payments) {
      final amount = _toDouble(payment['amount']);

      final paymentMethod =
      _string(
        payment['paymentMethod'] ??
            payment['method'],
      );

      final methodText = paymentMethod.isNotEmpty
          ? ' - $paymentMethod'
          : '';

      paymentLines.add(
        '₹${_formatAmount(amount)}$methodText',
      );
    }

    final paymentText = paymentLines.isEmpty
        ? 'No payment received'
        : paymentLines.join('\n');

    // ============================================================
    // BUILD WHATSAPP MESSAGE
    // ============================================================

    final message = '''
🌱 *KAARUNYA NURSERY GARDENS*
*Grow Green • Live Green*

🧾 *ORDER BILL*

Order No: $_orderNumber
Date: $_orderDate

👤 *Customer*
$_customerName
📞 $_mobile
📍 $_village

━━━━━━━━━━━━━━━━━━

🌱 *PLANTS*

$itemsText

━━━━━━━━━━━━━━━━━━

💰 *BILL SUMMARY*

Total Bill    : ₹${_formatAmount(_total)}
Paid          : ₹${_formatAmount(_totalPaid)}
*Balance Due  : ₹${_formatAmount(_balance)}*

━━━━━━━━━━━━━━━━━━

💳 *PAYMENT RECEIVED*

$paymentText

━━━━━━━━━━━━━━━━━━

🙏 *Thank you for your order!*

🌱 *KAARUNYA NURSERY GARDENS*
📞 9876543210
📍 Venkatampalli, Kadapa

*Grow Green • Live Green* 🌿
''';

    // ============================================================
    // CUSTOMER MOBILE NUMBER
    // ============================================================

    final cleanedNumber = _mobile.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    // Add India country code for 10-digit numbers.
    final whatsappNumber = cleanedNumber.length == 10
        ? '91$cleanedNumber'
        : cleanedNumber;

    // ============================================================
    // OPEN WHATSAPP
    // ============================================================

    final encodedMessage =
    Uri.encodeComponent(message);

    final whatsappUri = Uri.parse(
      'whatsapp://send'
          '?phone=$whatsappNumber'
          '&text=$encodedMessage',
    );

    try {
      final launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showError(
          'WhatsApp is not available on this device.',
        );
      }
    } catch (e) {
      debugPrint(
        'WhatsApp launch error: $e',
      );

      if (mounted) {
        _showError(
          'Unable to open WhatsApp.',
        );
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppTheme.backgroundLight,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        centerTitle: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                Flexible(
                  child: Text(
                    _orderNumber,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  width: 3,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 7),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  _orderDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Share Order',
            onPressed: _isUpdating ? null : _shareOrder,
            icon: const Icon(
              Icons.share_outlined,
              size: 22,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomerToggle(),

                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: _showCustomerDetails
                      ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _buildCustomerCard(),
                  )
                      : const SizedBox.shrink(),
                ),


                const SizedBox(height: 10),
                _buildItemsCard(),

                const SizedBox(height: 20),
                _buildSectionTitle(
                  'Order Summary',
                  Icons.receipt_long_outlined,
                ),
                const SizedBox(height: 10),
                _buildSummaryCard(),

                const SizedBox(height: 12),
                _buildPaymentToggle(),

                AnimatedSize(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: _showPaymentDetails
                      ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _buildPaymentCard(),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (_isUpdating)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black12,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(18),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge() {
    return Container(
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration:
      BoxDecoration(
        color:
        _statusBackground(),
        borderRadius:
        BorderRadius.circular(
          10,
        ),
      ),
      child:
      Text(
        _status,
        style:
        TextStyle(
          color:
          _statusColor(),
          fontSize: 10,
          fontWeight:
          FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
      String title,
      IconData icon,
      ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration:
          BoxDecoration(
            color:
            AppTheme.primaryContainer,
            borderRadius:
            BorderRadius.circular(
              9,
            ),
          ),
          child:
          Icon(
            icon,
            color:
            AppTheme.primary,
            size: 18,
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        Text(
          title,
          style:
          const TextStyle(
            fontSize: 15,
            fontWeight:
            FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerToggle() {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            setState(() {
              _showCustomerDetails = !_showCustomerDetails;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: _showCustomerDetails
                  ? AppTheme.primaryContainer
                  : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.primary.withAlpha(35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _showCustomerDetails
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.person_outline_rounded,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _showCustomerDetails
                      ? 'Hide Customer / Delivery Details'
                      : 'View Customer / Delivery Details',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showCustomerDetails
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CUSTOMER + DELIVERY DETAILS CARD
  // ============================================================

  Widget _buildCustomerCard() {
    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _detailRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Customer Name',
                  value: _customerName,
                ),
                if (_fatherName.isNotEmpty) ...[
                  _detailDivider(),
                  _detailRow(
                    icon: Icons.badge_outlined,
                    label: 'Father Name',
                    value: _fatherName,
                  ),
                ],
                if (_mobile.isNotEmpty) ...[
                  _detailDivider(),
                  _detailRow(
                    icon: Icons.phone_outlined,
                    label: 'Mobile Number',
                    value: _mobile,
                    trailing: Icon(
                      Icons.phone_outlined,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
                _detailDivider(),
                _detailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Village',
                  value: _village.isEmpty ? '-' : _village,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT TOGGLE
  // ============================================================

  Widget _buildPaymentToggle() {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            setState(() {
              _showPaymentDetails = !_showPaymentDetails;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 17,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _showPaymentDetails
                      ? 'Hide Payment Details'
                      : 'View Payment Details',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  _showPaymentDetails
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppTheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ITEMS CARD
  // ============================================================

  // ============================================================
  // ITEMS CARD
  // ============================================================

  Widget _buildItemsCard() {
    final items =
        _items;

    if (items.isEmpty) {
      return _card(
        child:
        Padding(
          padding:
          const EdgeInsets.all(
            18,
          ),
          child:
          Center(
            child:
            Text(
              'No item details available.',
              style:
              TextStyle(
                color: Colors
                    .grey
                    .shade600,
              ),
            ),
          ),
        ),
      );
    }

    return _card(
      padding:
      EdgeInsets.zero,
      child:
      Column(
        children: [
          ...List.generate(
            items.length,
                (index) {
              return _buildItem(
                items[index],
                index,
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SINGLE ITEM
  // ============================================================

  Widget _buildItem(
      Map<String, dynamic> item,
      int index,
      ) {
    final plantName =
    _string(
      item['plantName'],
    );

    final varietyName =
    _string(
      item['varietyName'],
    );

    final variantName =
    _string(
      item['variantName'],
    );

    final quantity =
    _toInt(
      item['quantity'],
    );

    final price =
    _toDouble(
      item['price'],
    );

    final storedTotal =
    item['total'];

    final calculatedTotal =
    storedTotal != null
        ? _toDouble(
      storedTotal,
    )
        : price * quantity;

    final weight =
    _toDouble(
      item['weight'],
    );

    final years =
    _toInt(
      item['years'],
    );

    return Container(
      padding:
      const EdgeInsets.all(14),
      decoration:
      BoxDecoration(
        border: index == 0
            ? null
            : Border(
          top: BorderSide(
            color:
            Colors.grey.shade200,
          ),
        ),
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  color:
                  AppTheme.primaryContainer,
                  borderRadius:
                  BorderRadius.circular(
                    11,
                  ),
                ),
                child:
                const Icon(
                  Icons
                      .local_florist_rounded,
                  color:
                  AppTheme.primary,
                  size: 21,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      plantName.isEmpty
                          ? 'Plant'
                          : plantName,
                      style:
                      const TextStyle(
                        fontSize: 14,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    if (varietyName
                        .isNotEmpty ||
                        variantName
                            .isNotEmpty) ...[
                      const SizedBox(
                        height: 3,
                      ),
                      Text(
                        [
                          if (varietyName
                              .isNotEmpty)
                            varietyName,
                          if (variantName
                              .isNotEmpty)
                            variantName,
                        ].join(' • '),
                        style:
                        TextStyle(
                          fontSize: 11,
                          color: Colors
                              .grey
                              .shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Text(
                '₹${calculatedTotal.toStringAsFixed(0)}',
                style:
                const TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  AppTheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 11,
          ),

          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _smallInfoChip(
                Icons
                    .inventory_2_outlined,
                'Qty: $quantity',
              ),

              _smallInfoChip(
                Icons
                    .currency_rupee_rounded,
                '₹${price.toStringAsFixed(0)} each',
              ),

              if (weight >
                  0)
                _smallInfoChip(
                  Icons
                      .scale_outlined,
                  '${weight.toStringAsFixed(1)} kg',
                ),

              if (years >
                  0)
                _smallInfoChip(
                  Icons
                      .calendar_month_outlined,
                  '$years years',
                ),

            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER SUMMARY
  // ============================================================

  Widget _buildSummaryCard() {
    return _card(
      child:
      Column(
        children: [
          _amountRow(
            'Order Total',
            _total,
            Colors.black87,
          ),

          const SizedBox(
            height: 10,
          ),

          _amountRow(
            'Total Paid',
            _totalPaid,
            Colors.green.shade700,
          ),

          const SizedBox(
            height: 10,
          ),

          const Divider(),

          const SizedBox(
            height: 10,
          ),

          _amountRow(
            'Remaining Balance',
            _balance,
            _balance > 0
                ? Colors
                .orange
                .shade800
                : Colors
                .green
                .shade700,
            bold: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT CARD
  // ============================================================

  Widget _buildPaymentCard() {
    final paymentColor =
    _paymentColor();

    final payments =
        _payments;

    return _card(
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [

          // ------------------------------------------------------
          // SUMMARY
          // ------------------------------------------------------

          Row(
            children: [
              Expanded(
                child:
                _paymentSummary(
                  'Total',
                  _total,
                  Colors.black87,
                ),
              ),
              Expanded(
                child:
                _paymentSummary(
                  'Paid',
                  _totalPaid,
                  Colors.green
                      .shade700,
                ),
              ),
              Expanded(
                child:
                _paymentSummary(
                  'Balance',
                  _balance,
                  _balance > 0
                      ? Colors
                      .orange
                      .shade800
                      : Colors
                      .green
                      .shade700,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 16,
          ),

          // ------------------------------------------------------
          // PAYMENT STATUS
          // ------------------------------------------------------

          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets
                .all(10),
            decoration:
            BoxDecoration(
              color:
              paymentColor
                  .withAlpha(12),
              borderRadius:
              BorderRadius.circular(
                10,
              ),
            ),
            child:
            Row(
              children: [
                Icon(
                  _balance <= 0
                      ? Icons
                      .check_circle_outline
                      : Icons
                      .pending_actions,
                  color:
                  paymentColor,
                  size: 18,
                ),
                const SizedBox(
                  width: 7,
                ),
                Text(
                  _paymentStatus,
                  style:
                  TextStyle(
                    color:
                    paymentColor,
                    fontWeight:
                    FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // ------------------------------------------------------
          // PAYMENT HISTORY TITLE
          // ------------------------------------------------------

          Row(
            children: [
              const Icon(
                Icons
                    .history_rounded,
                size: 17,
                color:
                AppTheme.primary,
              ),
              const SizedBox(
                width: 6,
              ),
              const Text(
                'Payment History',
                style:
                TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          // ------------------------------------------------------
          // PAYMENT HISTORY
          // ------------------------------------------------------

          if (payments.isEmpty)
            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets
                  .all(14),
              decoration:
              BoxDecoration(
                color:
                Colors.grey.shade50,
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
              child:
              Center(
                child:
                Text(
                  'No payments received yet.',
                  style:
                  TextStyle(
                    fontSize: 12,
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),
              ),
            )
          else
            Column(
              children:
              List.generate(
                payments.length,
                    (index) {
                  return _buildPaymentHistoryItem(
                    payments[index],
                    index,
                    payments.length,
                  );
                },
              ),
            ),

        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT HISTORY ITEM
  // ============================================================

  Widget _buildPaymentHistoryItem(
      Map<String, dynamic> payment,
      int index,
      int totalPayments,
      ) {
    final amount =
    _toDouble(
      payment['amount'],
    );

    final method =
    _string(
      payment['method'],
    );

    final date =
    _paymentDate(payment);

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 7,
      ),
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.grey.shade50,
        borderRadius:
        BorderRadius.circular(
          11,
        ),
        border: Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),
      child:
      Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration:
            BoxDecoration(
              color:
              Colors.green.shade50,
              borderRadius:
              BorderRadius.circular(
                9,
              ),
            ),
            child:
            Icon(
              Icons
                  .check_rounded,
              color:
              Colors.green.shade700,
              size: 18,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  date == null
                      ? '-'
                      : _formatDate(
                    date,
                  ),
                  style:
                  const TextStyle(
                    fontSize: 12,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  method.isEmpty
                      ? 'Payment'
                      : method,
                  style:
                  TextStyle(
                    fontSize: 10,
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '₹${amount.toStringAsFixed(0)}',
            style:
            TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.w800,
              color:
              Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _buildStatusCard() {
    final isClosed =
        _status.toLowerCase() ==
            'closed';

    final isDelivered =
        _status.toLowerCase() ==
            'delivered';

    return _card(
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      'Current Status',
                      style:
                      TextStyle(
                        fontSize: 11,
                        color: Colors
                            .grey
                            .shade600,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      _status,
                      style:
                      TextStyle(
                        fontSize: 17,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        _statusColor(),
                      ),
                    ),
                  ],
                ),
              ),
              _statusBadge(),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          if (isDelivered &&
              _balance > 0)
            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets
                  .all(11),
              decoration:
              BoxDecoration(
                color:
                Colors.orange.shade50,
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
              child:
              Row(
                children: [
                  Icon(
                    Icons
                        .info_outline,
                    color:
                    Colors.orange.shade800,
                    size: 18,
                  ),
                  const SizedBox(
                    width: 7,
                  ),
                  Expanded(
                    child:
                    Text(
                      'Order is delivered. '
                          'Collect the remaining '
                          '₹${_balance.toStringAsFixed(0)} '
                          'to close the order.',
                      style:
                      TextStyle(
                        color:
                        Colors.orange.shade900,
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (isClosed)
            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets
                  .all(11),
              decoration:
              BoxDecoration(
                color:
                Colors.green.shade50,
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
              child:
              Row(
                children: [
                  Icon(
                    Icons
                        .check_circle_outline,
                    color:
                    Colors.green.shade700,
                    size: 18,
                  ),
                  const SizedBox(
                    width: 7,
                  ),
                  Expanded(
                    child:
                    Text(
                      'Order completed. '
                          'Full payment has been received.',
                      style:
                      TextStyle(
                        color:
                        Colors.green.shade900,
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (!isDelivered &&
              !isClosed)
            Text(
              'Use the button below to mark this order as delivered.',
              style:
              TextStyle(
                fontSize: 11,
                color:
                Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM ACTIONS
  // ============================================================

  Widget _buildBottomAction() {
    final isClosed =
        _status.toLowerCase() ==
            'closed';

    final isDelivered =
        _status.toLowerCase() ==
            'delivered';

    if (isClosed) {
      return SafeArea(
        child:
        Container(
          padding:
          const EdgeInsets
              .fromLTRB(
            16,
            7,
            16,
            8,
          ),
          decoration:
          BoxDecoration(
            color:
            Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withAlpha(10),
                blurRadius: 8,
                offset:
                const Offset(0, -2),
              ),
            ],
          ),
          child:
          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets
                .symmetric(
              vertical: 11,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.green.shade50,
              borderRadius:
              BorderRadius.circular(
                11,
              ),
            ),
            child:
            Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .center,
              children: [
                Icon(
                  Icons
                      .check_circle_rounded,
                  color:
                  Colors.green.shade700,
                  size: 19,
                ),
                const SizedBox(
                  width: 7,
                ),
                Text(
                  'Order Closed',
                  style:
                  TextStyle(
                    color:
                    Colors.green.shade800,
                    fontWeight:
                    FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child:
      Container(
        padding:
        const EdgeInsets
            .fromLTRB(
          16,
          7,
          16,
          8,
        ),
        decoration:
        BoxDecoration(
          color:
          Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withAlpha(10),
              blurRadius: 8,
              offset:
              const Offset(0, -2),
            ),
          ],
        ),
        child:
        Row(
          children: [
            // ----------------------------------------------------
            // MARK DELIVERED
            // ----------------------------------------------------

            Expanded(
              child:
              OutlinedButton.icon(
                onPressed:
                isDelivered ||
                    _isUpdating
                    ? null
                    : _markDelivered,
                icon:
                const Icon(
                  Icons
                      .local_shipping_outlined,
                  size: 18,
                ),
                label:
                const Text(
                  'Mark Delivered',
                ),
                style:
                OutlinedButton
                    .styleFrom(
                  foregroundColor:
                  Colors.blue.shade700,
                  disabledForegroundColor:
                  Colors.grey.shade400,
                  side:
                  BorderSide(
                    color:
                    Colors.blue.shade700,
                  ),
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 11,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      11,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              width: 9,
            ),

            // ----------------------------------------------------
            // COLLECT PAYMENT
            // ----------------------------------------------------

            Expanded(
              child:
              ElevatedButton
                  .icon(
                onPressed:
                _balance > 0 &&
                    !_isUpdating
                    ? _addPayment
                    : null,
                icon:
                const Icon(
                  Icons
                      .payments_outlined,
                  size: 18,
                ),
                label:
                const Text(
                  'Collect Payment',
                ),
                style:
                ElevatedButton
                    .styleFrom(
                  backgroundColor:
                  AppTheme.primary,
                  foregroundColor:
                  Colors.white,
                  disabledBackgroundColor:
                  Colors.grey.shade300,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 11,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      11,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GENERIC CARD
  // ============================================================

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry?
    padding,
  }) {
    return Container(
      width:
      double.infinity,
      padding:
      padding ??
          const EdgeInsets.all(
            14,
          ),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
          Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(7),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child:
      child,
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration:
          BoxDecoration(
            color:
            Colors.grey.shade100,
            borderRadius:
            BorderRadius.circular(
              9,
            ),
          ),
          child:
          Icon(
            icon,
            size: 17,
            color:
            Colors.grey.shade700,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child:
          Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Text(
                label,
                style:
                TextStyle(
                  fontSize: 10,
                  color:
                  Colors.grey.shade600,
                ),
              ),
              const SizedBox(
                height: 2,
              ),
              Text(
                value.isEmpty
                    ? '-'
                    : value,
                style:
                const TextStyle(
                  fontSize: 13,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        if (trailing != null)
          trailing,
      ],
    );
  }

  // ============================================================
  // DETAIL DIVIDER
  // ============================================================

  Widget _detailDivider() {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical: 10,
      ),
      child:
      Divider(
        height: 1,
        color:
        Colors.grey.shade200,
      ),
    );
  }

  // ============================================================
  // SMALL INFO CHIP
  // ============================================================

  Widget _smallInfoChip(
      IconData icon,
      String text,
      ) {
    return Container(
      padding:
      const EdgeInsets
          .symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.grey.shade100,
        borderRadius:
        BorderRadius.circular(
          8,
        ),
      ),
      child:
      Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color:
            Colors.grey.shade700,
          ),
          const SizedBox(
            width: 4,
          ),
          Text(
            text,
            style:
            TextStyle(
              fontSize: 10,
              color:
              Colors.grey.shade800,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AMOUNT ROW
  // ============================================================

  Widget _amountRow(
      String label,
      double amount,
      Color color, {
        bool bold = false,
      }) {
    return Row(
      children: [
        Expanded(
          child:
          Text(
            label,
            style:
            TextStyle(
              fontSize: 12,
              color:
              Colors.grey.shade700,
              fontWeight:
              bold
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style:
          TextStyle(
            fontSize:
            bold ? 16 : 13,
            color:
            color,
            fontWeight:
            bold
                ? FontWeight.w800
                : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAYMENT SUMMARY
  // ============================================================

  Widget _paymentSummary(
      String label,
      double amount,
      Color color,
      ) {
    return Column(
      children: [
        Text(
          label,
          style:
          TextStyle(
            fontSize: 10,
            color:
            Colors.grey.shade600,
          ),
        ),
        const SizedBox(
          height: 3,
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style:
          TextStyle(
            fontSize: 14,
            fontWeight:
            FontWeight.w800,
            color:
            color,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// PAYMENT RESULT
// ============================================================================

class _PaymentResult {
  final double amount;
  final String method;

  const _PaymentResult({
    required this.amount,
    required this.method,
  });
}

// ============================================================================
// PAYMENT DIALOG
// ============================================================================

class _PaymentDialog
    extends StatefulWidget {
  final double total;
  final double alreadyPaid;
  final double balance;

  const _PaymentDialog({
    required this.total,
    required this.alreadyPaid,
    required this.balance,
  });

  @override
  State<_PaymentDialog>
  createState() =>
      _PaymentDialogState();
}

class _PaymentDialogState
    extends State<_PaymentDialog> {
  late TextEditingController
  _amountController;

  String _paymentMethod =
      'Cash';

  final List<String>
  _paymentMethods = [
    'Cash',
    'UPI',
    'Bank Transfer',
    'Other',
  ];

  @override
  void initState() {
    super.initState();

    _amountController =
        TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _save() {
    final amount =
    double.tryParse(
      _amountController.text
          .trim(),
    );

    if (amount == null ||
        amount <= 0) {
      _error(
        'Please enter a valid payment amount.',
      );
      return;
    }

    if (amount >
        widget.balance) {
      _error(
        'Payment cannot exceed '
            '₹${widget.balance.toStringAsFixed(0)}.',
      );
      return;
    }

    Navigator.pop(
      context,
      _PaymentResult(
        amount: amount,
        method:
        _paymentMethod,
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _error(
      String message,
      ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
        Text(message),
        backgroundColor:
        AppTheme.error,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return AlertDialog(
      shape:
      RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),
      title:
      const Text(
        'Collect Payment',
        style:
        TextStyle(
          fontWeight:
          FontWeight.w800,
        ),
      ),
      content:
      SingleChildScrollView(
        child:
        Column(
          mainAxisSize:
          MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment
              .start,
          children: [
            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets
                  .all(14),
              decoration:
              BoxDecoration(
                color:
                AppTheme
                    .primaryContainer,
                borderRadius:
                BorderRadius.circular(
                  14,
                ),
              ),
              child:
              Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    'Remaining Balance',
                    style:
                    TextStyle(
                      fontSize: 12,
                      color: Colors
                          .grey
                          .shade700,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    '₹${widget.balance.toStringAsFixed(0)}',
                    style:
                    const TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.w800,
                      color:
                      AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            TextField(
              controller:
              _amountController,
              autofocus:
              true,
              keyboardType:
              const TextInputType
                  .numberWithOptions(
                decimal: true,
              ),
              decoration:
              const InputDecoration(
                labelText:
                'Payment Amount',
                hintText:
                'Enter amount received',
                prefixIcon:
                Icon(
                  Icons
                      .currency_rupee_rounded,
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            DropdownButtonFormField<
                String>(
              value:
              _paymentMethod,
              decoration:
              const InputDecoration(
                labelText:
                'Payment Method',
                prefixIcon:
                Icon(
                  Icons
                      .payments_outlined,
                ),
              ),
              items:
              _paymentMethods
                  .map(
                    (method) {
                  return DropdownMenuItem<
                      String>(
                    value:
                    method,
                    child:
                    Text(
                      method,
                    ),
                  );
                },
              ).toList(),
              onChanged:
                  (value) {
                if (value ==
                    null) {
                  return;
                }

                setState(() {
                  _paymentMethod =
                      value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
          child:
          const Text(
            'Cancel',
          ),
        ),
        ElevatedButton.icon(
          onPressed:
          _save,
          icon:
          const Icon(
            Icons.check_rounded,
          ),
          label:
          const Text(
            'Save Payment',
          ),
          style:
          ElevatedButton
              .styleFrom(
            backgroundColor:
            AppTheme.primary,
            foregroundColor:
            Colors.white,
          ),
        ),
      ],
    );
  }
}
