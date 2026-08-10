import 'package:cloud_firestore/cloud_firestore.dart';

import './firebase_service.dart';

/// Repository for all Firestore CRUD operations
class FirestoreRepository {
  FirestoreRepository._();
  static final FirestoreRepository instance = FirestoreRepository._();

  final _fs = FirebaseService.instance;

  // Public accessor for auth settings (used by login)
  Future<Map<String, dynamic>?> getAuthSettings() async {
    try {
      final doc = await _fs.settings.doc('auth_settings').get();
      if (doc.exists) return doc.data() as Map<String, dynamic>?;
    } catch (_) {}
    return null;
  }

  // ─── Customers ─────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> watchCustomers() {
    return _fs.customers
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(_docToMap).toList());
  }

  Future<List<Map<String, dynamic>>> getCustomers({String? query}) async {
    Query q = _fs.customers.orderBy('name');
    final snap = await q.get();
    final all = snap.docs.map(_docToMap).toList();
    if (query != null && query.isNotEmpty) {
      final lower = query.toLowerCase();
      return all
          .where(
            (c) =>
                (c['name'] as String).toLowerCase().contains(lower) ||
                (c['mobile'] as String).contains(lower),
          )
          .toList();
    }
    return all;
  }

  Future<void> addCustomer(Map<String, dynamic> data) async {
    await _fs.customers.add({
      ...data,
      'totalOrders': 0,
      'totalAmount': 0.0,
      'pendingAmount': 0.0,
      'active': true,
      'createdAt': _fs.now,
      'updatedAt': _fs.now,
    });
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    await _fs.customers.doc(id).update({...data, 'updatedAt': _fs.now});
  }

  Future<void> toggleCustomerActive(String id, bool active) async {
    await _fs.customers.doc(id).update({
      'active': active,
      'updatedAt': _fs.now,
    });
  }

  // ─── Villages ──────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> watchVillages() {
    return _fs.villages
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(_docToMap).toList());
  }

  Future<List<Map<String, dynamic>>> getVillages() async {
    final snap = await _fs.villages.orderBy('name').get();
    return snap.docs.map(_docToMap).toList();
  }

  Future<void> addVillage(Map<String, dynamic> data) async {
    await _fs.villages.add({
      ...data,
      'customerCount': 0,
      'active': true,
      'createdAt': _fs.now,
      'updatedAt': _fs.now,
    });
  }

  Future<void> toggleVillageActive(String id, bool active) async {
    await _fs.villages.doc(id).update({'active': active, 'updatedAt': _fs.now});
  }

  // ─── Plants ────────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> watchPlants() {
    return _fs.plantVariants
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs.map(_docToMap).toList());
  }

  Future<List<Map<String, dynamic>>> getPlants({
    String? category,
    String? query,
  }) async {
    Query q = _fs.plantVariants.orderBy('name');
    if (category != null && category != 'All') {
      q = q.where('categoryId', isEqualTo: category);
    }
    final snap = await q.get();
    final all = snap.docs.map(_docToMap).toList();
    if (query != null && query.isNotEmpty) {
      final lower = query.toLowerCase();
      return all
          .where((p) => (p['name'] as String).toLowerCase().contains(lower))
          .toList();
    }
    return all;
  }

  Future<List<Map<String, dynamic>>> getPlantCategories() async {
    final snap = await _fs.plantCategories.orderBy('sortOrder').get();
    return snap.docs.map(_docToMap).toList();
  }

  Future<void> addPlant(Map<String, dynamic> data) async {
    await _fs.plantVariants.add({
      ...data,
      'active': true,
      'createdAt': _fs.now,
      'updatedAt': _fs.now,
    });
  }

  Future<void> updatePlantStock(String id, int stock) async {
    await _fs.plantVariants.doc(id).update({
      'stock': stock,
      'updatedAt': _fs.now,
    });
  }

  Future<void> togglePlantActive(String id, bool active) async {
    await _fs.plantVariants.doc(id).update({
      'active': active,
      'updatedAt': _fs.now,
    });
  }

  // ─── Orders ────────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> watchOrders() {
    return _fs.orders
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_docToMap).toList());
  }

  Future<List<Map<String, dynamic>>> getOrdersForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final snap = await _fs.orders
        .where(
          'orderDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          isLessThanOrEqualTo: Timestamp.fromDate(end),
        )
        .orderBy('orderDate')
        .get();
    return snap.docs.map(_docToMap).toList();
  }

  Future<List<Map<String, dynamic>>> getRecentOrders({int limit = 10}) async {
    final snap = await _fs.orders
        .orderBy('orderDate', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(_docToMap).toList();
  }

  Future<String> placeOrder(
    Map<String, dynamic> orderData,
    List<Map<String, dynamic>> items,
  ) async {
    final orderId = _fs.generateId();
    final batch = _fs.firestore.batch();

    // Create order
    batch.set(_fs.orders.doc(orderId), {
      ...orderData,
      'id': orderId,
      'status': 'pending',
      'itemCount': items.length,
      'createdAt': _fs.now,
      'updatedAt': _fs.now,
    });

    // Create order items
    for (final item in items) {
      final itemId = _fs.generateId();
      batch.set(_fs.orderItems.doc(itemId), {
        ...item,
        'id': itemId,
        'orderId': orderId,
        'createdAt': _fs.now,
      });
    }

    // Create advance payment if any
    final advance = (orderData['advanceAmount'] as num?)?.toDouble() ?? 0.0;
    if (advance > 0) {
      final payId = _fs.generateId();
      batch.set(_fs.payments.doc(payId), {
        'id': payId,
        'orderId': orderId,
        'customerId': orderData['customerId'],
        'customerName': orderData['customerName'],
        'amount': advance,
        'paymentMode': 'cash',
        'type': 'advance',
        'status': 'completed',
        'paidAt': _fs.now,
        'createdAt': _fs.now,
      });
    }

    await batch.commit();
    return orderId;
  }

  Future<void> updateOrderStatus(String id, String status) async {
    await _fs.orders.doc(id).update({'status': status, 'updatedAt': _fs.now});
  }

  // ─── Deliveries ────────────────────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> watchDeliveries() {
    return _fs.deliveries
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(_docToMap).toList());
  }

  Future<List<Map<String, dynamic>>> getDeliveries() async {
    final snap = await _fs.deliveries
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(_docToMap).toList();
  }

  Future<String> createDelivery(Map<String, dynamic> data) async {
    final id = _fs.generateId();
    await _fs.deliveries.doc(id).set({
      ...data,
      'id': id,
      'status': 'pending',
      'orderIds': data['orderIds'] ?? [],
      'createdAt': _fs.now,
      'updatedAt': _fs.now,
    });
    return id;
  }

  Future<void> updateDeliveryStatus(
    String deliveryId,
    String status, {
    Map<String, dynamic>? locationData,
  }) async {
    final update = <String, dynamic>{'status': status, 'updatedAt': _fs.now};
    if (locationData != null) {
      update['lastLocation'] = locationData;
      update['lastLocationAt'] = _fs.now;
    }
    if (status == 'delivered') {
      update['deliveredAt'] = _fs.now;
    } else if (status == 'in_transit') {
      update['startedAt'] = _fs.now;
    }
    await _fs.deliveries.doc(deliveryId).update(update);
  }

  Future<void> assignOrderToDelivery(String orderId, String deliveryId) async {
    final batch = _fs.firestore.batch();
    // Add orderId to delivery's orderIds array
    final deliveryDoc = await _fs.deliveries.doc(deliveryId).get();
    if (deliveryDoc.exists) {
      final data = deliveryDoc.data() as Map<String, dynamic>;
      final ids = List<String>.from(data['orderIds'] as List? ?? []);
      if (!ids.contains(orderId)) ids.add(orderId);
      batch.update(_fs.deliveries.doc(deliveryId), {
        'orderIds': ids,
        'updatedAt': _fs.now,
      });
    }
    // Update order with deliveryId
    batch.update(_fs.orders.doc(orderId), {
      'deliveryId': deliveryId,
      'status': 'confirmed',
      'updatedAt': _fs.now,
    });
    await batch.commit();
  }

  Future<void> removeOrderFromDelivery(
    String orderId,
    String deliveryId,
  ) async {
    final batch = _fs.firestore.batch();
    final deliveryDoc = await _fs.deliveries.doc(deliveryId).get();
    if (deliveryDoc.exists) {
      final data = deliveryDoc.data() as Map<String, dynamic>;
      final ids = List<String>.from(data['orderIds'] as List? ?? []);
      ids.remove(orderId);
      batch.update(_fs.deliveries.doc(deliveryId), {
        'orderIds': ids,
        'updatedAt': _fs.now,
      });
    }
    batch.update(_fs.orders.doc(orderId), {
      'deliveryId': FieldValue.delete(),
      'status': 'pending',
      'updatedAt': _fs.now,
    });
    await batch.commit();
  }

  // ─── Live Streams for Dashboard ────────────────────────────────────────────
  Stream<List<Map<String, dynamic>>> watchRecentOrders({int limit = 5}) {
    return _fs.orders
        .orderBy('orderDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(_docToMap).toList());
  }

  Stream<Map<String, dynamic>> watchDashboardStats(String filter) {
    final now = DateTime.now();
    DateTime start;
    switch (filter) {
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'All Time':
        start = DateTime(2020, 1, 1);
        break;
      default:
        start = DateTime(now.year, now.month, now.day);
    }

    return _fs.orders
        .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .snapshots()
        .asyncMap((ordersSnap) async {
          final orders = ordersSnap.docs.map(_docToMap).toList();
          double revenue = 0;
          double collected = 0;
          double pending = 0;
          int deliveries = 0;

          for (final o in orders) {
            revenue += (o['totalAmount'] as num?)?.toDouble() ?? 0;
            collected += (o['advanceAmount'] as num?)?.toDouble() ?? 0;
            pending += (o['pendingAmount'] as num?)?.toDouble() ?? 0;
            if (o['status'] == 'delivered' || o['status'] == 'paid') {
              deliveries++;
            }
          }

          final customersSnap = await _fs.customers.get();
          final villagesSnap = await _fs.villages.get();

          return {
            'totalOrders': orders.length,
            'revenue': revenue,
            'collected': collected,
            'pending': pending,
            'deliveries': deliveries,
            'customers': customersSnap.docs.length,
            'villages': villagesSnap.docs.length,
            'todaysOrders': orders.length,
            'healthScore': _calcHealthScore(revenue, collected),
            'healthLabel': _healthLabel(revenue, collected),
          };
        });
  }

  // ─── Payments ──────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getOrdersWithPending() async {
    final snap = await _fs.orders.orderBy('orderDate', descending: true).get();
    final all = snap.docs.map(_docToMap).toList();
    return all.where((o) {
      final pending = (o['pendingAmount'] as num?)?.toDouble() ?? 0;
      return pending > 0;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getPayments({int limit = 50}) async {
    final snap = await _fs.payments
        .orderBy('paidAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(_docToMap).toList();
  }

  Future<String> recordPayment(
    Map<String, dynamic> paymentData,
    String orderId,
    double amount,
  ) async {
    final payId = _fs.generateId();
    final batch = _fs.firestore.batch();

    // Create payment record
    batch.set(_fs.payments.doc(payId), {
      ...paymentData,
      'id': payId,
      'paidAt': _fs.now,
      'createdAt': _fs.now,
    });

    // Update order's pending and advance amounts
    final orderDoc = await _fs.orders.doc(orderId).get();
    if (orderDoc.exists) {
      final orderData = orderDoc.data() as Map<String, dynamic>;
      final currentAdvance =
          (orderData['advanceAmount'] as num?)?.toDouble() ?? 0;
      final currentPending =
          (orderData['pendingAmount'] as num?)?.toDouble() ?? 0;
      final newAdvance = currentAdvance + amount;
      final newPending = (currentPending - amount).clamp(0, double.infinity);
      final newStatus = newPending <= 0 ? 'paid' : orderData['status'];

      batch.update(_fs.orders.doc(orderId), {
        'advanceAmount': newAdvance,
        'pendingAmount': newPending,
        'status': newStatus,
        'updatedAt': _fs.now,
      });
    }

    await batch.commit();
    return payId;
  }

  // ─── Dashboard Stats ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getDashboardStats(String filter) async {
    final now = DateTime.now();
    DateTime start;
    switch (filter) {
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'All Time':
        start = DateTime(2020, 1, 1);
        break;
      default: // Today
        start = DateTime(now.year, now.month, now.day);
    }

    final ordersSnap = await _fs.orders
        .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();

    final orders = ordersSnap.docs.map(_docToMap).toList();
    double revenue = 0;
    double collected = 0;
    double pending = 0;
    int deliveries = 0;

    for (final o in orders) {
      revenue += (o['totalAmount'] as num?)?.toDouble() ?? 0;
      collected += (o['advanceAmount'] as num?)?.toDouble() ?? 0;
      pending += (o['pendingAmount'] as num?)?.toDouble() ?? 0;
      if (o['status'] == 'delivered' || o['status'] == 'paid') deliveries++;
    }

    final customersSnap = await _fs.customers.get();
    final villagesSnap = await _fs.villages.get();

    return {
      'totalOrders': orders.length,
      'revenue': revenue,
      'collected': collected,
      'pending': pending,
      'deliveries': deliveries,
      'customers': customersSnap.docs.length,
      'villages': villagesSnap.docs.length,
      'todaysOrders': orders.length,
      'healthScore': _calcHealthScore(revenue, collected),
      'healthLabel': _healthLabel(revenue, collected),
    };
  }

  int _calcHealthScore(double revenue, double collected) {
    if (revenue == 0) return 70;
    final rate = (collected / revenue * 100).clamp(0, 100);
    return (rate * 0.7 + 30).round();
  }

  String _healthLabel(double revenue, double collected) {
    if (revenue == 0) return 'No orders yet';
    final rate = collected / revenue;
    if (rate >= 0.9) return 'Business Thriving';
    if (rate >= 0.7) return 'Good Business Day';
    if (rate >= 0.5) return 'Moderate Collections';
    return 'Pending Collections High';
  }

  // ─── Reports ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getReportData(String period) async {
    final now = DateTime.now();
    DateTime start;
    switch (period) {
      case 'This Week':
        start = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'Last 3 Months':
        start = DateTime(now.year, now.month - 3, 1);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        break;
      default: // This Month
        start = DateTime(now.year, now.month, 1);
    }

    final ordersSnap = await _fs.orders
        .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();
    final orders = ordersSnap.docs.map(_docToMap).toList();

    double totalRevenue = 0;
    double totalCollected = 0;
    final Map<String, double> customerRevenue = {};
    final Map<String, int> plantCount = {};

    for (final o in orders) {
      final amt = (o['totalAmount'] as num?)?.toDouble() ?? 0;
      final adv = (o['advanceAmount'] as num?)?.toDouble() ?? 0;
      totalRevenue += amt;
      totalCollected += adv;
      final cName = o['customerName'] as String? ?? '';
      customerRevenue[cName] = (customerRevenue[cName] ?? 0) + amt;
    }

    final itemsSnap = await _fs.orderItems.get();
    for (final doc in itemsSnap.docs) {
      final data = _docToMap(doc);
      final pName = data['plantName'] as String? ?? '';
      final qty = (data['quantity'] as num?)?.toInt() ?? 0;
      plantCount[pName] = (plantCount[pName] ?? 0) + qty;
    }

    return {
      'totalRevenue': totalRevenue,
      'totalCollected': totalCollected,
      'pendingAmount': totalRevenue - totalCollected,
      'orderCount': orders.length,
      'collectionRate': totalRevenue > 0
          ? (totalCollected / totalRevenue * 100).round()
          : 0,
      'topCustomers': customerRevenue.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
      'topPlants': plantCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    };
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────
  Map<String, dynamic> _docToMap(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return {'id': doc.id, ...data};
  }
}
