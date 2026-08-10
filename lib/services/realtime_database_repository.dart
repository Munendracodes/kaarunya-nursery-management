import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_service.dart';

class RealtimeDatabaseRepository {
  RealtimeDatabaseRepository._();

  static final RealtimeDatabaseRepository instance =
  RealtimeDatabaseRepository._();

  final FirebaseService _firebase =
      FirebaseService.instance;

  final ImagePicker _imagePicker =
  ImagePicker();

  // ============================================================
  // PLANT REFERENCES
  // ============================================================

  /// users/{mobileNumber}/plants
  DatabaseReference get _plantsRef {
    return _firebase.plantsRef;
  }

  /// users/{mobileNumber}/plants/{plantId}
  DatabaseReference _plantRef(
      String plantId,
      ) {
    return _plantsRef.child(plantId);
  }

  /// users/{mobileNumber}/plants/{plantId}/varieties
  DatabaseReference _varietiesRef(
      String plantId,
      ) {
    return _plantRef(plantId)
        .child('varieties');
  }

  /// users/{mobileNumber}/plants/{plantId}/varieties/{varietyId}
  DatabaseReference _varietyRef(
      String plantId,
      String varietyId,
      ) {
    return _varietiesRef(plantId)
        .child(varietyId);
  }

  /// users/{mobileNumber}/plants/{plantId}/varieties/{varietyId}/variants
  DatabaseReference _variantsRef(
      String plantId,
      String varietyId,
      ) {
    return _varietyRef(
      plantId,
      varietyId,
    ).child('variants');
  }

  /// Make sure the mobile number has been initialized.
  void _validateCurrentUser() {
    // Accessing _firebase.mobileNumber will throw
    // a meaningful exception if it has not been set.
    final mobileNumber = _firebase.mobileNumber;

    if (mobileNumber.trim().isEmpty) {
      throw Exception(
        'Current user mobile number is empty.',
      );
    }
  }

  // ============================================================
  // ADD PLANT
  // ============================================================

  /// Add a new plant.
  ///
  /// Database:
  ///
  /// users/{mobileNumber}/plants/{plantId}
  ///
  /// Storage:
  ///
  /// users/{mobileNumber}/plants/{plantId}/plant_image.jpg
  Future<String> addPlant({
    required String name,
    XFile? image,
  }) async {
    _validateCurrentUser();

    try {
      // ==========================================================
      // 1. VALIDATE
      // ==========================================================

      final plantName = name.trim();

      if (plantName.isEmpty) {
        throw Exception(
          'Plant name cannot be empty',
        );
      }

      debugPrint(
        '========================================',
      );
      debugPrint(
        'ADD PLANT STARTED',
      );
      debugPrint(
        'User: ${_firebase.mobileNumber}',
      );
      debugPrint(
        'Plant name: $plantName',
      );
      debugPrint(
        'Image selected: ${image != null}',
      );
      debugPrint(
        '========================================',
      );

      // ==========================================================
      // 2. GENERATE PLANT ID
      // ==========================================================

      final plantRef =
      _plantsRef.push();

      final plantId =
          plantRef.key;

      if (plantId == null) {
        throw Exception(
          'Unable to generate plant ID',
        );
      }

      debugPrint(
        'Plant ID generated: $plantId',
      );

      debugPrint(
        'Plant database path: ${plantRef.path}',
      );

      String? imageUrl;

      // ==========================================================
      // 3. UPLOAD PLANT IMAGE
      // ==========================================================

      if (image != null) {
        debugPrint(
          'Starting Firebase Storage upload...',
        );

        debugPrint(
          'Local image path: ${image.path}',
        );

        final storageRef =
        _firebase.storage
            .ref()
            .child('users')
            .child(
          _firebase.mobileNumber,
        )
            .child('plants')
            .child(plantId)
            .child('plant_image.jpg');

        debugPrint(
          'Storage path: ${storageRef.fullPath}',
        );

        final file =
        File(image.path);

        if (!await file.exists()) {
          throw Exception(
            'Selected image file does not exist: ${image.path}',
          );
        }

        final fileSize =
        await file.length();

        debugPrint(
          'Image size: $fileSize bytes',
        );

        if (fileSize == 0) {
          throw Exception(
            'Selected image file is empty',
          );
        }

        final metadata =
        SettableMetadata(
          contentType: 'image/jpeg',
        );

        final uploadTask =
        storageRef.putFile(
          file,
          metadata,
        );

        uploadTask.snapshotEvents
            .listen((snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress =
                (snapshot.bytesTransferred /
                    snapshot.totalBytes) *
                    100;

            debugPrint(
              'Storage upload progress: '
                  '${progress.toStringAsFixed(1)}%',
            );
          }
        });

        await uploadTask;

        debugPrint(
          'Firebase Storage upload completed',
        );

        imageUrl =
        await storageRef
            .getDownloadURL();

        debugPrint(
          'Firebase Storage URL obtained',
        );

        debugPrint(
          'Image URL: $imageUrl',
        );
      } else {
        debugPrint(
          'No image selected. '
              'Skipping Storage upload.',
        );
      }

      // ==========================================================
      // 4. CREATE PLANT DATA
      // ==========================================================

      final plantData =
      <String, dynamic>{
        'name': plantName,
        'active': true,
        'createdAt':
        ServerValue.timestamp,
      };

      if (imageUrl != null &&
          imageUrl.isNotEmpty) {
        plantData['imageUrl'] =
            imageUrl;
      }

      debugPrint(
        'Plant data: $plantData',
      );

      // ==========================================================
      // 5. SAVE TO REALTIME DATABASE
      // ==========================================================

      debugPrint(
        'Writing plant to Realtime Database...',
      );

      await plantRef.set(
        plantData,
      );

      debugPrint(
        'Realtime Database write completed',
      );

      debugPrint(
        'Plant successfully created: $plantId',
      );

      debugPrint(
        '========================================',
      );

      return plantId;
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        '========================================',
      );
    debugPrint(
    'FIREBASE ERROR WHILE ADDING PLANT',
    );
    debugPrint(
    'Code: ${e.code}',
    );
    debugPrint(
    'Message: ${e.message}',
    );
    debugPrint(
    'Plugin: ${e.plugin}',
    );
    debugPrint(
    '========================================',
    );

    debugPrintStack(
    stackTrace: stackTrace,
    );

    throw Exception(
    'Firebase error [${e.code}]: '
    '${e.message ?? 'Unknown Firebase error'}',
    );
    } catch (e, stackTrace) {
    debugPrint(
    '========================================',
    );
    debugPrint(
    'ERROR WHILE ADDING PLANT',
    );
    debugPrint(
    'Error: $e',
    );
    debugPrint(
    '========================================',
    );

    debugPrintStack(
    stackTrace: stackTrace,
    );

    throw Exception(
    'Unable to add plant: $e',
    );
    }
  }

  // ============================================================
  // GET PLANTS
  // ============================================================

  /// Get all plants for the current user.
  ///
  /// Reads:
  ///
  /// users/{mobileNumber}/plants
  Future<List<Map<String, dynamic>>>
  getPlants() async {
    _validateCurrentUser();

    final snapshot =
    await _plantsRef.get();

    if (!snapshot.exists ||
        snapshot.value == null) {
      return [];
    }

    final rawData =
    Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );

    return rawData.entries
        .map((entry) {
      final plantId =
      entry.key.toString();

      final data =
      Map<String, dynamic>.from(
        Map<dynamic, dynamic>.from(
          entry.value as Map,
        ),
      );

      return {
        'id': plantId,
        ...data,
      };
    }).toList();
  }

  // ============================================================
  // TOGGLE PLANT ACTIVE
  // ============================================================

  /// Enable/disable a plant.
  ///
  /// Kept for backward compatibility.
  Future<void> togglePlantActive(
      String plantId,
      bool active,
      ) async {
    _validateCurrentUser();

    await _plantRef(
      plantId,
    ).update({
      'active': active,
    });
  }

  // ============================================================
  // ADD VARIETY
  // ============================================================

  /// Add a new variety under a plant.
  ///
  /// Database:
  ///
  /// users/{mobileNumber}/plants/{plantId}/varieties/{varietyId}
  ///
  /// Storage:
  ///
  /// users/{mobileNumber}/plants/{plantId}/varieties/{varietyId}/variety_image.jpg
  Future<String> addVariety({
    required String plantId,
    required String name,
    XFile? image,
  }) async {
    _validateCurrentUser();

    if (plantId.trim().isEmpty) {
      throw Exception(
        'Plant ID is required',
      );
    }

    final varietyRef =
    _varietiesRef(
      plantId,
    ).push();

    final varietyId =
        varietyRef.key;

    if (varietyId == null) {
      throw Exception(
        'Unable to generate variety ID',
      );
    }

    debugPrint(
      '========================================',
    );
    debugPrint(
      'ADD VARIETY',
    );
    debugPrint(
      'User: ${_firebase.mobileNumber}',
    );
    debugPrint(
      'Plant ID: $plantId',
    );
    debugPrint(
      'Variety ID: $varietyId',
    );
    debugPrint(
      'Database path: ${varietyRef.path}',
    );
    debugPrint(
      '========================================',
    );

    String? imageUrl;

    // ==========================================================
    // UPLOAD VARIETY IMAGE
    // ==========================================================

    if (image != null) {
      final storageRef =
      _firebase.storage
          .ref()
          .child('users')
          .child(
        _firebase.mobileNumber,
      )
          .child('plants')
          .child(plantId)
          .child('varieties')
          .child(varietyId)
          .child('variety_image.jpg');

      debugPrint(
        'Variety storage path: '
            '${storageRef.fullPath}',
      );

      final file =
      File(image.path);

      if (!await file.exists()) {
        throw Exception(
          'Selected image file does not exist',
        );
      }

      final fileSize =
      await file.length();

      if (fileSize == 0) {
        throw Exception(
          'Selected image file is empty',
        );
      }

      final metadata =
      SettableMetadata(
        contentType: 'image/jpeg',
      );

      await storageRef.putFile(
        file,
        metadata,
      );

      imageUrl =
      await storageRef
          .getDownloadURL();

      debugPrint(
        'Variety image uploaded successfully',
      );

      debugPrint(
        'Variety image URL: $imageUrl',
      );
    }

    // ==========================================================
    // SAVE VARIETY
    // ==========================================================

    final varietyData =
    <String, dynamic>{
      'name': name.trim(),
      'createdAt':
      ServerValue.timestamp,
    };

    if (imageUrl != null &&
        imageUrl.isNotEmpty) {
      varietyData['imageUrl'] =
          imageUrl;
    }

    await varietyRef.set(
      varietyData,
    );

    debugPrint(
      'Variety saved successfully: '
          '$varietyId',
    );

    return varietyId;
  }

  // ============================================================
  // GET VARIETIES
  // ============================================================

  /// Get varieties for a specific plant.
  Future<List<Map<String, dynamic>>>
  getVarieties(
      String plantId,
      ) async {
    _validateCurrentUser();

    if (plantId.trim().isEmpty) {
      throw Exception(
        'Plant ID is required',
      );
    }

    final snapshot =
    await _varietiesRef(
      plantId,
    ).get();

    if (!snapshot.exists ||
        snapshot.value == null) {
      return [];
    }

    final rawData =
    Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );

    return rawData.entries
        .map((entry) {
      final varietyId =
      entry.key.toString();

      final data =
      Map<String, dynamic>.from(
        Map<dynamic, dynamic>.from(
          entry.value as Map,
        ),
      );

      return {
        'id': varietyId,
        ...data,
      };
    }).toList();
  }

  // ============================================================
  // ADD VARIANT
  // ============================================================

  /// Add a new variant under a variety.
  ///
  /// Database:
  ///
  /// users/{mobileNumber}/plants/{plantId}/varieties/{varietyId}/variants/{variantId}
  ///
  /// Storage:
  ///
  /// users/{mobileNumber}/plants/{plantId}/varieties/{varietyId}/variants/{variantId}.jpg
  Future<String> addVariant({
    required String plantId,
    required String varietyId,
    required String name,
    required double weight,
    required int years,
    required double price,
    XFile? image,
  }) async {
    _validateCurrentUser();

    if (plantId.trim().isEmpty) {
      throw Exception(
        'Plant ID is required',
      );
    }

    if (varietyId.trim().isEmpty) {
      throw Exception(
        'Variety ID is required',
      );
    }

    // ==========================================================
    // VARIANTS DATABASE REFERENCE
    // ==========================================================

    final variantsRef =
    _variantsRef(
      plantId,
      varietyId,
    );

    final variantRef =
    variantsRef.push();

    final variantId =
        variantRef.key;

    if (variantId == null) {
      throw Exception(
        'Unable to generate variant ID',
      );
    }

    debugPrint(
      '========================================',
    );
    debugPrint(
      'ADD VARIANT',
    );
    debugPrint(
      'User: ${_firebase.mobileNumber}',
    );
    debugPrint(
      'Plant ID: $plantId',
    );
    debugPrint(
      'Variety ID: $varietyId',
    );
    debugPrint(
      'Variant ID: $variantId',
    );
    debugPrint(
      'Database path: ${variantRef.path}',
    );
    debugPrint(
      '========================================',
    );

    // ==========================================================
    // UPLOAD IMAGE
    // ==========================================================

    String? imageUrl;

    if (image != null) {
      try {
        debugPrint(
          'Uploading variant image: '
              '${image.path}',
        );

        final storageRef =
        _firebase.storage
            .ref()
            .child('users')
            .child(
          _firebase.mobileNumber,
        )
            .child('plants')
            .child(plantId)
            .child('varieties')
            .child(varietyId)
            .child('variants')
            .child(
          '$variantId.jpg',
        );

        debugPrint(
          'Variant storage path: '
              '${storageRef.fullPath}',
        );

        final file =
        File(image.path);

        if (!await file.exists()) {
          throw Exception(
            'Selected variant image file does not exist',
          );
        }

        final fileSize =
        await file.length();

        if (fileSize == 0) {
          throw Exception(
            'Selected variant image file is empty',
          );
        }

        final metadata =
        SettableMetadata(
          contentType: 'image/jpeg',
        );

        await storageRef.putFile(
          file,
          metadata,
        );

        imageUrl =
        await storageRef
            .getDownloadURL();

        debugPrint(
          'Variant image uploaded successfully',
        );

        debugPrint(
          'Variant image URL: $imageUrl',
        );
      } catch (e, stackTrace) {
    debugPrint(
    'Variant image upload failed: $e',
    );

    debugPrintStack(
    stackTrace: stackTrace,
    );

    throw Exception(
    'Failed to upload variant image: $e',
    );
    }
    }

    // ==========================================================
    // VARIANT DATA
    // ==========================================================

    final variantData =
    <String, dynamic>{
    'name': name.trim(),
    'weight': weight,
    'weightUnit': 'kg',
    'years': years,
    'price': price,
    'createdAt':
    ServerValue.timestamp,
    };

    if (imageUrl != null &&
    imageUrl.isNotEmpty) {
    variantData['imageUrl'] =
    imageUrl;
    }

    // ==========================================================
    // SAVE TO REALTIME DATABASE
    // ==========================================================

    await variantRef.set(
    variantData,
    );

    debugPrint(
    'Variant saved successfully: '
    '$variantId',
    );

    debugPrint(
    'Variant data: $variantData',
    );

    return variantId;
  }

  // ============================================================
  // UPDATE VARIANT
  // ============================================================

  /// Update an existing variant.
  ///
  /// If a new image is supplied, it replaces the existing image
  /// at the same Storage location.
  Future<void> updateVariant({
    required String plantId,
    required String varietyId,
    required String variantId,
    required String name,
    required double weight,
    required int years,
    required double price,
    XFile? image,
  }) async {
    _validateCurrentUser();

    if (plantId.trim().isEmpty) {
      throw Exception(
        'Plant ID is required',
      );
    }

    if (varietyId.trim().isEmpty) {
      throw Exception(
        'Variety ID is required',
      );
    }

    if (variantId.trim().isEmpty) {
      throw Exception(
        'Variant ID is required',
      );
    }

    final variantRef =
    _variantsRef(
      plantId,
      varietyId,
    ).child(variantId);

    String? imageUrl;

    // ==========================================================
    // UPLOAD NEW IMAGE
    // ==========================================================

    if (image != null) {
      final storageRef =
      _firebase.storage
          .ref()
          .child('users')
          .child(
        _firebase.mobileNumber,
      )
          .child('plants')
          .child(plantId)
          .child('varieties')
          .child(varietyId)
          .child('variants')
          .child(
        '$variantId.jpg',
      );

      debugPrint(
        'Updating variant image: '
            '${storageRef.fullPath}',
      );

      final file =
      File(image.path);

      if (!await file.exists()) {
        throw Exception(
          'Selected variant image file does not exist',
        );
      }

      final fileSize =
      await file.length();

      if (fileSize == 0) {
        throw Exception(
          'Selected variant image file is empty',
        );
      }

      final metadata =
      SettableMetadata(
        contentType: 'image/jpeg',
      );

      await storageRef.putFile(
        file,
        metadata,
      );

      imageUrl =
      await storageRef
          .getDownloadURL();

      debugPrint(
        'Updated variant image URL: '
            '$imageUrl',
      );
    }

    // ==========================================================
    // UPDATE DATA
    // ==========================================================

    final updateData =
    <String, dynamic>{
      'name': name.trim(),
      'weight': weight,
      'weightUnit': 'kg',
      'years': years,
      'price': price,
    };

    if (imageUrl != null &&
        imageUrl.isNotEmpty) {
      updateData['imageUrl'] =
          imageUrl;
    }

    await variantRef.update(
      updateData,
    );

    debugPrint(
      'Variant updated successfully: '
          '$variantId',
    );
  }

  // ============================================================
  // GET VARIANTS
  // ============================================================

  /// Get variants for a specific plant + variety.
  Future<List<Map<String, dynamic>>>
  getVariants(
      String plantId,
      String varietyId,
      ) async {
    _validateCurrentUser();

    if (plantId.trim().isEmpty) {
      throw Exception(
        'Plant ID is required',
      );
    }

    if (varietyId.trim().isEmpty) {
      throw Exception(
        'Variety ID is required',
      );
    }

    final snapshot =
    await _variantsRef(
      plantId,
      varietyId,
    ).get();

    if (!snapshot.exists ||
        snapshot.value == null) {
      return [];
    }

    final rawData =
    Map<dynamic, dynamic>.from(
      snapshot.value as Map,
    );

    return rawData.entries
        .map((entry) {
      final variantId =
      entry.key.toString();

      final data =
      Map<String, dynamic>.from(
        Map<dynamic, dynamic>.from(
          entry.value as Map,
        ),
      );

      return {
        'id': variantId,
        ...data,
      };
    }).toList();
  }
}