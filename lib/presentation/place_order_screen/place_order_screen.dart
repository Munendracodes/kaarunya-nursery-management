import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/order_model.dart';
import '../../services/firebase_service.dart';
import '../../services/customer_repository.dart';
import '../../services/order_repository.dart';
import '../../theme/app_theme.dart';

class PlaceOrderScreen extends StatefulWidget {
  const PlaceOrderScreen({super.key});

  @override
  State<PlaceOrderScreen> createState() =>
      _PlaceOrderScreenState();
}

class _PlaceOrderScreenState
    extends State<PlaceOrderScreen> {

  final FirebaseService _firebase =
      FirebaseService.instance;

  final CustomerRepository _customerRepository =
      CustomerRepository.instance;

  final OrderRepository _orderRepository =
      OrderRepository.instance;

  // ============================================================
  // CURRENT STEP
  // ============================================================

  int _currentStep = 0;

  // 0 = Items
  // 1 = Customer
  // 2 = Confirmation

  // ============================================================
  // ORDER ITEMS
  // ============================================================

  final List<OrderItemModel> _orderItems = [];

  // ============================================================
  // CUSTOMER
  // ============================================================

  final TextEditingController _mobileController =
  TextEditingController();

  final TextEditingController _nameController =
  TextEditingController();

  final TextEditingController _fatherNameController =
  TextEditingController();

  String? _selectedVillage;

  Map<String, dynamic>? _customer;

  bool _customerFound = false;
  bool _customerSearched = false;

  // ============================================================
  // PAYMENT
  // ============================================================

  final TextEditingController _advanceController =
  TextEditingController();

  bool _isSubmitting = false;

  // ============================================================
  // DATA
  // ============================================================

  List<Map<String, dynamic>> _plants = [];
  List<String> _villages = [];

  bool _loadingPlants = true;
  bool _loadingVillages = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadPlants();
    _loadVillages();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    _fatherNameController.dispose();
    _advanceController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD PLANTS
  // ============================================================

  Future<void> _loadPlants() async {
    try {
      final snapshot =
      await _firebase.plantsRef.get();

      if (!snapshot.exists ||
          snapshot.value == null) {
        setState(() {
          _plants = [];
          _loadingPlants = false;
        });

        return;
      }

      final raw =
      Map<dynamic, dynamic>.from(
        snapshot.value as Map,
      );

      final plants =
      raw.entries.map((entry) {
        final id = entry.key.toString();

        final data =
        Map<String, dynamic>.from(
          Map<dynamic, dynamic>.from(
            entry.value as Map,
          ),
        );

        return {
          'id': id,
          ...data,
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _plants = plants;
        _loadingPlants = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingPlants = false;
      });

      _showError(
        'Unable to load plants: $e',
      );
    }
  }

  // ============================================================
  // LOAD VILLAGES
  // ============================================================

  Future<void> _loadVillages() async {
    try {
      final snapshot =
      await _firebase.villagesRef.get();

      if (!snapshot.exists ||
          snapshot.value == null) {
        setState(() {
          _villages = [];
          _loadingVillages = false;
        });

        return;
      }

      final value = snapshot.value;

      final List<String> villages = [];

      if (value is Map) {
        for (final entry in value.entries) {
          final data = entry.value;

          if (data is Map) {
            final name =
            data['name']?.toString();

            if (name != null &&
                name.trim().isNotEmpty) {
              villages.add(name.trim());
            }
          } else if (data != null) {
            villages.add(
              data.toString(),
            );
          }
        }
      }

      villages.sort();

      if (!mounted) return;

      setState(() {
        _villages = villages;
        _loadingVillages = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingVillages = false;
      });
    }
  }

  // ============================================================
  // TOTALS
  // ============================================================

  double get _subtotal {
    return _orderItems.fold(
      0,
          (sum, item) =>
      sum + (item.price * item.quantity),
    );
  }

  double get _total {
    return _subtotal;
  }

  double get _advance {
    return double.tryParse(
      _advanceController.text.trim(),
    ) ??
        0;
  }

  double get _balance {
    final balance = _total - _advance;

    return balance < 0 ? 0 : balance;
  }

  // ============================================================
  // NEXT
  // ============================================================

  void _nextStep() {
    if (_currentStep == 0) {
      if (_orderItems.isEmpty) {
        _showError(
          'Please add at least one plant.',
        );
        return;
      }
    }

    if (_currentStep == 1) {
      if (!_validateCustomer()) {
        return;
      }
    }

    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
    } else {
      _placeOrder();
    }
  }

  // ============================================================
  // BACK
  // ============================================================

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      context.pop();
    }
  }

  // ============================================================
  // CUSTOMER SEARCH
  // ============================================================

  Future<void> _searchCustomer() async {
    final mobile =
    _mobileController.text.trim();

    if (mobile.isEmpty) {
      _showError(
        'Please enter customer mobile number.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      final customer =
      await _customerRepository.getCustomer(
        mobile,
      );

      if (!mounted) return;

      setState(() {
        _customerSearched = true;
        _customer = customer;
        _customerFound = customer != null;

        if (customer != null) {
          _nameController.text =
              customer['name']?.toString() ?? '';

          _fatherNameController.text =
              customer['fatherName']?.toString() ?? '';

          _selectedVillage =
              customer['village']?.toString();
        } else {
          _nameController.clear();
          _fatherNameController.clear();
          _selectedVillage = null;
        }
      });
    } catch (e) {
      _showError(
        'Unable to search customer: $e',
      );
    }
  }

  // ============================================================
  // VALIDATE CUSTOMER
  // ============================================================

  bool _validateCustomer() {
    final mobile =
    _mobileController.text.trim();

    if (mobile.isEmpty) {
      _showError(
        'Please enter customer mobile number.',
      );
      return false;
    }

    if (!_customerFound) {
      if (_nameController.text.trim().isEmpty) {
        _showError(
          'Please enter customer name.',
        );
        return false;
      }

      if (_selectedVillage == null ||
          _selectedVillage!.trim().isEmpty) {
        _showError(
          'Please select a village.',
        );
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // ADD / CREATE CUSTOMER
  // ============================================================

  Future<void> _ensureCustomerExists() async {
    final mobile =
    _mobileController.text.trim();

    if (_customerFound) {
      return;
    }

    final customer =
    await _customerRepository.getOrCreateCustomer(
      mobileNumber: mobile,
      name: _nameController.text.trim(),
      fatherName:
      _fatherNameController.text.trim(),
      village: _selectedVillage ?? '',
    );

    _customer = customer;
    _customerFound = true;
  }

  // ============================================================
  // PLACE ORDER
  // ============================================================

  Future<void> _placeOrder() async {
    if (_orderItems.isEmpty) {
      _showError(
        'Please add at least one item.',
      );
      return;
    }

    if (!_validateCustomer()) {
      return;
    }

    if (_advance > _total) {
      _showError(
        'Advance payment cannot exceed order total.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Make sure customer exists.
      await _ensureCustomerExists();

      final orderId =
      await _orderRepository.createOrder(
        customerId:
        _mobileController.text.trim(),
        customerMobile:
        _mobileController.text.trim(),
        customerName:
        _nameController.text.trim(),
        customerFatherName:
        _fatherNameController.text.trim(),
        customerVillage:
        _selectedVillage ?? '',
        items: _orderItems,
        advancePayment: _advance,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      await _showSuccess(orderId);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      _showError(
        'Failed to place order: $e',
      );
    }
  }

  // ============================================================
  // ADD ITEM
  // ============================================================

  Future<void> _addOrderItem() async {
    if (_plants.isEmpty) {
      _showError(
        'No plants available. Please add plants first.',
      );
      return;
    }

    final result =
    await showDialog<OrderItemModel>(
      context: context,
      builder: (_) =>
          _AddOrderItemDialog(
            plants: _plants,
            firebase: _firebase,
          ),
    );

    if (result == null) return;

    setState(() {
      _orderItems.add(result);
    });
  }

  // ============================================================
  // EDIT ITEM
  // ============================================================

  Future<void> _editOrderItem(
      int index,
      ) async {
    final item =
    _orderItems[index];

    final result =
    await showDialog<OrderItemModel>(
      context: context,
      builder: (_) =>
          _EditOrderItemDialog(
            item: item,
          ),
    );

    if (result == null) return;

    setState(() {
      _orderItems[index] = result;
    });
  }

  // ============================================================
  // DELETE ITEM
  // ============================================================

  void _removeOrderItem(
      int index,
      ) {
    setState(() {
      _orderItems.removeAt(index);
    });
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        AppTheme.error,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // SUCCESS
  // ============================================================

  Future<void> _showSuccess(
      String orderId,
      ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(20),
          ),
          contentPadding:
          const EdgeInsets.all(28),
          content: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration:
                BoxDecoration(
                  color: AppTheme
                      .primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color:
                  AppTheme.primary,
                  size: 36,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Order Placed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                'Order has been placed successfully.',
                textAlign:
                TextAlign.center,
                style: TextStyle(
                  color:
                  Colors.grey.shade600,
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              SizedBox(
                width: double.infinity,
                child:
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop();

                    context.pop();
                  },
                  style:
                  ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    AppTheme.primary,
                    foregroundColor:
                    Colors.white,
                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 14,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius
                          .circular(
                        12,
                      ),
                    ),
                  ),
                  child:
                  const Text(
                    'Done',
                  ),
                ),
              ),
            ],
          ),
        );
      },
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

    return Scaffold(
      backgroundColor:
      AppTheme.backgroundLight,

      appBar: AppBar(
        backgroundColor:
        theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed:
          _previousStep,
        ),
        title: Text(
          _currentStep == 0
              ? 'Create Order'
              : _currentStep == 1
              ? 'Customer'
              : 'Confirm Order',
          style: theme
              .textTheme
              .titleLarge
              ?.copyWith(
            fontWeight:
            FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: IndexedStack(
          index: _currentStep,
          children: [
            _buildItemsStep(),
            _buildCustomerStep(),
            _buildConfirmationStep(),
          ],
        ),
      ),

      bottomNavigationBar:
      _buildBottomBar(),
    );
  }

  // ============================================================
  // ITEMS STEP
  // ============================================================

  Widget _buildItemsStep() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              20,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [


                if (_orderItems.isEmpty)
                  _buildEmptyItems()
                else
                  ...List.generate(
                    _orderItems.length,
                        (index) =>
                        _buildOrderItemCard(
                          index,
                          _orderItems[index],
                        ),
                  ),

                const SizedBox(
                  height: 12,
                ),

                _buildTotalCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY ITEMS
  // ============================================================

  Widget _buildEmptyItems() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(
        vertical: 40,
        horizontal: 24,
      ),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons
                .local_florist_outlined,
            size: 48,
            color:
            AppTheme.primary
                .withAlpha(150),
          ),
          const SizedBox(
            height: 12,
          ),
          const Text(
            'No plants added',
            style: TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 6,
          ),
          Text(
            'Add the plants and variants required for this order.',
            textAlign:
            TextAlign.center,
            style: TextStyle(
              color:
              Colors.grey.shade600,
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          ElevatedButton.icon(
            onPressed:
            _loadingPlants
                ? null
                : _addOrderItem,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label:
            const Text(
              'Add Plant',
            ),
            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              AppTheme.primary,
              foregroundColor:
              Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ITEM CARD
  // ============================================================

  Widget _buildOrderItemCard(
      int index,
      OrderItemModel item,
      ) {
    final itemTotal =
        item.price * item.quantity;

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withAlpha(
              7,
            ),
            blurRadius: 8,
            offset:
            const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration:
                BoxDecoration(
                  color: AppTheme
                      .primaryContainer,
                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                ),
                child: const Icon(
                  Icons
                      .local_florist_rounded,
                  color:
                  AppTheme.primary,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      item.plantName,
                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      '${item.varietyName} • ${item.variantName}',
                      style:
                      TextStyle(
                        color: Colors
                            .grey
                            .shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                onPressed: () =>
                    _editOrderItem(
                      index,
                    ),
                icon: const Icon(
                  Icons
                      .edit_rounded,
                  size: 20,
                ),
              ),

              IconButton(
                onPressed: () =>
                    _removeOrderItem(
                      index,
                    ),
                icon: Icon(
                  Icons
                      .delete_outline_rounded,
                  color:
                  AppTheme.error,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              _infoChip(
                Icons
                    .inventory_2_outlined,
                'Qty ${item.quantity}',
              ),
              const SizedBox(
                width: 8,
              ),
              _infoChip(
                Icons
                    .scale_outlined,
                '${item.weight} kg',
              ),
              const SizedBox(
                width: 8,
              ),
              _infoChip(
                Icons
                    .currency_rupee_rounded,
                '₹${item.price.toStringAsFixed(0)}',
              ),
            ],
          ),


          const Divider(
            height: 22,
          ),

          Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
            children: [
              const Text(
                'Item Total',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
              Text(
                '₹${itemTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight:
                  FontWeight.w800,
                  color:
                  AppTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(
      IconData icon,
      String text,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
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
            width: 4,
          ),
          Text(
            text,
            style:
            const TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOTAL CARD
  // ============================================================

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _summaryRow(
            'Item Subtotal',
            '₹${_subtotal.toStringAsFixed(2)}',
          ),


          const Divider(
            height: 20,
          ),

          _summaryRow(
            'Grand Total',
            '₹${_total.toStringAsFixed(2)}',
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
      String label,
      String value, {
        bool bold = false,
      }) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment
          .spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: bold
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold
                ? FontWeight.w800
                : FontWeight.w600,
            fontSize:
            bold ? 18 : 14,
            color: bold
                ? AppTheme.primary
                : null,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CUSTOMER STEP
  // ============================================================

  Widget _buildCustomerStep() {
    return SingleChildScrollView(
      padding:
      const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller:
            _mobileController,
            label:
            'Customer Mobile Number',
            hint:
            'Enter mobile number',
            icon:
            Icons.phone_rounded,
            keyboardType:
            TextInputType.phone,
          ),

          const SizedBox(
            height: 10,
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
              _searchCustomer,
              icon: const Icon(
                Icons.search_rounded,
              ),
              label: const Text(
                'Search Customer',
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                AppTheme.primary,
                foregroundColor:
                Colors.white,
                padding:
                const EdgeInsets
                    .symmetric(
                  vertical: 14,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                ),
              ),
            ),
          ),

          if (_customerSearched) ...[
            const SizedBox(
              height: 20,
            ),
            if (_customerFound)
              _buildExistingCustomer()
            else
              _buildNewCustomer(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // EXISTING CUSTOMER
  // ============================================================

  Widget _buildExistingCustomer() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color:
        AppTheme.primaryContainer,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          AppTheme.primary.withAlpha(
            50,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons
                    .check_circle_rounded,
                color:
                AppTheme.primary,
              ),
              const SizedBox(
                width: 8,
              ),
              const Text(
                'Customer Found',
                style: TextStyle(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          _customerInfoRow(
            'Name',
            _nameController.text,
          ),
          _customerInfoRow(
            'Father Name',
            _fatherNameController.text,
          ),
          _customerInfoRow(
            'Village',
            _selectedVillage ?? '-',
          ),
          _customerInfoRow(
            'Mobile',
            _mobileController.text,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NEW CUSTOMER
  // ============================================================

  Widget _buildNewCustomer() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.all(14),
          decoration:
          BoxDecoration(
            color:
            Colors.orange.shade50,
            borderRadius:
            BorderRadius.circular(
              12,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons
                    .person_add_alt_1_rounded,
                color:
                Colors.orange.shade700,
              ),
              const SizedBox(
                width: 8,
              ),
              const Expanded(
                child: Text(
                  'New customer. Please enter the details below.',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        _buildTextField(
          controller:
          _nameController,
          label:
          'Customer Name',
          hint:
          'Enter customer name',
          icon:
          Icons.person_outline_rounded,
        ),

        const SizedBox(
          height: 14,
        ),

        _buildTextField(
          controller:
          _fatherNameController,
          label:
          'Father Name',
          hint:
          'Enter father name',
          icon:
          Icons.person_outline_rounded,
        ),

        const SizedBox(
          height: 14,
        ),

        _buildVillageAutocomplete(),
      ],
    );
  }

  // ============================================================
  // VILLAGE AUTOCOMPLETE
  // ============================================================

  Widget _buildVillageAutocomplete() {
    return Autocomplete<String>(
      initialValue:
      _selectedVillage != null
          ? TextEditingValue(
        text:
        _selectedVillage!,
      )
          : null,
      optionsBuilder:
          (TextEditingValue value) {
        if (value.text.isEmpty) {
          return _villages;
        }

        return _villages.where(
              (village) =>
              village
                  .toLowerCase()
                  .contains(
                value.text
                    .toLowerCase(),
              ),
        );
      },
      onSelected:
          (String village) {
        setState(() {
          _selectedVillage =
              village;
        });
      },
      fieldViewBuilder: (
          context,
          controller,
          focusNode,
          onFieldSubmitted,
          ) {
        if (_selectedVillage != null &&
            controller.text.isEmpty) {
          controller.text =
          _selectedVillage!;
        }

        return TextField(
          controller:
          controller,
          focusNode:
          focusNode,
          onChanged:
              (value) {
            _selectedVillage =
                value;
          },
          decoration:
          InputDecoration(
            labelText:
            'Village',
            hintText:
            'Search village',
            prefixIcon:
            const Icon(
              Icons
                  .location_on_outlined,
            ),
            suffixIcon:
            _loadingVillages
                ? const SizedBox(
              width: 20,
              height: 20,
              child:
              Padding(
                padding:
                EdgeInsets
                    .all(
                  12,
                ),
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,
                ),
              ),
            )
                : null,
            filled: true,
            fillColor:
            Colors.white,
            border:
            OutlineInputBorder(
              borderRadius:
              BorderRadius
                  .circular(
                12,
              ),
              borderSide:
              BorderSide(
                color:
                Colors.grey
                    .shade300,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _customerInfoRow(
      String label,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style:
              TextStyle(
                color: Colors
                    .grey
                    .shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIRMATION STEP
  // ============================================================

  Widget _buildConfirmationStep() {
    return SingleChildScrollView(
      padding:
      const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          _buildConfirmationCustomer(),

          const SizedBox(
            height: 16,
          ),

          ..._orderItems.map(
                (item) =>
                _buildConfirmationItem(
                  item,
                ),
          ),

          const SizedBox(
            height: 8,
          ),

          _buildTotalCard(),

          const SizedBox(
            height: 16,
          ),

          _buildPaymentCard(),
        ],
      ),
    );
  }

  Widget _buildConfirmationCustomer() {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          _customerInfoRow(
            'Name',
            _nameController.text,
          ),
          _customerInfoRow(
            'Father Name',
            _fatherNameController.text,
          ),
          _customerInfoRow(
            'Mobile',
            _mobileController.text,
          ),
          _customerInfoRow(
            'Village',
            _selectedVillage ?? '-',
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationItem(
      OrderItemModel item,
      ) {
    final total =
        item.price * item.quantity;

    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.only(
        bottom: 10,
      ),
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
            BoxDecoration(
              color: AppTheme
                  .primaryContainer,
              borderRadius:
              BorderRadius.circular(
                11,
              ),
            ),
            child: const Icon(
              Icons
                  .local_florist_rounded,
              color:
              AppTheme.primary,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  item.plantName,
                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  '${item.varietyName} • ${item.variantName}',
                  style:
                  TextStyle(
                    fontSize: 12,
                    color: Colors
                        .grey
                        .shade600,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  'Qty: ${item.quantity} × ₹${item.price.toStringAsFixed(0)}',
                  style:
                  TextStyle(
                    fontSize: 12,
                    color: Colors
                        .grey
                        .shade700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style:
            const TextStyle(
              fontWeight:
              FontWeight.w800,
              color:
              AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  Widget _buildPaymentCard() {
    return Container(
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
          Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Advance Payment',
            style: TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w700,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          _buildTextField(
            controller:
            _advanceController,
            label:
            'Amount Received',
            hint:
            'Enter advance amount',
            icon:
            Icons
                .currency_rupee_rounded,
            keyboardType:
            const TextInputType
                .numberWithOptions(
              decimal: true,
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),
          const SizedBox(
            height: 16,
          ),
          _summaryRow(
            'Total',
            '₹${_total.toStringAsFixed(2)}',
          ),
          const SizedBox(
            height: 8,
          ),
          _summaryRow(
            'Paid',
            '₹${_advance.toStringAsFixed(2)}',
          ),
          const Divider(
            height: 20,
          ),
          _summaryRow(
            'Balance',
            '₹${_balance.toStringAsFixed(2)}',
            bold: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController
    controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    ValueChanged<String>?
    onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
      keyboardType,
      onChanged:
      onChanged,
      decoration:
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
        Icon(icon),
        filled: true,
        fillColor:
        Colors.white,
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          borderSide:
          BorderSide(
            color:
            Colors.grey.shade300,
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          borderSide:
          BorderSide(
            color:
            Colors.grey.shade300,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            12,
          ),
          borderSide:
          const BorderSide(
            color:
            AppTheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
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
          child: Icon(
            icon,
            color:
            AppTheme.primary,
          ),
        ),
        const SizedBox(
          width: 12,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              Text(
                title,
                style:
                const TextStyle(
                  fontSize: 20,
                  fontWeight:
                  FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text(
                subtitle,
                style:
                TextStyle(
                  fontSize: 13,
                  color: Colors
                      .grey
                      .shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================

  Widget _buildBottomBar() {
    final isItemsStep =
        _currentStep == 0;

    final isLast =
        _currentStep == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        6,
        16,
        16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ==========================================================
          // ITEMS STEP - ADD ANOTHER PLANT
          // ==========================================================

          if (isItemsStep) ...[
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: Colors.grey,
            ),

            const SizedBox(
              height: 2,
            ),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                _loadingPlants
                    ? null
                    : _addOrderItem,
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label: const Text(
                  'Add Another Plant',
                ),
                style:
                OutlinedButton.styleFrom(
                  foregroundColor:
                  AppTheme.primary,
                  side: BorderSide(
                    color: AppTheme.primary
                        .withAlpha(100),
                  ),
                  padding:
                  const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      13,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 10,
            ),
          ],

          // ==========================================================
          // BACK + CONTINUE / PLACE ORDER
          // ==========================================================

          Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed:
                    _isSubmitting
                        ? null
                        : _previousStep,
                    style:
                    OutlinedButton.styleFrom(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        vertical: 15,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          13,
                        ),
                      ),
                    ),
                    child:
                    const Text(
                      'Back',
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),
              ],

              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed:
                  _isSubmitting
                      ? null
                      : _nextStep,
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    AppTheme.primary,
                    foregroundColor:
                    Colors.white,
                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 15,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        13,
                      ),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : Text(
                    isLast
                        ? 'Place Order'
                        : 'Continue',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// ADD ORDER ITEM DIALOG
// ============================================================================

class _AddOrderItemDialog
    extends StatefulWidget {

  final List<Map<String, dynamic>>
  plants;

  final FirebaseService firebase;

  const _AddOrderItemDialog({
    required this.plants,
    required this.firebase,
  });

  @override
  State<_AddOrderItemDialog>
  createState() =>
      _AddOrderItemDialogState();
}

class _AddOrderItemDialogState
    extends State<_AddOrderItemDialog> {

  Map<String, dynamic>? _plant;
  Map<String, dynamic>? _variety;
  Map<String, dynamic>? _variant;

  List<Map<String, dynamic>>
  _varieties = [];

  List<Map<String, dynamic>>
  _variants = [];

  bool _loadingVarieties = false;
  bool _loadingVariants = false;

  int _quantity = 1;

  late TextEditingController
  _priceController;


  @override
  void initState() {
    super.initState();

    _priceController =
        TextEditingController();

  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD VARIETIES
  // ============================================================

  Future<void> _loadVarieties(
      String plantId,
      ) async {
    setState(() {
      _loadingVarieties = true;
      _varieties = [];
      _variants = [];
      _variety = null;
      _variant = null;
      _priceController.clear();
    });

    try {
      final snapshot =
      await widget.firebase
          .plantsRef
          .child(plantId)
          .child('varieties')
          .get();

      if (!snapshot.exists ||
          snapshot.value == null) {
        setState(() {
          _loadingVarieties = false;
        });
        return;
      }

      final raw =
      Map<dynamic, dynamic>.from(
        snapshot.value as Map,
      );

      final data =
      raw.entries.map((entry) {
        return {
          'id': entry.key.toString(),
          ...Map<String, dynamic>.from(
            Map<dynamic, dynamic>.from(
              entry.value as Map,
            ),
          ),
        };
      }).toList();

      setState(() {
        _varieties = data;
        _loadingVarieties = false;
      });
    } catch (e) {
      setState(() {
        _loadingVarieties = false;
      });
    }
  }

  // ============================================================
  // LOAD VARIANTS
  // ============================================================

  Future<void> _loadVariants(
      String plantId,
      String varietyId,
      ) async {
    setState(() {
      _loadingVariants = true;
      _variants = [];
      _variant = null;
      _priceController.clear();
    });

    try {
      final snapshot =
      await widget.firebase
          .plantsRef
          .child(plantId)
          .child('varieties')
          .child(varietyId)
          .child('variants')
          .get();

      if (!snapshot.exists ||
          snapshot.value == null) {
        setState(() {
          _loadingVariants = false;
        });
        return;
      }

      final raw =
      Map<dynamic, dynamic>.from(
        snapshot.value as Map,
      );

      final data =
      raw.entries.map((entry) {
        return {
          'id': entry.key.toString(),
          ...Map<String, dynamic>.from(
            Map<dynamic, dynamic>.from(
              entry.value as Map,
            ),
          ),
        };
      }).toList();

      setState(() {
        _variants = data;
        _loadingVariants = false;
      });
    } catch (e) {
      setState(() {
        _loadingVariants = false;
      });
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _save() {
    if (_plant == null) {
      _error(
        'Please select a plant.',
      );
      return;
    }

    if (_variety == null) {
      _error(
        'Please select a variety.',
      );
      return;
    }

    if (_variant == null) {
      _error(
        'Please select a variant.',
      );
      return;
    }

    final price =
    double.tryParse(
      _priceController.text.trim(),
    );

    if (price == null ||
        price < 0) {
      _error(
        'Please enter a valid price.',
      );
      return;
    }

    final itemTotal =
        price * _quantity;

    final result =
    OrderItemModel(
      plantId:
      _plant!['id'].toString(),
      plantName:
      _plant!['name']
          ?.toString() ??
          '',
      varietyId:
      _variety!['id'].toString(),
      varietyName:
      _variety!['name']
          ?.toString() ??
          '',
      variantId:
      _variant!['id'].toString(),
      variantName:
      _variant!['name']
          ?.toString() ??
          '',
      weight:
      _toDouble(
        _variant!['weight'],
      ),
      years:
      _toInt(
        _variant!['years'],
      ),
      quantity:
      _quantity,
      price:
      price,
      discount:
      0,
      total:
      itemTotal,
    );

    Navigator.of(context)
        .pop(result);
  }

  double _toDouble(
      dynamic value,
      ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  int _toInt(
      dynamic value,
      ) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  void _error(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(message),
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
      title: const Text(
        'Add Plant',
        style: TextStyle(
          fontWeight:
          FontWeight.w700,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            _buildPlantDropdown(),

            const SizedBox(
              height: 14,
            ),

            _buildVarietyDropdown(),

            const SizedBox(
              height: 14,
            ),

            _buildVariantDropdown(),

            const SizedBox(
              height: 16,
            ),

            _buildQuantity(),

            const SizedBox(
              height: 14,
            ),

            TextField(
              controller:
              _priceController,
              keyboardType:
              const TextInputType
                  .numberWithOptions(
                decimal: true,
              ),
              decoration:
              const InputDecoration(
                labelText:
                'Price',
                prefixIcon:
                Icon(
                  Icons
                      .currency_rupee_rounded,
                ),
              ),
            ),

          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(
                context,
              ).pop(),
          child:
          const Text(
            'Cancel',
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style:
          ElevatedButton.styleFrom(
            backgroundColor:
            AppTheme.primary,
            foregroundColor:
            Colors.white,
          ),
          child:
          const Text(
            'Add Plant',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PLANT DROPDOWN
  // ============================================================

  Widget _buildPlantDropdown() {
    return DropdownButtonFormField<
        Map<String, dynamic>>(
      value: _plant,
      isExpanded: true,
      decoration:
      const InputDecoration(
        labelText:
        'Plant',
        prefixIcon:
        Icon(
          Icons
              .local_florist_rounded,
        ),
      ),
      items:
      widget.plants.map(
            (plant) {
          return DropdownMenuItem<
              Map<String, dynamic>>(
            value: plant,
            child: Text(
              plant['name']
                  ?.toString() ??
                  'Unnamed Plant',
            ),
          );
        },
      ).toList(),
      onChanged:
          (plant) {
        if (plant == null) return;

        setState(() {
          _plant = plant;
        });

        _loadVarieties(
          plant['id'].toString(),
        );
      },
    );
  }

  // ============================================================
  // VARIETY DROPDOWN
  // ============================================================

  Widget _buildVarietyDropdown() {
    return DropdownButtonFormField<
        Map<String, dynamic>>(
      value: _variety,
      isExpanded: true,
      decoration:
      const InputDecoration(
        labelText:
        'Variety',
        prefixIcon:
        Icon(
          Icons
              .spa_outlined,
        ),
      ),
      items:
      _varieties.map(
            (variety) {
          return DropdownMenuItem<
              Map<String, dynamic>>(
            value: variety,
            child: Text(
              variety['name']
                  ?.toString() ??
                  'Unnamed Variety',
            ),
          );
        },
      ).toList(),
      onChanged:
      _loadingVarieties
          ? null
          : (variety) {
        if (variety ==
            null) {
          return;
        }

        setState(() {
          _variety =
              variety;
        });

        _loadVariants(
          _plant!['id']
              .toString(),
          variety['id']
              .toString(),
        );
      },
    );
  }

  // ============================================================
  // VARIANT DROPDOWN
  // ============================================================

  Widget _buildVariantDropdown() {
    return DropdownButtonFormField<
        Map<String, dynamic>>(
      value: _variant,
      isExpanded: true,
      decoration:
      InputDecoration(
        labelText:
        'Variant',
        prefixIcon:
        const Icon(
          Icons
              .inventory_2_outlined,
        ),
        suffixIcon:
        _loadingVariants
            ? const SizedBox(
          width: 20,
          height: 20,
          child:
          Padding(
            padding:
            EdgeInsets
                .all(
              10,
            ),
            child:
            CircularProgressIndicator(
              strokeWidth:
              2,
            ),
          ),
        )
            : null,
      ),
      items:
      _variants.map(
            (variant) {
          final weight =
              variant['weight']
                  ?.toString() ??
                  '';

          final years =
              variant['years']
                  ?.toString() ??
                  '';

          return DropdownMenuItem<
              Map<String, dynamic>>(
            value: variant,
            child: Text(
              '${variant['name'] ?? ''} • ${weight}kg • ${years} years',
              overflow:
              TextOverflow
                  .ellipsis,
            ),
          );
        },
      ).toList(),
      onChanged:
      _loadingVariants
          ? null
          : (variant) {
        if (variant ==
            null) {
          return;
        }

        setState(() {
          _variant =
              variant;

          _priceController
              .text =
              _toDouble(
                variant[
                'price'],
              ).toStringAsFixed(
                2,
              );
        });
      },
    );
  }

  // ============================================================
  // QUANTITY
  // ============================================================

  Widget _buildQuantity() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.grey.shade50,
        borderRadius:
        BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color:
          Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Quantity',
              style: TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),

          IconButton(
            onPressed:
            _quantity > 1
                ? () {
              setState(() {
                _quantity--;
              });
            }
                : null,
            icon:
            const Icon(
              Icons
                  .remove_circle_outline,
            ),
          ),

          Text(
            '$_quantity',
            style:
            const TextStyle(
              fontSize: 17,
              fontWeight:
              FontWeight.w700,
            ),
          ),

          IconButton(
            onPressed: () {
              setState(() {
                _quantity++;
              });
            },
            icon:
            const Icon(
              Icons
                  .add_circle_outline,
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// EDIT ORDER ITEM DIALOG
// ============================================================================

class _EditOrderItemDialog
    extends StatefulWidget {

  final OrderItemModel item;

  const _EditOrderItemDialog({
    required this.item,
  });

  @override
  State<_EditOrderItemDialog>
  createState() =>
      _EditOrderItemDialogState();
}

class _EditOrderItemDialogState
    extends State<_EditOrderItemDialog> {

  late int _quantity;

  late TextEditingController
  _priceController;


  @override
  void initState() {
    super.initState();

    _quantity =
        widget.item.quantity;

    _priceController =
        TextEditingController(
          text: widget.item.price
              .toStringAsFixed(2),
        );

  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _save() {
    final price =
    double.tryParse(
      _priceController.text.trim(),
    );

    if (price == null ||
        price < 0) {
      _error(
        'Enter a valid price.',
      );
      return;
    }

    final total =
        price * _quantity;

    Navigator.of(context)
        .pop(
      OrderItemModel(
        plantId:
        widget.item.plantId,
        plantName:
        widget.item.plantName,
        varietyId:
        widget.item.varietyId,
        varietyName:
        widget.item.varietyName,
        variantId:
        widget.item.variantId,
        variantName:
        widget.item.variantName,
        weight:
        widget.item.weight,
        years:
        widget.item.years,
        quantity:
        _quantity,
        price:
        price,
        discount:
        0,
        total:
        total,
      ),
    );
  }

  void _error(
      String message,
      ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content:
        Text(message),
      ),
    );
  }

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
      title: const Text(
        'Edit Item',
        style: TextStyle(
          fontWeight:
          FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          Align(
            alignment:
            Alignment.centerLeft,
            child: Text(
              '${widget.item.plantName} • ${widget.item.varietyName}',
              style:
              TextStyle(
                color:
                Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Align(
            alignment:
            Alignment.centerLeft,
            child: Text(
              widget.item.variantName,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(
            height: 18,
          ),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Quantity',
                ),
              ),
              IconButton(
                onPressed:
                _quantity > 1
                    ? () {
                  setState(() {
                    _quantity--;
                  });
                }
                    : null,
                icon:
                const Icon(
                  Icons
                      .remove_circle_outline,
                ),
              ),
              Text(
                '$_quantity',
                style:
                const TextStyle(
                  fontWeight:
                  FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _quantity++;
                  });
                },
                icon:
                const Icon(
                  Icons
                      .add_circle_outline,
                ),
              ),
            ],
          ),
          TextField(
            controller:
            _priceController,
            keyboardType:
            const TextInputType
                .numberWithOptions(
              decimal: true,
            ),
            decoration:
            const InputDecoration(
              labelText:
              'Price',
              prefixIcon:
              Icon(
                Icons
                    .currency_rupee_rounded,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(
                context,
              ).pop(),
          child:
          const Text(
            'Cancel',
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style:
          ElevatedButton.styleFrom(
            backgroundColor:
            AppTheme.primary,
            foregroundColor:
            Colors.white,
          ),
          child:
          const Text(
            'Save',
          ),
        ),
      ],
    );
  }
}
