import 'package:cloud_firestore/cloud_firestore.dart';

import './firebase_service.dart';

/// Seeds all Firestore collections and Realtime Database with nursery data.
/// Call once on first launch or from settings.
class SeedDataService {
  SeedDataService._();
  static final SeedDataService instance = SeedDataService._();

  final _fs = FirebaseService.instance;

  Future<void> seedAll() async {
    await Future.wait([
      _seedSettings(),
      _seedVillages(),
      _seedCustomers(),
      _seedPlantCategories(),
      _seedPlantVarieties(),
      _seedPlantVariants(),
    ]);
    await Future.wait([_seedOrders(), _seedInventory()]);
    await Future.wait([
      _seedOrderItems(),
      _seedPurchaseOrders(),
      _seedDeliveries(),
      _seedPayments(),
    ]);
    await _seedRealtimeDatabase();
  }

  // ─── Settings ──────────────────────────────────────────────────────────────
  Future<void> _seedSettings() async {
    final batch = _fs.firestore.batch();
    final ref = _fs.settings.doc('app_settings');
    batch.set(ref, {
      'nurseryName': 'Kaarunya Nursery',
      'ownerName': 'Kaarunya',
      'phone': '9876543210',
      'address': 'Vijayawada, Andhra Pradesh',
      'gstNumber': '',
      'defaultLanguage': 'EN',
      'currency': 'INR',
      'currencySymbol': '₹',
      'taxRate': 0.0,
      'advancePercentage': 50,
      'createdAt': _fs.now,
      'updatedAt': _fs.now,
    });
    final pinRef = _fs.settings.doc('auth_settings');
    batch.set(pinRef, {
      'managerMobile': '9876543210',
      'managerPin': '123456',
      'updatedAt': _fs.now,
    });
    await batch.commit();
  }

  // ─── Villages ──────────────────────────────────────────────────────────────
  Future<void> _seedVillages() async {
    final villages = [
      {
        'id': 'V001',
        'name': 'Kondapalli',
        'district': 'Krishna',
        'active': true,
        'customerCount': 18,
      },
      {
        'id': 'V002',
        'name': 'Nuzvid',
        'district': 'Krishna',
        'active': true,
        'customerCount': 12,
      },
      {
        'id': 'V003',
        'name': 'Eluru',
        'district': 'West Godavari',
        'active': true,
        'customerCount': 22,
      },
      {
        'id': 'V004',
        'name': 'Vijayawada',
        'district': 'Krishna',
        'active': true,
        'customerCount': 35,
      },
      {
        'id': 'V005',
        'name': 'Gudivada',
        'district': 'Krishna',
        'active': true,
        'customerCount': 9,
      },
      {
        'id': 'V006',
        'name': 'Tenali',
        'district': 'Guntur',
        'active': true,
        'customerCount': 14,
      },
      {
        'id': 'V007',
        'name': 'Guntur',
        'district': 'Guntur',
        'active': true,
        'customerCount': 28,
      },
      {
        'id': 'V008',
        'name': 'Machilipatnam',
        'district': 'Krishna',
        'active': true,
        'customerCount': 7,
      },
      {
        'id': 'V009',
        'name': 'Bhimavaram',
        'district': 'West Godavari',
        'active': true,
        'customerCount': 11,
      },
      {
        'id': 'V010',
        'name': 'Narsapur',
        'district': 'West Godavari',
        'active': true,
        'customerCount': 6,
      },
      {
        'id': 'V011',
        'name': 'Palakol',
        'district': 'West Godavari',
        'active': false,
        'customerCount': 3,
      },
      {
        'id': 'V012',
        'name': 'Tadepalligudem',
        'district': 'West Godavari',
        'active': true,
        'customerCount': 8,
      },
    ];
    final batch = _fs.firestore.batch();
    for (final v in villages) {
      batch.set(_fs.villages.doc(v['id'] as String), {
        ...v,
        'createdAt': _fs.now,
        'updatedAt': _fs.now,
      });
    }
    await batch.commit();
  }

  // ─── Customers ─────────────────────────────────────────────────────────────
  Future<void> _seedCustomers() async {
    final customers = [
      {
        'id': 'C001',
        'name': 'Venkata Rao',
        'mobile': '9441234567',
        'villageId': 'V001',
        'villageName': 'Kondapalli',
        'totalOrders': 14,
        'totalAmount': 42000.0,
        'pendingAmount': 8500.0,
        'active': true,
      },
      {
        'id': 'C002',
        'name': 'Lakshmi Devi',
        'mobile': '9849876543',
        'villageId': 'V002',
        'villageName': 'Nuzvid',
        'totalOrders': 8,
        'totalAmount': 28000.0,
        'pendingAmount': 0.0,
        'active': true,
      },
      {
        'id': 'C003',
        'name': 'Srinivasa Reddy',
        'mobile': '9966554433',
        'villageId': 'V003',
        'villageName': 'Eluru',
        'totalOrders': 22,
        'totalAmount': 87500.0,
        'pendingAmount': 15000.0,
        'active': true,
      },
      {
        'id': 'C004',
        'name': 'Padma Kumari',
        'mobile': '9876012345',
        'villageId': 'V004',
        'villageName': 'Vijayawada',
        'totalOrders': 6,
        'totalAmount': 18000.0,
        'pendingAmount': 3200.0,
        'active': true,
      },
      {
        'id': 'C005',
        'name': 'Raju Naidu',
        'mobile': '9701234567',
        'villageId': 'V005',
        'villageName': 'Gudivada',
        'totalOrders': 11,
        'totalAmount': 35000.0,
        'pendingAmount': 5250.0,
        'active': true,
      },
      {
        'id': 'C006',
        'name': 'Govinda Rao',
        'mobile': '9550123456',
        'villageId': 'V006',
        'villageName': 'Tenali',
        'totalOrders': 9,
        'totalAmount': 27000.0,
        'pendingAmount': 2500.0,
        'active': true,
      },
      {
        'id': 'C007',
        'name': 'Sarada Devi',
        'mobile': '9440987654',
        'villageId': 'V007',
        'villageName': 'Guntur',
        'totalOrders': 17,
        'totalAmount': 54000.0,
        'pendingAmount': 0.0,
        'active': true,
      },
      {
        'id': 'C008',
        'name': 'Krishnamurthy',
        'mobile': '9848765432',
        'villageId': 'V008',
        'villageName': 'Machilipatnam',
        'totalOrders': 4,
        'totalAmount': 12000.0,
        'pendingAmount': 4000.0,
        'active': true,
      },
      {
        'id': 'C009',
        'name': 'Annapurna',
        'mobile': '9963210987',
        'villageId': 'V009',
        'villageName': 'Bhimavaram',
        'totalOrders': 7,
        'totalAmount': 21500.0,
        'pendingAmount': 1500.0,
        'active': true,
      },
      {
        'id': 'C010',
        'name': 'Suresh Babu',
        'mobile': '9700543210',
        'villageId': 'V001',
        'villageName': 'Kondapalli',
        'totalOrders': 19,
        'totalAmount': 68000.0,
        'pendingAmount': 12000.0,
        'active': true,
      },
      {
        'id': 'C011',
        'name': 'Kamala Devi',
        'mobile': '9551234567',
        'villageId': 'V004',
        'villageName': 'Vijayawada',
        'totalOrders': 5,
        'totalAmount': 15000.0,
        'pendingAmount': 0.0,
        'active': true,
      },
      {
        'id': 'C012',
        'name': 'Narasimha Rao',
        'mobile': '9441098765',
        'villageId': 'V010',
        'villageName': 'Narsapur',
        'totalOrders': 3,
        'totalAmount': 9000.0,
        'pendingAmount': 3000.0,
        'active': true,
      },
      {
        'id': 'C013',
        'name': 'Vijaya Lakshmi',
        'mobile': '9849012345',
        'villageId': 'V012',
        'villageName': 'Tadepalligudem',
        'totalOrders': 8,
        'totalAmount': 24000.0,
        'pendingAmount': 0.0,
        'active': true,
      },
      {
        'id': 'C014',
        'name': 'Ramesh Chandra',
        'mobile': '9966123456',
        'villageId': 'V003',
        'villageName': 'Eluru',
        'totalOrders': 12,
        'totalAmount': 38000.0,
        'pendingAmount': 7500.0,
        'active': true,
      },
      {
        'id': 'C015',
        'name': 'Bhavani Devi',
        'mobile': '9876543211',
        'villageId': 'V007',
        'villageName': 'Guntur',
        'totalOrders': 6,
        'totalAmount': 19500.0,
        'pendingAmount': 2000.0,
        'active': false,
      },
    ];
    final batch = _fs.firestore.batch();
    for (final c in customers) {
      batch.set(_fs.customers.doc(c['id'] as String), {
        ...c,
        'createdAt': _fs.now,
        'updatedAt': _fs.now,
      });
    }
    await batch.commit();
  }

  // ─── Plant Categories ──────────────────────────────────────────────────────
  Future<void> _seedPlantCategories() async {
    final categories = [
      {
        'id': 'CAT001',
        'name': 'Fruit Trees',
        'nameTe': 'పండ్ల చెట్లు',
        'icon': 'local_florist',
        'active': true,
        'sortOrder': 1,
      },
      {
        'id': 'CAT002',
        'name': 'Coconut',
        'nameTe': 'కొబ్బరి',
        'icon': 'park',
        'active': true,
        'sortOrder': 2,
      },
      {
        'id': 'CAT003',
        'name': 'Timber',
        'nameTe': 'కలప చెట్లు',
        'icon': 'forest',
        'active': true,
        'sortOrder': 3,
      },
      {
        'id': 'CAT004',
        'name': 'Flowers',
        'nameTe': 'పూల మొక్కలు',
        'icon': 'spa',
        'active': true,
        'sortOrder': 4,
      },
      {
        'id': 'CAT005',
        'name': 'Banana',
        'nameTe': 'అరటి',
        'icon': 'eco',
        'active': true,
        'sortOrder': 5,
      },
      {
        'id': 'CAT006',
        'name': 'Medicinal',
        'nameTe': 'ఔషధ మొక్కలు',
        'icon': 'healing',
        'active': true,
        'sortOrder': 6,
      },
      {
        'id': 'CAT007',
        'name': 'Vegetables',
        'nameTe': 'కూరగాయలు',
        'icon': 'grass',
        'active': true,
        'sortOrder': 7,
      },
    ];
    final batch = _fs.firestore.batch();
    for (final c in categories) {
      batch.set(_fs.plantCategories.doc(c['id'] as String), {
        ...c,
        'createdAt': _fs.now,
        'updatedAt': _fs.now,
      });
    }
    await batch.commit();
  }

  // ─── Plant Varieties ───────────────────────────────────────────────────────
  Future<void> _seedPlantVarieties() async {
    final varieties = [
      {
        'id': 'VAR001',
        'categoryId': 'CAT001',
        'name': 'Mango',
        'nameTe': 'మామిడి',
        'active': true,
      },
      {
        'id': 'VAR002',
        'categoryId': 'CAT001',
        'name': 'Guava',
        'nameTe': 'జామ',
        'active': true,
      },
      {
        'id': 'VAR003',
        'categoryId': 'CAT001',
        'name': 'Sapota',
        'nameTe': 'సపోట',
        'active': true,
      },
      {
        'id': 'VAR004',
        'categoryId': 'CAT001',
        'name': 'Pomegranate',
        'nameTe': 'దానిమ్మ',
        'active': true,
      },
      {
        'id': 'VAR005',
        'categoryId': 'CAT001',
        'name': 'Lemon',
        'nameTe': 'నిమ్మ',
        'active': true,
      },
      {
        'id': 'VAR006',
        'categoryId': 'CAT002',
        'name': 'Coconut',
        'nameTe': 'కొబ్బరి',
        'active': true,
      },
      {
        'id': 'VAR007',
        'categoryId': 'CAT003',
        'name': 'Teak',
        'nameTe': 'టేకు',
        'active': true,
      },
      {
        'id': 'VAR008',
        'categoryId': 'CAT003',
        'name': 'Neem',
        'nameTe': 'వేప',
        'active': true,
      },
      {
        'id': 'VAR009',
        'categoryId': 'CAT003',
        'name': 'Eucalyptus',
        'nameTe': 'యూకలిప్టస్',
        'active': true,
      },
      {
        'id': 'VAR010',
        'categoryId': 'CAT004',
        'name': 'Rose',
        'nameTe': 'గులాబి',
        'active': true,
      },
      {
        'id': 'VAR011',
        'categoryId': 'CAT004',
        'name': 'Jasmine',
        'nameTe': 'మల్లె',
        'active': true,
      },
      {
        'id': 'VAR012',
        'categoryId': 'CAT004',
        'name': 'Marigold',
        'nameTe': 'చేమంతి',
        'active': true,
      },
      {
        'id': 'VAR013',
        'categoryId': 'CAT005',
        'name': 'Banana',
        'nameTe': 'అరటి',
        'active': true,
      },
      {
        'id': 'VAR014',
        'categoryId': 'CAT006',
        'name': 'Tulsi',
        'nameTe': 'తులసి',
        'active': true,
      },
      {
        'id': 'VAR015',
        'categoryId': 'CAT006',
        'name': 'Aloe Vera',
        'nameTe': 'కలబంద',
        'active': true,
      },
    ];
    final batch = _fs.firestore.batch();
    for (final v in varieties) {
      batch.set(_fs.plantVarieties.doc(v['id'] as String), {
        ...v,
        'createdAt': _fs.now,
        'updatedAt': _fs.now,
      });
    }
    await batch.commit();
  }

  // ─── Plant Variants (SKUs) ─────────────────────────────────────────────────
  Future<void> _seedPlantVariants() async {
    final variants = [
      {
        'id': 'P001',
        'varietyId': 'VAR001',
        'categoryId': 'CAT001',
        'name': 'Mango (Banganapalli)',
        'nameTe': 'మామిడి (బంగినపల్లి)',
        'variant': '2yr Grafted',
        'price': 180.0,
        'stock': 200,
        'minStock': 50,
        'active': true,
        'imageUrl':
            'https://images.pixabay.com/photo/2016/03/05/19/02/mango-1238331_960_720.jpg',
      },
      {
        'id': 'P002',
        'varietyId': 'VAR001',
        'categoryId': 'CAT001',
        'name': 'Mango (Alphonso)',
        'nameTe': 'మామిడి (అల్ఫాన్సో)',
        'variant': '1yr Grafted',
        'price': 220.0,
        'stock': 120,
        'minStock': 30,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/918643/pexels-photo-918643.jpeg',
      },
      {
        'id': 'P003',
        'varietyId': 'VAR001',
        'categoryId': 'CAT001',
        'name': 'Mango (Totapuri)',
        'nameTe': 'మామిడి (తోతాపురి)',
        'variant': '2yr Grafted',
        'price': 160.0,
        'stock': 180,
        'minStock': 40,
        'active': true,
        'imageUrl':
            'https://images.pixabay.com/photo/2017/01/20/15/06/mango-1995056_960_720.jpg',
      },
      {
        'id': 'P004',
        'varietyId': 'VAR002',
        'categoryId': 'CAT001',
        'name': 'Guava (Allahabad)',
        'nameTe': 'జామ (అలహాబాద్)',
        'variant': '1yr Seedling',
        'price': 80.0,
        'stock': 350,
        'minStock': 80,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/4750270/pexels-photo-4750270.jpeg',
      },
      {
        'id': 'P005',
        'varietyId': 'VAR002',
        'categoryId': 'CAT001',
        'name': 'Guava (Taiwan Pink)',
        'nameTe': 'జామ (తైవాన్ పింక్)',
        'variant': '1yr Grafted',
        'price': 120.0,
        'stock': 150,
        'minStock': 40,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/4750270/pexels-photo-4750270.jpeg',
      },
      {
        'id': 'P006',
        'varietyId': 'VAR006',
        'categoryId': 'CAT002',
        'name': 'Coconut (Hybrid)',
        'nameTe': 'కొబ్బరి (హైబ్రిడ్)',
        'variant': '6-month',
        'price': 300.0,
        'stock': 150,
        'minStock': 30,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/1974052/pexels-photo-1974052.jpeg',
      },
      {
        'id': 'P007',
        'varietyId': 'VAR006',
        'categoryId': 'CAT002',
        'name': 'Coconut (Dwarf)',
        'nameTe': 'కొబ్బరి (పొట్టి)',
        'variant': '1yr',
        'price': 250.0,
        'stock': 80,
        'minStock': 20,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/1974052/pexels-photo-1974052.jpeg',
      },
      {
        'id': 'P008',
        'varietyId': 'VAR007',
        'categoryId': 'CAT003',
        'name': 'Teak (Grade A)',
        'nameTe': 'టేకు (గ్రేడ్ A)',
        'variant': '1yr Seedling',
        'price': 120.0,
        'stock': 500,
        'minStock': 100,
        'active': true,
        'imageUrl':
            'https://images.pixabay.com/photo/2015/12/01/20/28/road-1072823_960_720.jpg',
      },
      {
        'id': 'P009',
        'varietyId': 'VAR008',
        'categoryId': 'CAT003',
        'name': 'Neem',
        'nameTe': 'వేప',
        'variant': '6-month',
        'price': 50.0,
        'stock': 800,
        'minStock': 150,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/1002703/pexels-photo-1002703.jpeg',
      },
      {
        'id': 'P010',
        'varietyId': 'VAR009',
        'categoryId': 'CAT003',
        'name': 'Eucalyptus',
        'nameTe': 'యూకలిప్టస్',
        'variant': '6-month',
        'price': 40.0,
        'stock': 1000,
        'minStock': 200,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/1002703/pexels-photo-1002703.jpeg',
      },
      {
        'id': 'P011',
        'varietyId': 'VAR010',
        'categoryId': 'CAT004',
        'name': 'Rose (Red)',
        'nameTe': 'గులాబి (ఎరుపు)',
        'variant': 'Grafted',
        'price': 45.0,
        'stock': 0,
        'minStock': 100,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/56866/garden-rose-red-pink-56866.jpeg',
      },
      {
        'id': 'P012',
        'varietyId': 'VAR010',
        'categoryId': 'CAT004',
        'name': 'Rose (Pink)',
        'nameTe': 'గులాబి (గులాబి రంగు)',
        'variant': 'Grafted',
        'price': 45.0,
        'stock': 250,
        'minStock': 80,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/56866/garden-rose-red-pink-56866.jpeg',
      },
      {
        'id': 'P013',
        'varietyId': 'VAR011',
        'categoryId': 'CAT004',
        'name': 'Jasmine (Mogra)',
        'nameTe': 'మల్లె (మోగ్రా)',
        'variant': 'Rooted cutting',
        'price': 30.0,
        'stock': 600,
        'minStock': 120,
        'active': true,
        'imageUrl':
            'https://images.pixabay.com/photo/2016/08/31/11/54/icon-1633249_960_720.jpg',
      },
      {
        'id': 'P014',
        'varietyId': 'VAR013',
        'categoryId': 'CAT005',
        'name': 'Banana (G9 Tissue)',
        'nameTe': 'అరటి (G9 టిష్యూ)',
        'variant': 'TC Plant',
        'price': 150.0,
        'stock': 300,
        'minStock': 60,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/2316466/pexels-photo-2316466.jpeg',
      },
      {
        'id': 'P015',
        'varietyId': 'VAR013',
        'categoryId': 'CAT005',
        'name': 'Banana (Robusta)',
        'nameTe': 'అరటి (రోబస్టా)',
        'variant': 'Sucker',
        'price': 80.0,
        'stock': 450,
        'minStock': 90,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/2316466/pexels-photo-2316466.jpeg',
      },
      {
        'id': 'P016',
        'varietyId': 'VAR003',
        'categoryId': 'CAT001',
        'name': 'Sapota (Cricket Ball)',
        'nameTe': 'సపోట (క్రికెట్ బాల్)',
        'variant': '1yr Grafted',
        'price': 100.0,
        'stock': 200,
        'minStock': 40,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/1132047/pexels-photo-1132047.jpeg',
      },
      {
        'id': 'P017',
        'varietyId': 'VAR004',
        'categoryId': 'CAT001',
        'name': 'Pomegranate (Bhagwa)',
        'nameTe': 'దానిమ్మ (భగ్వా)',
        'variant': '1yr Cutting',
        'price': 130.0,
        'stock': 160,
        'minStock': 35,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/1435735/pexels-photo-1435735.jpeg',
      },
      {
        'id': 'P018',
        'varietyId': 'VAR014',
        'categoryId': 'CAT006',
        'name': 'Tulsi',
        'nameTe': 'తులసి',
        'variant': 'Pot plant',
        'price': 20.0,
        'stock': 500,
        'minStock': 100,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/1002703/pexels-photo-1002703.jpeg',
      },
      {
        'id': 'P019',
        'varietyId': 'VAR015',
        'categoryId': 'CAT006',
        'name': 'Aloe Vera',
        'nameTe': 'కలబంద',
        'variant': 'Pot plant',
        'price': 35.0,
        'stock': 400,
        'minStock': 80,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/1002703/pexels-photo-1002703.jpeg',
      },
      {
        'id': 'P020',
        'varietyId': 'VAR005',
        'categoryId': 'CAT001',
        'name': 'Lemon (Kagzi)',
        'nameTe': 'నిమ్మ (కాగ్జీ)',
        'variant': '1yr Grafted',
        'price': 90.0,
        'stock': 280,
        'minStock': 60,
        'active': true,
        'imageUrl':
            'https://images.pexels.com/photos/1132047/pexels-photo-1132047.jpeg',
      },
    ];
    final batch = _fs.firestore.batch();
    for (final v in variants) {
      batch.set(_fs.plantVariants.doc(v['id'] as String), {
        ...v,
        'createdAt': _fs.now,
        'updatedAt': _fs.now,
      });
    }
    await batch.commit();
  }

  // ─── Orders ────────────────────────────────────────────────────────────────
  Future<void> _seedOrders() async {
    final now = DateTime.now();
    final orders = [
      {
        'id': 'ORD-2408-001',
        'customerId': 'C001',
        'customerName': 'Venkata Rao',
        'villageId': 'V001',
        'villageName': 'Kondapalli',
        'totalAmount': 4800.0,
        'advanceAmount': 2400.0,
        'pendingAmount': 2400.0,
        'status': 'pending',
        'orderDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day, 8, 30),
        ),
        'deliveryDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 3),
        ),
        'notes': 'Deliver before noon',
        'itemCount': 2,
      },
      {
        'id': 'ORD-2408-002',
        'customerId': 'C002',
        'customerName': 'Lakshmi Devi',
        'villageId': 'V002',
        'villageName': 'Nuzvid',
        'totalAmount': 6000.0,
        'advanceAmount': 6000.0,
        'pendingAmount': 0.0,
        'status': 'paid',
        'orderDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day, 9, 0),
        ),
        'deliveryDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 2),
        ),
        'notes': '',
        'itemCount': 1,
      },
      {
        'id': 'ORD-2408-003',
        'customerId': 'C003',
        'customerName': 'Srinivasa Reddy',
        'villageId': 'V003',
        'villageName': 'Eluru',
        'totalAmount': 12500.0,
        'advanceAmount': 7500.0,
        'pendingAmount': 5000.0,
        'status': 'confirmed',
        'orderDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day, 11, 0),
        ),
        'deliveryDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 5),
        ),
        'notes': 'Large order - arrange vehicle',
        'itemCount': 2,
      },
      {
        'id': 'ORD-2408-004',
        'customerId': 'C004',
        'customerName': 'Padma Kumari',
        'villageId': 'V004',
        'villageName': 'Vijayawada',
        'totalAmount': 3200.0,
        'advanceAmount': 1600.0,
        'pendingAmount': 1600.0,
        'status': 'delivered',
        'orderDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day, 13, 0),
        ),
        'deliveryDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day),
        ),
        'notes': '',
        'itemCount': 2,
      },
      {
        'id': 'ORD-2408-005',
        'customerId': 'C005',
        'customerName': 'Raju Naidu',
        'villageId': 'V005',
        'villageName': 'Gudivada',
        'totalAmount': 5250.0,
        'advanceAmount': 0.0,
        'pendingAmount': 5250.0,
        'status': 'pending',
        'orderDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day, 15, 0),
        ),
        'deliveryDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 4),
        ),
        'notes': 'Call before delivery',
        'itemCount': 1,
      },
      {
        'id': 'ORD-2408-006',
        'customerId': 'C006',
        'customerName': 'Govinda Rao',
        'villageId': 'V006',
        'villageName': 'Tenali',
        'totalAmount': 4500.0,
        'advanceAmount': 2000.0,
        'pendingAmount': 2500.0,
        'status': 'confirmed',
        'orderDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day, 16, 30),
        ),
        'deliveryDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 3),
        ),
        'notes': '',
        'itemCount': 1,
      },
      {
        'id': 'ORD-2407-001',
        'customerId': 'C007',
        'customerName': 'Sarada Devi',
        'villageId': 'V007',
        'villageName': 'Guntur',
        'totalAmount': 8400.0,
        'advanceAmount': 8400.0,
        'pendingAmount': 0.0,
        'status': 'paid',
        'orderDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day - 1, 10, 0),
        ),
        'deliveryDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day - 1),
        ),
        'notes': '',
        'itemCount': 3,
      },
      {
        'id': 'ORD-2407-002',
        'customerId': 'C008',
        'customerName': 'Krishnamurthy',
        'villageId': 'V008',
        'villageName': 'Machilipatnam',
        'totalAmount': 3600.0,
        'advanceAmount': 1800.0,
        'pendingAmount': 1800.0,
        'status': 'delivered',
        'orderDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day - 1, 14, 0),
        ),
        'deliveryDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day - 1),
        ),
        'notes': '',
        'itemCount': 1,
      },
      {
        'id': 'ORD-2406-001',
        'customerId': 'C009',
        'customerName': 'Annapurna',
        'villageId': 'V009',
        'villageName': 'Bhimavaram',
        'totalAmount': 6750.0,
        'advanceAmount': 6750.0,
        'pendingAmount': 0.0,
        'status': 'paid',
        'orderDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day - 2, 9, 30),
        ),
        'deliveryDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day - 2),
        ),
        'notes': '',
        'itemCount': 2,
      },
      {
        'id': 'ORD-2406-002',
        'customerId': 'C010',
        'customerName': 'Suresh Babu',
        'villageId': 'V001',
        'villageName': 'Kondapalli',
        'totalAmount': 18000.0,
        'advanceAmount': 9000.0,
        'pendingAmount': 9000.0,
        'status': 'confirmed',
        'orderDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day - 2, 11, 0),
        ),
        'deliveryDate': Timestamp.fromDate(
          DateTime(now.year, now.month, now.day + 7),
        ),
        'notes': 'Bulk order for farm',
        'itemCount': 4,
      },
    ];
    final batch = _fs.firestore.batch();
    for (final o in orders) {
      batch.set(_fs.orders.doc(o['id'] as String), {
        ...o,
        'createdAt': _fs.now,
        'updatedAt': _fs.now,
      });
    }
    await batch.commit();
  }

  // ─── Order Items ───────────────────────────────────────────────────────────
  Future<void> _seedOrderItems() async {
    final items = [
      {
        'id': 'OI-001',
        'orderId': 'ORD-2408-001',
        'plantId': 'P001',
        'plantName': 'Mango (Banganapalli)',
        'variant': '2yr Grafted',
        'quantity': 12,
        'unitPrice': 180.0,
        'totalPrice': 2160.0,
      },
      {
        'id': 'OI-002',
        'orderId': 'ORD-2408-001',
        'plantId': 'P004',
        'plantName': 'Guava (Allahabad)',
        'variant': '1yr Seedling',
        'quantity': 8,
        'unitPrice': 80.0,
        'totalPrice': 640.0,
      },
      {
        'id': 'OI-003',
        'orderId': 'ORD-2408-002',
        'plantId': 'P006',
        'plantName': 'Coconut (Hybrid)',
        'variant': '6-month',
        'quantity': 20,
        'unitPrice': 300.0,
        'totalPrice': 6000.0,
      },
      {
        'id': 'OI-004',
        'orderId': 'ORD-2408-003',
        'plantId': 'P008',
        'plantName': 'Teak (Grade A)',
        'variant': '1yr Seedling',
        'quantity': 50,
        'unitPrice': 120.0,
        'totalPrice': 6000.0,
      },
      {
        'id': 'OI-005',
        'orderId': 'ORD-2408-003',
        'plantId': 'P009',
        'plantName': 'Neem',
        'variant': '6-month',
        'quantity': 30,
        'unitPrice': 50.0,
        'totalPrice': 1500.0,
      },
      {
        'id': 'OI-006',
        'orderId': 'ORD-2408-004',
        'plantId': 'P011',
        'plantName': 'Rose (Red)',
        'variant': 'Grafted',
        'quantity': 40,
        'unitPrice': 45.0,
        'totalPrice': 1800.0,
      },
      {
        'id': 'OI-007',
        'orderId': 'ORD-2408-004',
        'plantId': 'P013',
        'plantName': 'Jasmine (Mogra)',
        'variant': 'Rooted cutting',
        'quantity': 60,
        'unitPrice': 30.0,
        'totalPrice': 1800.0,
      },
      {
        'id': 'OI-008',
        'orderId': 'ORD-2408-005',
        'plantId': 'P014',
        'plantName': 'Banana (G9 Tissue)',
        'variant': 'TC Plant',
        'quantity': 35,
        'unitPrice': 150.0,
        'totalPrice': 5250.0,
      },
      {
        'id': 'OI-009',
        'orderId': 'ORD-2408-006',
        'plantId': 'P001',
        'plantName': 'Mango (Banganapalli)',
        'variant': '2yr Grafted',
        'quantity': 25,
        'unitPrice': 180.0,
        'totalPrice': 4500.0,
      },
      {
        'id': 'OI-010',
        'orderId': 'ORD-2407-001',
        'plantId': 'P006',
        'plantName': 'Coconut (Hybrid)',
        'variant': '6-month',
        'quantity': 15,
        'unitPrice': 300.0,
        'totalPrice': 4500.0,
      },
      {
        'id': 'OI-011',
        'orderId': 'ORD-2407-001',
        'plantId': 'P004',
        'plantName': 'Guava (Allahabad)',
        'variant': '1yr Seedling',
        'quantity': 20,
        'unitPrice': 80.0,
        'totalPrice': 1600.0,
      },
      {
        'id': 'OI-012',
        'orderId': 'ORD-2407-001',
        'plantId': 'P013',
        'plantName': 'Jasmine (Mogra)',
        'variant': 'Rooted cutting',
        'quantity': 30,
        'unitPrice: ': 30.0,
        'totalPrice': 900.0,
      },
    ];
    final batch = _fs.firestore.batch();
    for (final item in items) {
      batch.set(_fs.orderItems.doc(item['id'] as String), {
        ...item,
        'createdAt': _fs.now,
      });
    }
    await batch.commit();
  }

  // ─── Purchase Orders ───────────────────────────────────────────────────────
  Future<void> _seedPurchaseOrders() async {
    final pos = [
      {
        'id': 'PO-001',
        'supplierName': 'Green Valley Nursery',
        'supplierPhone': '9440111222',
        'status': 'received',
        'totalAmount': 45000.0,
        'orderDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 10)),
        ),
        'expectedDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 5)),
        ),
        'receivedDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 5)),
        ),
        'notes': 'Mango and Guava saplings',
      },
      {
        'id': 'PO-002',
        'supplierName': 'Andhra Plant Hub',
        'supplierPhone': '9849333444',
        'status': 'pending',
        'totalAmount': 28000.0,
        'orderDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 3)),
        ),
        'expectedDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 4)),
        ),
        'receivedDate': null,
        'notes': 'Coconut and Banana tissue culture',
      },
      {
        'id': 'PO-003',
        'supplierName': 'Krishna Nursery Farms',
        'supplierPhone': '9966555666',
        'status': 'confirmed',
        'totalAmount': 62000.0,
        'orderDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        'expectedDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'receivedDate': null,
        'notes': 'Timber seedlings bulk order',
      },
    ];
    final batch = _fs.firestore.batch();
    for (final po in pos) {
      batch.set(_fs.purchaseOrders.doc(po['id'] as String), {
        ...po,
        'createdAt': _fs.now,
        'updatedAt': _fs.now,
      });
    }
    await batch.commit();
  }

  // ─── Deliveries ────────────────────────────────────────────────────────────
  Future<void> _seedDeliveries() async {
    final deliveries = [
      {
        'id': 'DEL-001',
        'orderId': 'ORD-2408-004',
        'customerId': 'C004',
        'customerName': 'Padma Kumari',
        'villageName': 'Vijayawada',
        'status': 'delivered',
        'scheduledDate': Timestamp.fromDate(DateTime.now()),
        'deliveredDate': Timestamp.fromDate(DateTime.now()),
        'driverName': 'Ravi Kumar',
        'vehicleNumber': 'AP16AB1234',
        'notes': '',
      },
      {
        'id': 'DEL-002',
        'orderId': 'ORD-2407-001',
        'customerId': 'C007',
        'customerName': 'Sarada Devi',
        'villageName': 'Guntur',
        'status': 'delivered',
        'scheduledDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        'deliveredDate': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
        'driverName': 'Suresh',
        'vehicleNumber': 'AP16CD5678',
        'notes': '',
      },
      {
        'id': 'DEL-003',
        'orderId': 'ORD-2408-001',
        'customerId': 'C001',
        'customerName': 'Venkata Rao',
        'villageName': 'Kondapalli',
        'status': 'scheduled',
        'scheduledDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 3)),
        ),
        'deliveredDate': null,
        'driverName': 'Ravi Kumar',
        'vehicleNumber': 'AP16AB1234',
        'notes': 'Deliver before noon',
      },
    ];
    final batch = _fs.firestore.batch();
    for (final d in deliveries) {
      batch.set(_fs.deliveries.doc(d['id'] as String), {
        ...d,
        'createdAt': _fs.now,
        'updatedAt': _fs.now,
      });
    }
    await batch.commit();
  }

  // ─── Payments ──────────────────────────────────────────────────────────────
  Future<void> _seedPayments() async {
    final payments = [
      {
        'id': 'PAY-001',
        'orderId': 'ORD-2408-002',
        'customerId': 'C002',
        'customerName': 'Lakshmi Devi',
        'amount': 6000.0,
        'paymentMode': 'cash',
        'type': 'full',
        'status': 'completed',
        'paidAt': Timestamp.fromDate(DateTime.now()),
      },
      {
        'id': 'PAY-002',
        'orderId': 'ORD-2408-001',
        'customerId': 'C001',
        'customerName': 'Venkata Rao',
        'amount': 2400.0,
        'paymentMode': 'upi',
        'type': 'advance',
        'status': 'completed',
        'paidAt': Timestamp.fromDate(DateTime.now()),
      },
      {
        'id': 'PAY-003',
        'orderId': 'ORD-2408-003',
        'customerId': 'C003',
        'customerName': 'Srinivasa Reddy',
        'amount': 7500.0,
        'paymentMode': 'bank_transfer',
        'type': 'advance',
        'status': 'completed',
        'paidAt': Timestamp.fromDate(DateTime.now()),
      },
      {
        'id': 'PAY-004',
        'orderId': 'ORD-2407-001',
        'customerId': 'C007',
        'customerName': 'Sarada Devi',
        'amount': 8400.0,
        'paymentMode': 'cash',
        'type': 'full',
        'status': 'completed',
        'paidAt': Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 1)),
        ),
      },
      {
        'id': 'PAY-005',
        'orderId': 'ORD-2408-004',
        'customerId': 'C004',
        'customerName': 'Padma Kumari',
        'amount': 1600.0,
        'paymentMode': 'cash',
        'type': 'advance',
        'status': 'completed',
        'paidAt': Timestamp.fromDate(DateTime.now()),
      },
    ];
    final batch = _fs.firestore.batch();
    for (final p in payments) {
      batch.set(_fs.payments.doc(p['id'] as String), {
        ...p,
        'createdAt': _fs.now,
      });
    }
    await batch.commit();
  }

  // ─── Inventory ─────────────────────────────────────────────────────────────
  Future<void> _seedInventory() async {
    final batch = _fs.firestore.batch();
    final inventoryItems = [
      {
        'id': 'INV-P001',
        'plantId': 'P001',
        'plantName': 'Mango (Banganapalli)',
        'currentStock': 200,
        'reservedStock': 37,
        'availableStock': 163,
        'minStock': 50,
        'lastUpdated': _fs.now,
      },
      {
        'id': 'INV-P002',
        'plantId': 'P002',
        'plantName': 'Mango (Alphonso)',
        'currentStock': 120,
        'reservedStock': 0,
        'availableStock': 120,
        'minStock': 30,
        'lastUpdated': _fs.now,
      },
      {
        'id': 'INV-P003',
        'plantId': 'P003',
        'plantName': 'Mango (Totapuri)',
        'currentStock': 180,
        'reservedStock': 0,
        'availableStock': 180,
        'minStock': 40,
        'lastUpdated': _fs.now,
      },
      {
        'id': 'INV-P004',
        'plantId': 'P004',
        'plantName': 'Guava (Allahabad)',
        'currentStock': 350,
        'reservedStock': 28,
        'availableStock': 322,
        'minStock': 80,
        'lastUpdated': _fs.now,
      },
      {
        'id': 'INV-P006',
        'plantId': 'P006',
        'plantName': 'Coconut (Hybrid)',
        'currentStock': 150,
        'reservedStock': 35,
        'availableStock': 115,
        'minStock': 30,
        'lastUpdated': _fs.now,
      },
      {
        'id': 'INV-P008',
        'plantId': 'P008',
        'plantName': 'Teak (Grade A)',
        'currentStock': 500,
        'reservedStock': 50,
        'availableStock': 450,
        'minStock': 100,
        'lastUpdated': _fs.now,
      },
      {
        'id': 'INV-P009',
        'plantId': 'P009',
        'plantName': 'Neem',
        'currentStock': 800,
        'reservedStock': 30,
        'availableStock': 770,
        'minStock': 150,
        'lastUpdated': _fs.now,
      },
      {
        'id': 'INV-P011',
        'plantId': 'P011',
        'plantName': 'Rose (Red)',
        'currentStock': 0,
        'reservedStock': 0,
        'availableStock': 0,
        'minStock': 100,
        'lastUpdated': _fs.now,
      },
      {
        'id': 'INV-P013',
        'plantId': 'P013',
        'plantName': 'Jasmine (Mogra)',
        'currentStock': 600,
        'reservedStock': 90,
        'availableStock': 510,
        'minStock': 120,
        'lastUpdated': _fs.now,
      },
      {
        'id': 'INV-P014',
        'plantId': 'P014',
        'plantName': 'Banana (G9 Tissue)',
        'currentStock': 300,
        'reservedStock': 35,
        'availableStock': 265,
        'minStock': 60,
        'lastUpdated': _fs.now,
      },
    ];
    for (final item in inventoryItems) {
      batch.set(_fs.inventory.doc(item['id'] as String), item);
    }
    await batch.commit();
  }

  // ─── Realtime Database ─────────────────────────────────────────────────────
  Future<void> _seedRealtimeDatabase() async {
    final db = FirebaseService.instance.database;
    await db.ref('dashboard').set({
      'today': {
        'totalOrders': 6,
        'revenue': 36250,
        'collected': 19500,
        'pending': 16750,
        'deliveries': 1,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      'week': {
        'totalOrders': 47,
        'revenue': 131000,
        'collected': 98400,
        'pending': 32600,
        'deliveries': 18,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      'month': {
        'totalOrders': 189,
        'revenue': 530000,
        'collected': 387000,
        'pending': 143000,
        'deliveries': 71,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
      'allTime': {
        'totalOrders': 1243,
        'revenue': 3800000,
        'collected': 2870000,
        'pending': 530000,
        'deliveries': 487,
        'customers': 142,
        'villages': 12,
        'lastUpdated': DateTime.now().toIso8601String(),
      },
    });

    await db.ref('inventory_alerts').set({
      'lowStock': ['P011', 'P006'],
      'outOfStock': ['P011'],
      'lastChecked': DateTime.now().toIso8601String(),
    });
  }

  // ─── Check if already seeded ───────────────────────────────────────────────
  Future<bool> isSeeded() async {
    final snap = await _fs.settings.doc('app_settings').get();
    return snap.exists;
  }
}
