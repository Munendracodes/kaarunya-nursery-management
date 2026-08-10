import 'package:firebase_database/firebase_database.dart';

import '../models/order_model.dart';
import 'firebase_service.dart';

class OrderRepository {
  OrderRepository._();

  static final OrderRepository instance =
  OrderRepository._();

  final FirebaseService _firebase =
      FirebaseService.instance;

  // ============================================================
  // CREATE ORDER
  // ============================================================

  Future<String> createOrder({
    required String customerId,
    required String customerMobile,
    required String customerName,
    required String customerFatherName,
    required String customerVillage,
    required List<OrderItemModel> items,
    required double advancePayment,
  }) async {
    if (items.isEmpty) {
      throw Exception(
        'Order must contain at least one item.',
      );
    }

    // ==========================================================
    // CALCULATE TOTALS
    // ==========================================================

    double subtotal = 0;
    double totalDiscount = 0;

    for (final item in items) {
      subtotal +=
          item.price * item.quantity;

      totalDiscount +=
          item.discount;
    }

    final total =
        subtotal - totalDiscount;

    final totalPaid =
        advancePayment;

    final balance =
        total - totalPaid;

    if (totalPaid < 0) {
      throw Exception(
        'Advance payment cannot be negative.',
      );
    }

    if (totalPaid > total) {
      throw Exception(
        'Advance payment cannot be greater than order total.',
      );
    }

    // ==========================================================
    // DETERMINE PAYMENT STATUS
    // ==========================================================

    String paymentStatus;

    if (totalPaid <= 0) {
      paymentStatus = 'PENDING';
    } else if (balance <= 0) {
      paymentStatus = 'PAID';
    } else {
      paymentStatus = 'PARTIAL';
    }

    // ==========================================================
    // CREATE ORDER ID
    // ==========================================================

    final orderRef =
    _firebase.ordersRef.push();

    final orderId =
        orderRef.key;

    if (orderId == null) {
      throw Exception(
        'Unable to generate order ID.',
      );
    }

    // ==========================================================
    // ORDER NUMBER
    // ==========================================================

    final orderNumber =
        'ORD-${DateTime.now().millisecondsSinceEpoch}';

    // ==========================================================
    // ORDER DATA
    // ==========================================================

    final orderData =
    <String, dynamic>{
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerMobile':
      customerMobile.trim(),
      'customerName':
      customerName.trim(),
      'customerFatherName':
      customerFatherName.trim(),
      'customerVillage':
      customerVillage.trim(),

      'subtotal': subtotal,
      'discount': totalDiscount,
      'total': total,

      'totalPaid': totalPaid,
      'balance': balance,

      'orderStatus': 'ORDERED',
      'paymentStatus': paymentStatus,

      'createdAt':
      ServerValue.timestamp,
    };

    // ==========================================================
    // ORDER ITEMS
    // ==========================================================

    final itemsData =
    <String, dynamic>{};

    for (final item in items) {
      final itemRef =
      orderRef
          .child('items')
          .push();

      final itemId =
          itemRef.key;

      if (itemId == null) {
        throw Exception(
          'Unable to generate order item ID.',
        );
      }

      itemsData[itemId] =
          item.toMap();
    }

    orderData['items'] =
        itemsData;

    // ==========================================================
    // INITIAL PAYMENT
    // ==========================================================

    if (advancePayment > 0) {
      final paymentRef =
      orderRef
          .child('payments')
          .push();

      final paymentId =
          paymentRef.key;

      if (paymentId == null) {
        throw Exception(
          'Unable to generate payment ID.',
        );
      }

      orderData['payments'] = {
        paymentId: {
          'amount': advancePayment,
          'paymentDate':
          ServerValue.timestamp,
        },
      };
    }

    // ==========================================================
    // SAVE COMPLETE ORDER
    // ==========================================================

    await orderRef.set(
      orderData,
    );

    return orderId;
  }

  // ============================================================
  // GET ORDER
  // ============================================================

  Future<Map<String, dynamic>?>
  getOrder(
      String orderId,
      ) async {
    final snapshot =
    await _firebase.ordersRef
        .child(orderId)
        .get();

    if (!snapshot.exists ||
        snapshot.value == null) {
      return null;
    }

    return Map<String, dynamic>.from(
      snapshot.value as Map,
    );
  }

  // ============================================================
  // GET ALL ORDERS
  // ============================================================

  Future<List<Map<String, dynamic>>>
  getOrders() async {
    final snapshot =
    await _firebase.ordersRef.get();

    if (!snapshot.exists ||
        snapshot.value == null) {
      return [];
    }

    final rawData =
    Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );

    return rawData.entries.map((entry) {
      final orderId =
      entry.key.toString();

      final data =
      Map<String, dynamic>.from(
        Map<dynamic, dynamic>.from(
          entry.value as Map,
        ),
      );

      return {
        'id': orderId,
        ...data,
      };
    }).toList();
  }
}