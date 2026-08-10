import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum OrderStatus { pending, confirmed, purchased, delivered, cancelled, paid }

class StatusBadgeWidget extends StatelessWidget {
  final OrderStatus status;
  final bool compact;

  const StatusBadgeWidget({
    required this.status,
    this.compact = false,
    super.key,
  });

  String get _label {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.purchased:
        return 'Purchased';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.paid:
        return 'Paid';
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case OrderStatus.pending:
        return AppTheme.warningContainer;
      case OrderStatus.confirmed:
        return const Color(0xFFE3F2FD);
      case OrderStatus.purchased:
        return const Color(0xFFF3E5F5);
      case OrderStatus.delivered:
        return AppTheme.secondaryContainer;
      case OrderStatus.cancelled:
        return AppTheme.errorContainer;
      case OrderStatus.paid:
        return AppTheme.secondaryContainer;
    }
  }

  Color get _textColor {
    switch (status) {
      case OrderStatus.pending:
        return AppTheme.warning;
      case OrderStatus.confirmed:
        return AppTheme.info;
      case OrderStatus.purchased:
        return const Color(0xFF6A1B9A);
      case OrderStatus.delivered:
        return AppTheme.success;
      case OrderStatus.cancelled:
        return AppTheme.error;
      case OrderStatus.paid:
        return AppTheme.primaryDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
          color: _textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
