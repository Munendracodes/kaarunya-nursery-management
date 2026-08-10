import 'package:firebase_database/firebase_database.dart';

import 'firebase_service.dart';

class CustomerRepository {
  CustomerRepository._();

  static final CustomerRepository instance =
  CustomerRepository._();

  final FirebaseService _firebase =
      FirebaseService.instance;

  // ============================================================
  // GET CUSTOMER
  // ============================================================

  /// Returns an existing customer using mobile number.
  ///
  /// Path:
  ///
  /// users/{mobileNumber}/customers/{customerMobile}
  Future<Map<String, dynamic>?> getCustomer(
      String mobileNumber,
      ) async {
    final cleanedNumber =
    mobileNumber.trim();

    if (cleanedNumber.isEmpty) {
      throw Exception(
        'Customer mobile number cannot be empty.',
      );
    }

    final snapshot =
    await _firebase.customersRef
        .child(cleanedNumber)
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
  // CREATE CUSTOMER
  // ============================================================

  /// Creates a new customer using the mobile number as ID.
  Future<void> createCustomer({
    required String mobileNumber,
    required String name,
    required String fatherName,
    required String village,
  }) async {
    final cleanedNumber =
    mobileNumber.trim();

    final cleanedName =
    name.trim();

    final cleanedFatherName =
    fatherName.trim();

    final cleanedVillage =
    village.trim();

    if (cleanedNumber.isEmpty) {
      throw Exception(
        'Customer mobile number is required.',
      );
    }

    if (cleanedName.isEmpty) {
      throw Exception(
        'Customer name is required.',
      );
    }

    if (cleanedVillage.isEmpty) {
      throw Exception(
        'Customer village is required.',
      );
    }

    await _firebase.customersRef
        .child(cleanedNumber)
        .set({
      'mobileNumber': cleanedNumber,
      'name': cleanedName,
      'fatherName': cleanedFatherName,
      'village': cleanedVillage,
      'createdAt': ServerValue.timestamp,
    });
  }

  // ============================================================
  // GET OR CREATE CUSTOMER
  // ============================================================

  /// Returns an existing customer.
  ///
  /// If the customer doesn't exist, creates a new customer.
  ///
  /// This is useful during order creation.
  Future<Map<String, dynamic>> getOrCreateCustomer({
    required String mobileNumber,
    required String name,
    required String fatherName,
    required String village,
  }) async {
    final cleanedNumber =
    mobileNumber.trim();

    final existingCustomer =
    await getCustomer(
      cleanedNumber,
    );

    if (existingCustomer != null) {
      return existingCustomer;
    }

    await createCustomer(
      mobileNumber: cleanedNumber,
      name: name,
      fatherName: fatherName,
      village: village,
    );

    return {
      'mobileNumber': cleanedNumber,
      'name': name.trim(),
      'fatherName': fatherName.trim(),
      'village': village.trim(),
    };
  }

  // ============================================================
  // SEARCH CUSTOMERS
  // ============================================================

  /// Returns all customers.
  ///
  /// We can use this later for customer search/filtering.
  Future<List<Map<String, dynamic>>>
  getCustomers() async {
    final snapshot =
    await _firebase.customersRef.get();

    if (!snapshot.exists ||
        snapshot.value == null) {
      return [];
    }

    final rawData =
    Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );

    return rawData.entries.map((entry) {
      final customerId =
      entry.key.toString();

      final data =
      Map<String, dynamic>.from(
        Map<dynamic, dynamic>.from(
          entry.value as Map,
        ),
      );

      return {
        'id': customerId,
        ...data,
      };
    }).toList();
  }
}