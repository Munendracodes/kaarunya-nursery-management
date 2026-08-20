import 'package:firebase_database/firebase_database.dart';

import 'firebase_service.dart';
import 'password_service.dart';

class UserAuthService {
  UserAuthService._();

  static final UserAuthService instance =
  UserAuthService._();

  final FirebaseService _firebase =
      FirebaseService.instance;

  final PasswordService _passwordService =
      PasswordService.instance;

  // ============================================================
  // CREATE USER
  // ============================================================

  Future<void> createUser({
    required String mobileNumber,
    required String name,
    required String email,
    required String nurseryName,
    required String address,
    required String password,
  }) async {
    final mobile = mobileNumber.trim();

    if (mobile.isEmpty) {
      throw Exception(
        'Mobile number is required.',
      );
    }

    if (name.trim().isEmpty) {
      throw Exception(
        'Name is required.',
      );
    }

    if (email.trim().isEmpty) {
      throw Exception(
        'Email is required.',
      );
    }

    if (nurseryName.trim().isEmpty) {
      throw Exception(
        'Nursery name is required.',
      );
    }

    if (address.trim().isEmpty) {
      throw Exception(
        'Address is required.',
      );
    }

    if (password.length < 6) {
      throw Exception(
        'Password must contain at least 6 characters.',
      );
    }

    // ==========================================================
    // CHECK WHETHER USER ALREADY EXISTS
    // ==========================================================

    final userRef =
    _firebase.database.ref(
      'users/$mobile',
    );

    final existingUser =
    await userRef.get();

    if (existingUser.exists) {
      throw Exception(
        'A user already exists with this mobile number.',
      );
    }

    // ==========================================================
    // GENERATE PASSWORD HASH + SALT
    // ==========================================================

    final credentials =
    _passwordService
        .createPasswordCredentials(
      password,
    );

    // ==========================================================
    // CREATE PROFILE
    // ==========================================================

    final profileData =
    <String, dynamic>{
      'mobileNumber': mobile,
      'name': name.trim(),
      'email': email.trim(),
      'nurseryName':
      nurseryName.trim(),
      'address': address.trim(),

      'passwordHash':
      credentials['passwordHash'],

      'passwordSalt':
      credentials['passwordSalt'],

      'active': true,

      'createdAt':
      ServerValue.timestamp,
    };

    // ==========================================================
    // SAVE USER
    // ==========================================================

    await userRef.child('profile').set(
      profileData,
    );
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<Map<String, dynamic>>
  login({
    required String mobileNumber,
    required String password,
  }) async {
    final mobile =
    mobileNumber.trim();

    if (mobile.isEmpty) {
      throw Exception(
        'Mobile number is required.',
      );
    }

    if (password.isEmpty) {
      throw Exception(
        'Password is required.',
      );
    }

    // ==========================================================
    // FETCH PROFILE
    // ==========================================================

    final snapshot =
    await _firebase.database
        .ref(
      'users/$mobile/profile',
    )
        .get();

    if (!snapshot.exists ||
        snapshot.value == null) {
      throw Exception(
        'Invalid mobile number or password.',
      );
    }

    final profile =
    Map<String, dynamic>.from(
      snapshot.value as Map,
    );

    // ==========================================================
    // CHECK ACTIVE
    // ==========================================================

    final active =
        profile['active'] == true;

    if (!active) {
      throw Exception(
        'This account is inactive.',
      );
    }

    final storedHash =
        profile['passwordHash']
            ?.toString() ??
            '';

    final storedSalt =
        profile['passwordSalt']
            ?.toString() ??
            '';

    if (storedHash.isEmpty ||
        storedSalt.isEmpty) {
      throw Exception(
        'User account credentials are not configured.',
      );
    }

    // ==========================================================
    // VERIFY PASSWORD
    // ==========================================================

    final passwordValid =
    _passwordService
        .verifyPassword(
      password: password,
      storedHash: storedHash,
      storedSalt: storedSalt,
    );

    if (!passwordValid) {
      throw Exception(
        'Invalid mobile number or password.',
      );
    }

    // ==========================================================
    // SET CURRENT USER
    // ==========================================================

    _firebase.setCurrentUser(
      mobile,
    );

    return profile;
  }
}