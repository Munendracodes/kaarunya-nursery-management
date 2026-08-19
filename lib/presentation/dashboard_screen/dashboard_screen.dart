import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../services/order_repository.dart';
import './widgets/dashboard_app_bar_widget.dart';
import './widgets/dashboard_filter_chips_widget.dart';
import './widgets/dashboard_hero_widget.dart';
import './widgets/dashboard_kpi_grid_widget.dart';
import './widgets/dashboard_quick_actions_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ============================================================
  // REPOSITORY
  // ============================================================

  final OrderRepository _orderRepository =
      OrderRepository.instance;

  // ============================================================
  // FILTERS
  // ============================================================

  // IMPORTANT:
  // Dashboard starts with All Time so that the KPI values
  // match the complete orders collection in Firebase.
  String _selectedFilter = 'All Time';

  final List<String> _filters = [
    'Today',
    'This Week',
    'This Month',
    'All Time',
  ];

  // ============================================================
  // DATA
  // ============================================================

  List<Map<String, dynamic>> _orders = [];

  bool _isLoading = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadDashboardData();
  }

  // ============================================================
  // LOAD ORDERS
  // ============================================================

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      debugPrint(
        '==================================================',
      );

      debugPrint(
        'DASHBOARD: LOADING ORDERS FROM FIREBASE',
      );

      debugPrint(
        '==================================================',
      );

      final orders =
      await _orderRepository.getOrders();

      debugPrint(
        'Dashboard Firebase order count: ${orders.length}',
      );

      // ----------------------------------------------------------
      // PRINT EVERY ORDER FOR VERIFICATION
      // ----------------------------------------------------------

      double debugTotalPaid = 0;
      double debugPending = 0;

      for (final order in orders) {
        final orderNumber =
            order['orderNumber']
                ?.toString() ??
                'Unknown';

        final total =
        _toDouble(
          order['total'],
        );

        final totalPaid =
        _toDouble(
          order['totalPaid'],
        );

        final balance =
        _getBalance(order);

        debugTotalPaid += totalPaid;
        debugPending += balance;

        debugPrint(
          'ORDER: $orderNumber | '
              'Total: $total | '
              'Paid: $totalPaid | '
              'Balance: $balance | '
              'Status: ${order['orderStatus']} | '
              'Payment: ${order['paymentStatus']}',
        );
      }

      debugPrint(
        '--------------------------------------------------',
      );

      debugPrint(
        'FIREBASE TOTAL ORDERS: ${orders.length}',
      );

      debugPrint(
        'FIREBASE TOTAL COLLECTED: $debugTotalPaid',
      );

      debugPrint(
        'FIREBASE TOTAL PENDING: $debugPending',
      );

      debugPrint(
        '==================================================',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint(
        '==================================================',
      );

      debugPrint(
        'DASHBOARD: FAILED TO LOAD ORDERS',
      );

      debugPrint(
        'Error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      debugPrint(
        '==================================================',
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
            'Unable to load dashboard orders: $e',
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
    // ----------------------------------------------------------
    // ALL TIME
    // ----------------------------------------------------------

    if (_selectedFilter == 'All Time') {
      return List<Map<String, dynamic>>.from(
        _orders,
      );
    }

    final now = DateTime.now();

    late DateTime startDate;

    switch (_selectedFilter) {
      case 'Today':
        startDate = DateTime(
          now.year,
          now.month,
          now.day,
        );
        break;

      case 'This Week':
        final startOfToday = DateTime(
          now.year,
          now.month,
          now.day,
        );

        // Monday = 1
        final daysFromMonday =
            startOfToday.weekday - 1;

        startDate = startOfToday.subtract(
          Duration(
            days: daysFromMonday,
          ),
        );
        break;

      case 'This Month':
        startDate = DateTime(
          now.year,
          now.month,
          1,
        );
        break;

      default:
        return List<Map<String, dynamic>>.from(
          _orders,
        );
    }

    return _orders.where((order) {
      final orderDate =
      _getOrderDate(order);

      if (orderDate == null) {
        return false;
      }

      return !orderDate.isBefore(
        startDate,
      );
    }).toList();
  }

  // ============================================================
  // ORDER DATE
  // ============================================================

  DateTime? _getOrderDate(
      Map<String, dynamic> order,
      ) {
    // createdAt is the primary field.
    dynamic value =
    order['createdAt'];

    // Some older orders may use orderDate.
    value ??= order['orderDate'];

    if (value == null) {
      return null;
    }

    // Firebase ServerValue.timestamp
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value,
      );
    }

    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
      );
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
      );
    }

    // Timestamp stored as string.
    final numericValue =
    int.tryParse(
      value.toString(),
    );

    if (numericValue != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        numericValue,
      );
    }

    // ISO date string.
    try {
      return DateTime.parse(
        value.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // DASHBOARD KPI DATA
  // ============================================================

  Map<String, dynamic> get _kpiData {
    final orders =
        _filteredOrders;

    int totalOrders =
        orders.length;

    double collected = 0;

    double pending = 0;

    // ----------------------------------------------------------
    // CALCULATE FROM ACTUAL FIREBASE ORDER DATA
    // ----------------------------------------------------------

    for (final order in orders) {
      // Collected = totalPaid
      collected +=
          _toDouble(
            order['totalPaid'],
          );

      // Pending = balance
      //
      // If balance does not exist in an older order,
      // calculate:
      //
      // total - totalPaid
      //
      pending +=
          _getBalance(order);
    }

    debugPrint(
      '==================================================',
    );

    debugPrint(
      'DASHBOARD KPI',
    );

    debugPrint(
      'Filter: $_selectedFilter',
    );

    debugPrint(
      'Total Orders: $totalOrders',
    );

    debugPrint(
      'Collected: $collected',
    );

    debugPrint(
      'Pending: $pending',
    );

    debugPrint(
      '==================================================',
    );

    return {
      // Exact number of Firebase orders
      'totalOrders': totalOrders,

      // Revenue intentionally not implemented yet.
      'revenue': 0,

      // Sum of totalPaid
      'collected': collected,

      // Sum of balance / calculated pending
      'pending': pending,

      // Existing Hero widget values.
      'healthScore': 100,
      'healthLabel': 'Good',
    };
  }

  // ============================================================
  // GET BALANCE
  // ============================================================

  double _getBalance(
      Map<String, dynamic> order,
      ) {
    // ----------------------------------------------------------
    // 1. Use Firebase balance if available.
    // ----------------------------------------------------------

    final balanceValue =
    order['balance'];

    if (balanceValue != null) {
      final parsedBalance =
      double.tryParse(
        balanceValue.toString(),
      );

      if (parsedBalance != null) {
        return parsedBalance < 0
            ? 0
            : parsedBalance;
      }
    }

    // ----------------------------------------------------------
    // 2. Fallback:
    //
    // balance = total - totalPaid
    // ----------------------------------------------------------

    final total =
    _toDouble(
      order['total'],
    );

    final totalPaid =
    _toDouble(
      order['totalPaid'],
    );

    final calculated =
        total - totalPaid;

    return calculated < 0
        ? 0
        : calculated;
  }

  // ============================================================
  // NUMBER CONVERSION
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

  // ============================================================
  // FORMAT AMOUNT
  // ============================================================

  String _formatAmount(
      dynamic value,
      ) {
    final amount =
    _toDouble(value);

    return amount.toStringAsFixed(0);
  }

  // ============================================================
  // RECENT ORDERS
  // ============================================================

  List<Map<String, dynamic>>
  get _recentOrders {
    final orders =
    List<Map<String, dynamic>>.from(
      _orders,
    );

    // ----------------------------------------------------------
    // NEWEST FIRST
    // ----------------------------------------------------------

    orders.sort(
          (a, b) {
        final dateA =
        _getOrderDate(a);

        final dateB =
        _getOrderDate(b);

        if (dateA == null &&
            dateB == null) {
          return 0;
        }

        if (dateA == null) {
          return 1;
        }

        if (dateB == null) {
          return -1;
        }

        return dateB.compareTo(
          dateA,
        );
      },
    );

    // Show latest 5 orders.
    return orders.take(5).toList();
  }

  // ============================================================
  // DISPLAY ORDER STATUS
  // ============================================================

  String _displayStatus(
      Map<String, dynamic> order,
      ) {
    final status =
        order['orderStatus']
            ?.toString()
            .trim()
            .toUpperCase() ??
            '';

    switch (status) {
      case 'DELIVERED':
        return 'Delivered';

      case 'CLOSED':
        return 'Closed';

      case 'PENDING':
        return 'Pending';

      case 'ORDERED':
        return 'Ordered';

      default:
        return status.isEmpty
            ? 'Pending'
            : status
            .toLowerCase()
            .split(' ')
            .map(
              (word) =>
          word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
            .join(' ');
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(
      String status,
      ) {
    switch (status) {
      case 'Delivered':
        return Colors.blue.shade700;

      case 'Closed':
        return Colors.green.shade700;

      case 'Ordered':
        return AppTheme.primary;

      case 'Pending':
      default:
        return Colors.orange.shade700;
    }
  }

  // ============================================================
  // STATUS BACKGROUND
  // ============================================================

  Color _statusBackground(
      String status,
      ) {
    switch (status) {
      case 'Delivered':
        return Colors.blue.shade50;

      case 'Closed':
        return Colors.green.shade50;

      case 'Ordered':
        return AppTheme.primaryContainer;

      case 'Pending':
      default:
        return Colors.orange.shade50;
    }
  }

  // ============================================================
  // RECENT ORDER CARD
  // ============================================================

  Widget _buildRecentOrderCard(
      BuildContext context,
      Map<String, dynamic> order,
      ) {
    final theme =
    Theme.of(context);

    final customerName =
    order['customerName']
        ?.toString()
        .trim()
        .isNotEmpty ==
        true
        ? order['customerName']
        .toString()
        : 'Unknown Customer';

    final village =
        order['customerVillage']
            ?.toString()
            .trim() ??
            '';

    final mobile =
        order['customerMobile']
            ?.toString()
            .trim() ??
            '';

    final orderNumber =
        order['orderNumber']
            ?.toString() ??
            'Order';

    final total =
    _formatAmount(
      order['total'],
    );

    final balance =
    _formatAmount(
      _getBalance(order),
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
        bottom: 10,
      ),
      padding:
      const EdgeInsets.all(14),
      decoration:
      BoxDecoration(
        color:
        theme.colorScheme.surface,
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color:
          Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withAlpha(6),
            blurRadius: 8,
            offset:
            const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ------------------------------------------------------
          // ICON
          // ------------------------------------------------------

          Container(
            width: 44,
            height: 44,
            decoration:
            BoxDecoration(
              color:
              AppTheme.primaryContainer,
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child:
            const Icon(
              Icons
                  .receipt_long_rounded,
              color:
              AppTheme.primary,
              size: 22,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          // ------------------------------------------------------
          // CUSTOMER DETAILS
          // ------------------------------------------------------

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
                      .titleSmall
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

                if (village.isNotEmpty) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    village,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color:
                      Colors.grey.shade600,
                    ),
                  ),
                ] else if (mobile
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    mobile,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color:
                      Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ------------------------------------------------------
          // AMOUNT + STATUS
          // ------------------------------------------------------

          Column(
            crossAxisAlignment:
            CrossAxisAlignment.end,
            children: [
              Text(
                '₹$total',
                style: theme
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                  color:
                  AppTheme.primary,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Container(
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration:
                BoxDecoration(
                  color:
                  statusBackground,
                  borderRadius:
                  BorderRadius.circular(
                    8,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color:
                    statusColor,
                    fontSize: 10,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),


            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RECENT ORDERS SECTION
  // ============================================================

  Widget _buildRecentOrdersSection(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final recentOrders =
        _recentOrders;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Recent Orders',
              style: theme
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight:
                FontWeight.w700,
              ),
            ),

            const Spacer(),

            TextButton(
              onPressed: () {
                context.go(
                  AppRoutes
                      .orderManagementScreen,
                );
              },
              child:
              const Text(
                'View All',
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 8,
        ),

        if (_isLoading)
          const Padding(
            padding:
            EdgeInsets.symmetric(
              vertical: 30,
            ),
            child: Center(
              child:
              CircularProgressIndicator(),
            ),
          )
        else if (recentOrders.isEmpty)
          Container(
            width:
            double.infinity,
            padding:
            const EdgeInsets.all(28),
            decoration:
            BoxDecoration(
              color:
              theme.colorScheme.surface,
              borderRadius:
              BorderRadius.circular(
                16,
              ),
              border: Border.all(
                color:
                Colors.grey.shade200,
              ),
            ),
            child:
            Column(
              children: [
                Icon(
                  Icons
                      .receipt_long_outlined,
                  size: 38,
                  color:
                  Colors.grey.shade400,
                ),

                const SizedBox(
                  height: 10,
                ),

                Text(
                  'No orders yet',
                  style: theme
                      .textTheme
                      .titleSmall
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'Your recent orders will appear here.',
                  textAlign:
                  TextAlign.center,
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color:
                    Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children:
            recentOrders.map(
                  (order) {
                return _buildRecentOrderCard(
                  context,
                  order,
                );
              },
            ).toList(),
          ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final isTablet =
        MediaQuery.of(context)
            .size
            .width >=
            600;

    return Scaffold(
      backgroundColor:
      AppTheme.backgroundLight,

      body: SafeArea(
        child: isTablet
            ? _buildTabletLayout()
            : _buildPhoneLayout(),
      ),

      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: () => context.push(
          AppRoutes.placeOrderScreen,
        ),
        icon:
        const Icon(
          Icons.add_rounded,
        ),
        label:
        const Text(
          'New Order',
        ),
        backgroundColor:
        AppTheme.primary,
        foregroundColor:
        Colors.white,
      ),
    );
  }

  // ============================================================
  // PHONE LAYOUT
  // ============================================================

  Widget _buildPhoneLayout() {
    final kpiData =
        _kpiData;

    return RefreshIndicator(
      onRefresh:
      _loadDashboardData,
      child:
      CustomScrollView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        slivers: [
          DashboardAppBarWidget(
            onNotificationTap: () {},
            onAvatarTap: () {},
          ),

          // ------------------------------------------------------
          // KPI
          // ------------------------------------------------------

          SliverToBoxAdapter(
            child: Padding(
              padding:
              const EdgeInsets
                  .fromLTRB(
                16,
                16,
                16,
                0,
              ),
              child:
              DashboardKpiGridWidget(
                kpiData:
                kpiData,
              ),
            ),
          ),



          // ------------------------------------------------------
          // RECENT ORDERS
          // ------------------------------------------------------

          SliverToBoxAdapter(
            child: Padding(
              padding:
              const EdgeInsets
                  .fromLTRB(
                16,
                20,
                16,
                100,
              ),
              child:
              _buildRecentOrdersSection(
                context,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABLET LAYOUT
  // ============================================================

  Widget _buildTabletLayout() {
    final kpiData =
        _kpiData;

    return Row(
      children: [
        // ========================================================
        // MAIN CONTENT
        // ========================================================

        Expanded(
          flex: 6,
          child:
          RefreshIndicator(
            onRefresh:
            _loadDashboardData,
            child:
            CustomScrollView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              slivers: [
                DashboardAppBarWidget(
                  onNotificationTap:
                      () {},
                  onAvatarTap:
                      () {},
                ),

                // ------------------------------------------------
                // FILTER CHIPS
                // ------------------------------------------------

                SliverToBoxAdapter(
                  child:
                  DashboardFilterChipsWidget(
                    filters:
                    _filters,
                    selected:
                    _selectedFilter,
                    onSelected:
                        (filter) {
                      setState(() {
                        _selectedFilter =
                            filter;
                      });
                    },
                  ),
                ),

                // ------------------------------------------------
                // HERO
                // ------------------------------------------------

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                    const EdgeInsets
                        .fromLTRB(
                      20,
                      8,
                      20,
                      0,
                    ),
                    child:
                    DashboardHeroWidget(
                      score:
                      kpiData[
                      'healthScore'] as int,
                      label:
                      kpiData[
                      'healthLabel'] as String,
                      filter:
                      _selectedFilter,
                    ),
                  ),
                ),

                // ------------------------------------------------
                // RECENT ORDERS
                // ------------------------------------------------

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                    const EdgeInsets
                        .fromLTRB(
                      20,
                      16,
                      20,
                      80,
                    ),
                    child:
                    _buildRecentOrdersSection(
                      context,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ========================================================
        // RIGHT SIDE
        // ========================================================

        Container(
          width: 320,
          padding:
          const EdgeInsets.fromLTRB(
            0,
            24,
            20,
            24,
          ),
          child:
          Column(
            children: [
              DashboardKpiGridWidget(
                kpiData:
                kpiData,
                columns: 2,
              ),

              const SizedBox(
                height: 16,
              ),

              DashboardQuickActionsWidget(
                onAddOrder: () =>
                    context.push(
                      AppRoutes
                          .placeOrderScreen,
                    ),
                onCollectPayment: () {},
                onReports: () =>
                    context.go(
                      AppRoutes
                          .reportsScreen,
                    ),
                onManage: () =>
                    context.go(
                      AppRoutes
                          .manageScreen,
                    ),
                vertical: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}