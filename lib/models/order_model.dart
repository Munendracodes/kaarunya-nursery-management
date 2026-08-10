import 'package:firebase_database/firebase_database.dart';

class OrderItemModel {
  final String plantId;
  final String plantName;

  final String varietyId;
  final String varietyName;

  final String variantId;
  final String variantName;

  final double weight;
  final int years;

  final int quantity;
  final double price;
  final double discount;
  final double total;

  OrderItemModel({
    required this.plantId,
    required this.plantName,
    required this.varietyId,
    required this.varietyName,
    required this.variantId,
    required this.variantName,
    required this.weight,
    required this.years,
    required this.quantity,
    required this.price,
    required this.discount,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'plantId': plantId,
      'plantName': plantName,
      'varietyId': varietyId,
      'varietyName': varietyName,
      'variantId': variantId,
      'variantName': variantName,
      'weight': weight,
      'years': years,
      'quantity': quantity,
      'price': price,
      'discount': discount,
      'total': total,
    };
  }
}

class OrderModel {
  final String orderId;
  final String orderNumber;

  final String customerId;
  final String customerMobile;
  final String customerName;
  final String customerFatherName;
  final String customerVillage;

  final double subtotal;
  final double discount;
  final double total;

  final double totalPaid;
  final double balance;

  final String orderStatus;
  final String paymentStatus;

  final List<OrderItemModel> items;

  OrderModel({
    required this.orderId,
    required this.orderNumber,
    required this.customerId,
    required this.customerMobile,
    required this.customerName,
    required this.customerFatherName,
    required this.customerVillage,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.totalPaid,
    required this.balance,
    required this.orderStatus,
    required this.paymentStatus,
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerMobile': customerMobile,
      'customerName': customerName,
      'customerFatherName': customerFatherName,
      'customerVillage': customerVillage,
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'totalPaid': totalPaid,
      'balance': balance,
      'orderStatus': orderStatus,
      'paymentStatus': paymentStatus,
      'createdAt': ServerValue.timestamp,
    };
  }
}