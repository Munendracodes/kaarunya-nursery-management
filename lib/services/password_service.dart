import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class PasswordService {
  PasswordService._();

  static final PasswordService instance =
  PasswordService._();

  // ============================================================
  // PASSWORD HASH CONFIGURATION
  // ============================================================

  static const int iterations = 200000;
  static const int keyLength = 32;
  static const int saltLength = 16;

  // ============================================================
  // CREATE PASSWORD CREDENTIALS
  // ============================================================

  Map<String, String> createPasswordCredentials(
      String password,
      ) {
    if (password.isEmpty) {
      throw Exception(
        'Password cannot be empty.',
      );
    }

    final salt = _generateSalt();

    final hash = _pbkdf2(
      password: password,
      salt: salt,
      iterations: iterations,
      keyLength: keyLength,
    );

    return {
      'passwordHash': _bytesToHex(hash),
      'passwordSalt': _bytesToHex(salt),
    };
  }

  // ============================================================
  // VERIFY PASSWORD
  // ============================================================

  bool verifyPassword({
    required String password,
    required String storedHash,
    required String storedSalt,
  }) {
    if (password.isEmpty ||
        storedHash.isEmpty ||
        storedSalt.isEmpty) {
      return false;
    }

    try {
      final salt = _hexToBytes(storedSalt);

      final calculatedHash = _pbkdf2(
        password: password,
        salt: salt,
        iterations: iterations,
        keyLength: keyLength,
      );

      final calculatedHashHex =
      _bytesToHex(calculatedHash);

      return _constantTimeEquals(
        calculatedHashHex,
        storedHash,
      );
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // GENERATE RANDOM SALT
  // ============================================================

  Uint8List _generateSalt() {
    final random = Random.secure();

    final salt = Uint8List(saltLength);

    for (var i = 0; i < salt.length; i++) {
      salt[i] = random.nextInt(256);
    }

    return salt;
  }

  // ============================================================
  // PBKDF2-HMAC-SHA256
  // ============================================================

  Uint8List _pbkdf2({
    required String password,
    required Uint8List salt,
    required int iterations,
    required int keyLength,
  }) {
    final passwordBytes =
    Uint8List.fromList(
      password.codeUnits,
    );

    final hmac = Hmac(
      sha256,
      passwordBytes,
    );

    final blocks =
    (keyLength / sha256.convert([]).bytes.length)
        .ceil();

    final derivedKey = <int>[];

    for (var blockIndex = 1;
    blockIndex <= blocks;
    blockIndex++) {
      final blockNumber = Uint8List(4);

      blockNumber[0] =
      (blockIndex >> 24) & 0xff;
      blockNumber[1] =
      (blockIndex >> 16) & 0xff;
      blockNumber[2] =
      (blockIndex >> 8) & 0xff;
      blockNumber[3] =
      blockIndex & 0xff;

      final firstInput = Uint8List(
        salt.length + blockNumber.length,
      );

      firstInput.setRange(
        0,
        salt.length,
        salt,
      );

      firstInput.setRange(
        salt.length,
        firstInput.length,
        blockNumber,
      );

      var u =
          hmac.convert(firstInput).bytes;

      final t = List<int>.from(u);

      for (var iteration = 1;
      iteration < iterations;
      iteration++) {
        u = hmac.convert(u).bytes;

        for (var i = 0; i < t.length; i++) {
          t[i] ^= u[i];
        }
      }

      derivedKey.addAll(t);
    }

    return Uint8List.fromList(
      derivedKey.take(keyLength).toList(),
    );
  }

  // ============================================================
  // HEX HELPERS
  // ============================================================

  String _bytesToHex(List<int> bytes) {
    final buffer = StringBuffer();

    for (final byte in bytes) {
      buffer.write(
        byte.toRadixString(16).padLeft(2, '0'),
      );
    }

    return buffer.toString();
  }

  Uint8List _hexToBytes(String hex) {
    if (hex.length % 2 != 0) {
      throw FormatException(
        'Invalid hexadecimal string.',
      );
    }

    final result = Uint8List(
      hex.length ~/ 2,
    );

    for (var i = 0;
    i < hex.length;
    i += 2) {
      result[i ~/ 2] =
          int.parse(
            hex.substring(i, i + 2),
            radix: 16,
          );
    }

    return result;
  }

  // ============================================================
  // CONSTANT-TIME STRING COMPARISON
  // ============================================================

  bool _constantTimeEquals(
      String a,
      String b,
      ) {
    if (a.length != b.length) {
      return false;
    }

    var result = 0;

    for (var i = 0; i < a.length; i++) {
      result |=
      a.codeUnitAt(i) ^
      b.codeUnitAt(i);
    }

    return result == 0;
  }
}