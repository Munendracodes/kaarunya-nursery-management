import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../services/firestore_repository.dart';
import '../../services/pdf_export_service.dart';
import './widgets/payment_form_widget.dart';
import './widgets/payment_history_widget.dart';
import './widgets/payment_receipt_widget.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final orders = await FirestoreRepository.instance.getOrdersWithPending();
      final payments = await FirestoreRepository.instance.getPayments();
      if (mounted) {
        setState(() {
          _orders = orders;
          _payments = payments;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onPaymentRecorded(Map<String, dynamic> receipt) {
    _loadData();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentReceiptWidget(receipt: receipt),
    );
  }

  Future<void> _exportPaymentsPdf() async {
    if (_payments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No payment history to export')),
      );
      return;
    }
    setState(() => _isExporting = true);
    try {
      await PdfExportService.instance.exportPaymentHistory(payments: _payments);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Text(
          'Payments',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          // PDF export — only show on Payment History tab
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index != 1) return const SizedBox.shrink();
              return _isExporting
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      onPressed: _exportPaymentsPdf,
                      tooltip: 'Export Payment History as PDF',
                      color: AppTheme.primary,
                    );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: const Color(0xFF757575),
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelStyle: theme.textTheme.labelLarge,
          tabs: const [
            Tab(text: 'Record Payment'),
            Tab(text: 'Payment History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                PaymentFormWidget(
                  orders: _orders,
                  onPaymentRecorded: _onPaymentRecorded,
                ),
                PaymentHistoryWidget(payments: _payments, onRefresh: _loadData),
              ],
            ),
    );
  }
}
