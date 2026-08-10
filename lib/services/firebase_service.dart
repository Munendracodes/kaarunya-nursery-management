import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance =
  FirebaseService._();

  // ============================================================
  // CORE FIREBASE INSTANCES
  // ============================================================

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  // Use Firebase.app() instead of FirebaseDatabase.instance.app
  // to avoid accessing the app reference before Firebase is
  // fully initialized.
  final FirebaseDatabase database =
  FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
    'https://karunya-nursery-management-default-rtdb.asia-southeast1.firebasedatabase.app/',
  );

  final FirebaseStorage storage =
      FirebaseStorage.instance;

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? _mobileNumber;

  /// Set the mobile number of the currently logged-in user.
  ///
  /// For now we are using the mobile number as the user identifier.
  /// Later, when Firebase Authentication is implemented properly,
  /// this can be changed to use Firebase Auth UID.
  void setCurrentUser(String mobileNumber) {
    final cleanedNumber = mobileNumber.trim();

    if (cleanedNumber.isEmpty) {
      throw Exception(
        'Mobile number cannot be empty.',
      );
    }

    _mobileNumber = cleanedNumber;
  }

  /// Returns the currently logged-in user's mobile number.
  String get mobileNumber {
    if (_mobileNumber == null ||
        _mobileNumber!.isEmpty) {
      throw Exception(
        'Current user mobile number has not been initialized.',
      );
    }

    return _mobileNumber!;
  }

  // ============================================================
  // USER ROOT
  // ============================================================

  /// users/{mobileNumber}
  DatabaseReference get userRef {
    return database.ref(
      'users/$mobileNumber',
    );
  }

  // ============================================================
  // USER PROFILE
  // ============================================================

  /// users/{mobileNumber}/profile
  DatabaseReference get profileRef {
    return userRef.child('profile');
  }

  // ============================================================
  // USER PLANTS
  // ============================================================

  /// users/{mobileNumber}/plants
  DatabaseReference get plantsRef {
    return userRef.child('plants');
  }

  // ============================================================
  // USER CUSTOMERS
  // ============================================================

  /// users/{mobileNumber}/customers
  DatabaseReference get customersRef {
    return userRef.child('customers');
  }

  // ============================================================
  // USER VILLAGES
  // ============================================================

  /// users/{mobileNumber}/villages
  DatabaseReference get villagesRef {
    return userRef.child('villages');
  }

  // ============================================================
  // USER ORDERS
  // ============================================================

  /// users/{mobileNumber}/orders
  DatabaseReference get ordersRef {
    return userRef.child('orders');
  }

  // ============================================================
  // USER PAYMENTS
  // ============================================================

  /// users/{mobileNumber}/payments
  DatabaseReference get paymentsRef {
    return userRef.child('payments');
  }

  // ============================================================
  // EXISTING FIRESTORE COLLECTION REFERENCES
  // ============================================================

  CollectionReference get customers =>
      firestore.collection('customers');

  CollectionReference get villages =>
      firestore.collection('villages');

  CollectionReference get plantCategories =>
      firestore.collection('plant_categories');

  CollectionReference get plantVarieties =>
      firestore.collection('plant_varieties');

  CollectionReference get plantVariants =>
      firestore.collection('plant_variants');

  CollectionReference get orders =>
      firestore.collection('orders');

  CollectionReference get orderItems =>
      firestore.collection('order_items');

  CollectionReference get purchaseOrders =>
      firestore.collection('purchase_orders');

  CollectionReference get deliveries =>
      firestore.collection('deliveries');

  CollectionReference get payments =>
      firestore.collection('payments');

  CollectionReference get inventory =>
      firestore.collection('inventory');

  CollectionReference get settings =>
      firestore.collection('settings');

  // ============================================================
  // LEGACY RTDB REFERENCES
  // ============================================================
  //
  // We are keeping these temporarily so that the existing code
  // does not break while we migrate repositories one by one.
  //
  // DO NOT use these for new code.
  //
  // ============================================================

  DatabaseReference get rtdbRoot =>
      database.ref();

  DatabaseReference get rtdbOrders =>
      database.ref('orders');

  DatabaseReference get rtdbInventory =>
      database.ref('inventory');

  DatabaseReference get rtdbDashboard =>
      database.ref('dashboard');

  // ============================================================
  // AUTH HELPERS
  // ============================================================

  User? get currentUser =>
      auth.currentUser;

  Stream<User?> get authStateChanges =>
      auth.authStateChanges();

  Future signInWithEmailAndPassword(
      String email,
      String password,
      ) =>
      auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

  Future signOut() =>
      auth.signOut();

  // ============================================================
  // FIRESTORE HELPERS
  // ============================================================

  String generateId() =>
      firestore.collection('_').doc().id;

  Timestamp get now =>
      Timestamp.now();

  Timestamp fromDateTime(
      DateTime dt,
      ) =>
      Timestamp.fromDate(dt);
}