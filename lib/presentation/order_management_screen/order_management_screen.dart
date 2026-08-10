import 'package:flutter/material.dart';

import '../../services/order_repository.dart';
import '../../theme/app_theme.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() =>
      _OrderManagementScreenState();
}

class _OrderManagementScreenState
    extends State<OrderManagementScreen> {
  // ============================================================
  // STATE
  // ============================================================

  final OrderRepository _orderRepository =
      OrderRepository.instance;

  final TextEditingController _searchController =
  TextEditingController();

  List<Map<String, dynamic>> _orders = [];

  bool _isLoading = true;

  String _statusFilter = 'All';

  bool _isSearching = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD ORDERS
  // ============================================================

  Future<void> _loadOrders() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      debugPrint('========================================');
      debugPrint('LOADING ORDERS');
      debugPrint('========================================');

      final orders =
      await _orderRepository.getOrders();

      debugPrint(
        'Orders returned from Firebase: ${orders.length}',
      );

      for (final order in orders) {
        debugPrint(
          'Order: ${order['orderNumber']} | '
              'Customer: ${order['customerName']} | '
              'Status: ${order['orderStatus']} | '
              'Payment: ${order['paymentStatus']}',
        );
      }

      debugPrint('========================================');

      if (!mounted) {
        return;
      }

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('FAILED TO LOAD ORDERS');
      debugPrint('Error: $e');
      debugPrint('========================================');

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _orders = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load orders: $e',
          ),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // FILTERED ORDERS
  // ============================================================

  List<Map<String, dynamic>> get _filteredOrders {
    final searchText =
    _searchController.text.trim().toLowerCase();

    return _orders.where((order) {
      // --------------------------------------------------------
      // SEARCH
      // --------------------------------------------------------

      if (searchText.isNotEmpty) {
        final customerName =
            order['customerName']
                ?.toString()
                .toLowerCase() ??
                '';

        final customerMobile =
            order['customerMobile']
                ?.toString()
                .toLowerCase() ??
                '';

        final customerVillage =
            order['customerVillage']
                ?.toString()
                .toLowerCase() ??
                '';

        final orderNumber =
            order['orderNumber']
                ?.toString()
                .toLowerCase() ??
                '';

        final matchesSearch =
            customerName.contains(searchText) ||
                customerMobile.contains(searchText) ||
                customerVillage.contains(searchText) ||
                orderNumber.contains(searchText);

        if (!matchesSearch) {
          return false;
        }
      }

      // --------------------------------------------------------
      // STATUS FILTER
      // --------------------------------------------------------

      if (_statusFilter == 'All') {
        return true;
      }

      return _matchesStatus(
        order,
        _statusFilter,
      );
    }).toList();
  }

  // ============================================================
  // STATUS MATCHING
  // ============================================================

  bool _matchesStatus(
      Map<String, dynamic> order,
      String filter,
      ) {
    final orderStatus =
        order['orderStatus']
            ?.toString()
            .toUpperCase() ??
            '';

    final paymentStatus =
        order['paymentStatus']
            ?.toString()
            .toUpperCase() ??
            '';

    switch (filter) {
      case 'Pending':
        return orderStatus == 'ORDERED' ||
            orderStatus == 'PENDING';

      case 'Delivered':
        return orderStatus == 'DELIVERED';

      case 'Pending Payment':
        return orderStatus == 'PENDING_PAYMENT' ||
            paymentStatus == 'PARTIAL' ||
            (
                orderStatus == 'DELIVERED' &&
                    paymentStatus != 'PAID'
            );

      case 'Closed':
        return orderStatus == 'CLOSED' ||
            paymentStatus == 'PAID';

      default:
        return true;
    }
  }

  // ============================================================
  // STATUS DISPLAY
  // ============================================================

  String _displayStatus(
      Map<String, dynamic> order,
      ) {
    final orderStatus =
        order['orderStatus']
            ?.toString()
            .toUpperCase() ??
            '';

    final paymentStatus =
        order['paymentStatus']
            ?.toString()
            .toUpperCase() ??
            '';

    if (orderStatus == 'CLOSED' ||
        paymentStatus == 'PAID') {
      return 'Closed';
    }

    if (orderStatus == 'PENDING_PAYMENT' ||
        (
            orderStatus == 'DELIVERED' &&
                paymentStatus != 'PAID'
        ) ||
        paymentStatus == 'PARTIAL') {
      return 'Pending Payment';
    }

    if (orderStatus == 'DELIVERED') {
      return 'Delivered';
    }

    return 'Pending';
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(
      String status,
      ) {
    switch (status) {
      case 'Closed':
        return Colors.green.shade700;

      case 'Pending Payment':
        return Colors.orange.shade700;

      case 'Delivered':
        return Colors.blue.shade700;

      case 'Pending':
      default:
        return AppTheme.primary;
    }
  }

  Color _statusBackground(
      String status,
      ) {
    switch (status) {
      case 'Closed':
        return Colors.green.shade50;

      case 'Pending Payment':
        return Colors.orange.shade50;

      case 'Delivered':
        return Colors.blue.shade50;

      case 'Pending':
      default:
        return AppTheme.primaryContainer;
    }
  }

  // ============================================================
  // ITEM COUNT
  // ============================================================

  int _itemCount(
      Map<String, dynamic> order,
      ) {
    final items = order['items'];

    if (items is Map) {
      return items.length;
    }

    return 0;
  }

  // ============================================================
  // NUMBER FORMAT
  // ============================================================

  String _formatAmount(
      dynamic value,
      ) {
    final amount =
    value is num
        ? value.toDouble()
        : double.tryParse(
      value?.toString() ?? '',
    ) ??
        0;

    return amount
        .toStringAsFixed(0);
  }

  // ============================================================
  // FILTER CHIP
  // ============================================================

  Widget _buildFilterChip(
      String label,
      ) {
    final isSelected =
        _statusFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _statusFilter = label;
        });
      },
      child: AnimatedContainer(
        duration:
        const Duration(
          milliseconds: 180,
        ),
        padding:
        const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration:
        BoxDecoration(
          color: isSelected
              ? AppTheme.primary
              : AppTheme.surfaceVariantLight,
          borderRadius:
          BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppTheme.primary
                : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight:
            FontWeight.w600,
            color: isSelected
                ? Colors.white
                : AppTheme.primary,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar(
      ThemeData theme,
      ) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        8,
      ),
      child: Container(
        height: 48,
        decoration:
        BoxDecoration(
          color:
          theme.colorScheme.surface,
          borderRadius:
          BorderRadius.circular(14),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
        ),
        child: TextField(
          controller:
          _searchController,
          autofocus: true,
          onChanged: (_) {
            setState(() {});
          },
          decoration:
          InputDecoration(
            hintText:
            'Search customer, mobile or village',
            prefixIcon:
            const Icon(
              Icons.search_rounded,
            ),
            suffixIcon:
            IconButton(
              onPressed: () {
                _searchController.clear();

                setState(() {
                  _isSearching = false;
                });
              },
              icon: const Icon(
                Icons.close_rounded,
              ),
            ),
            border:
            InputBorder.none,
            contentPadding:
            const EdgeInsets.symmetric(
              vertical: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ORDER CARD
  // ============================================================

  Widget _buildOrderCard(
      BuildContext context,
      Map<String, dynamic> order,
      ) {
    final theme =
    Theme.of(context);

    final orderNumber =
        order['orderNumber']
            ?.toString() ??
            'Order';

    final customerName =
    order['customerName']
        ?.toString()
        .trim()
        .isNotEmpty ==
        true
        ? order['customerName']
        .toString()
        : 'Unknown Customer';

    final mobile =
        order['customerMobile']
            ?.toString() ??
            '';

    final village =
        order['customerVillage']
            ?.toString() ??
            '';

    final itemCount =
    _itemCount(order);

    final total =
    _formatAmount(
      order['total'],
    );

    final totalPaid =
    _formatAmount(
      order['totalPaid'],
    );

    final balance =
    _formatAmount(
      order['balance'],
    );

    final status =
    _displayStatus(order);

    final statusColor =
    _statusColor(status);

    final statusBackground =
    _statusBackground(status);

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      decoration:
      BoxDecoration(
        color:
        theme.colorScheme.surface,
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withAlpha(7),
            blurRadius: 10,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // ==================================================
            // TOP ROW
            // ==================================================

            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration:
                  BoxDecoration(
                    color:
                    AppTheme.primaryContainer,
                    borderRadius:
                    BorderRadius.circular(
                      13,
                    ),
                  ),
                  child:
                  const Icon(
                    Icons
                        .receipt_long_rounded,
                    color:
                    AppTheme.primary,
                    size: 24,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        orderNumber,
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color:
                          Colors.grey.shade600,
                          fontWeight:
                          FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    statusBackground,
                    borderRadius:
                    BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color:
                      statusColor,
                      fontSize: 11,
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // CUSTOMER INFORMATION
            // ==================================================

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (mobile.isNotEmpty)
                  _infoChip(
                    Icons
                        .phone_outlined,
                    mobile,
                  ),

                if (village.isNotEmpty)
                  _infoChip(
                    Icons
                        .location_on_outlined,
                    village,
                  ),

                _infoChip(
                  Icons
                      .inventory_2_outlined,
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            const Divider(
              height: 1,
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // PAYMENT SUMMARY
            // ==================================================

            Row(
              children: [
                Expanded(
                  child:
                  _amountColumn(
                    label: 'Total',
                    amount:
                    '₹$total',
                  ),
                ),

                Expanded(
                  child:
                  _amountColumn(
                    label: 'Paid',
                    amount:
                    '₹$totalPaid',
                  ),
                ),

                Expanded(
                  child:
                  _amountColumn(
                    label: 'Remaining',
                    amount:
                    '₹$balance',
                    highlight:
                    balance != '0',
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // VIEW ORDER
            // ==================================================

            SizedBox(
              width:
              double.infinity,
              child:
              OutlinedButton.icon(
                onPressed: () {
                  // We will connect this to
                  // Manage Order / Order Details
                  // screen next.
                },
                icon:
                const Icon(
                  Icons
                      .arrow_forward_rounded,
                  size: 18,
                ),
                label:
                const Text(
                  'View Order',
                ),
                style:
                OutlinedButton
                    .styleFrom(
                  foregroundColor:
                  AppTheme.primary,
                  side:
                  BorderSide(
                    color: AppTheme
                        .primary
                        .withAlpha(90),
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
                      12,
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
  // INFO CHIP
  // ============================================================

  Widget _infoChip(
      IconData icon,
      String text,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.grey.shade100,
        borderRadius:
        BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color:
            Colors.grey.shade700,
          ),
          const SizedBox(
            width: 5,
          ),
          Text(
            text,
            style:
            TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.w500,
              color:
              Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // AMOUNT COLUMN
  // ============================================================

  Widget _amountColumn({
    required String label,
    required String amount,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color:
            Colors.grey.shade600,
            fontWeight:
            FontWeight.w500,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 15,
            fontWeight:
            FontWeight.w800,
            color: highlight
                ? Colors.orange.shade700
                : AppTheme.primary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(
      ThemeData theme,
      ) {
    final hasSearch =
        _searchController.text
            .trim()
            .isNotEmpty;

    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(32),
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration:
              BoxDecoration(
                color:
                AppTheme.primaryContainer,
                shape:
                BoxShape.circle,
              ),
              child:
              const Icon(
                Icons
                    .receipt_long_outlined,
                size: 40,
                color:
                AppTheme.primary,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              hasSearch
                  ? 'No matching orders'
                  : 'No orders found',
              style: theme
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              hasSearch
                  ? 'Try a different customer name, mobile number or village.'
                  : _statusFilter == 'All'
                  ? 'Orders placed by customers will appear here.'
                  : 'There are no orders with "$_statusFilter" status.',
              textAlign:
              TextAlign.center,
              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color:
                Colors.grey.shade600,
              ),
            ),

            if (hasSearch) ...[
              const SizedBox(
                height: 18,
              ),
              OutlinedButton(
                onPressed: () {
                  _searchController
                      .clear();

                  setState(() {});
                },
                child:
                const Text(
                  'Clear Search',
                ),
              ),
            ],
          ],
        ),
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
    final theme =
    Theme.of(context);

    final filteredOrders =
        _filteredOrders;

    return Scaffold(
      backgroundColor:
      AppTheme.backgroundLight,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
        theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        automaticallyImplyLeading:
        false,

        title: Text(
          'Orders',
          style: theme
              .textTheme
              .titleLarge
              ?.copyWith(
            fontWeight:
            FontWeight.w700,
          ),
        ),

        actions: [
          IconButton(
            tooltip:
            'Search orders',
            onPressed: () {
              setState(() {
                _isSearching =
                !_isSearching;
              });

              if (!_isSearching) {
                _searchController
                    .clear();
              }
            },
            icon: Icon(
              _isSearching
                  ? Icons.close_rounded
                  : Icons.search_rounded,
            ),
          ),

          IconButton(
            tooltip:
            'Refresh',
            onPressed:
            _isLoading
                ? null
                : _loadOrders,
            icon:
            const Icon(
              Icons.refresh_rounded,
            ),
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------
            // SEARCH
            // ----------------------------------------------------

            if (_isSearching)
              _buildSearchBar(theme),

            // ----------------------------------------------------
            // STATUS FILTERS
            // ----------------------------------------------------

            SizedBox(
              height: 48,
              child:
              ListView.separated(
                scrollDirection:
                Axis.horizontal,
                padding:
                const EdgeInsets
                    .fromLTRB(
                  16,
                  6,
                  16,
                  6,
                ),
                itemCount: 5,
                separatorBuilder:
                    (_, __) =>
                const SizedBox(
                  width: 8,
                ),
                itemBuilder:
                    (context, index) {
                  const filters = [
                    'All',
                    'Pending',
                    'Delivered',
                    'Pending Payment',
                    'Closed',
                  ];

                  return _buildFilterChip(
                    filters[index],
                  );
                },
              ),
            ),

            // ----------------------------------------------------
            // ORDER COUNT
            // ----------------------------------------------------

            Padding(
              padding:
              const EdgeInsets
                  .fromLTRB(
                16,
                4,
                16,
                8,
              ),
              child: Row(
                children: [
                  Text(
                    '${filteredOrders.length} ${filteredOrders.length == 1 ? 'order' : 'orders'}',
                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color:
                      Colors.grey.shade600,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  if (_statusFilter !=
                      'All')
                    Text(
                      _statusFilter,
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color:
                        AppTheme.primary,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            // ----------------------------------------------------
            // ORDER LIST
            // ----------------------------------------------------

            Expanded(
              child: _isLoading
                  ? const Center(
                child:
                CircularProgressIndicator(),
              )
                  : filteredOrders
                  .isEmpty
                  ? _buildEmptyState(
                theme,
              )
                  : RefreshIndicator(
                onRefresh:
                _loadOrders,
                child:
                ListView.builder(
                  physics:
                  const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    16,
                    4,
                    16,
                    24,
                  ),
                  itemCount:
                  filteredOrders
                      .length,
                  itemBuilder:
                      (
                      context,
                      index,
                      ) {
                    return _buildOrderCard(
                      context,
                      filteredOrders[
                      index],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}