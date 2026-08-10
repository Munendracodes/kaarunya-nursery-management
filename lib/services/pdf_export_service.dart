import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfExportService {
  static final PdfExportService instance = PdfExportService._();
  PdfExportService._();

  // ─── Color palette matching app theme ───────────────────────────────────────
  static const _primaryColor = PdfColor.fromInt(0xFF2E7D32);
  static const _primaryLight = PdfColor.fromInt(0xFF81C784);
  static const _bgLight = PdfColor.fromInt(0xFFF5F5F5);
  static const _textDark = PdfColor.fromInt(0xFF212121);
  static const _textMuted = PdfColor.fromInt(0xFF757575);
  static const _white = PdfColors.white;
  static const _divider = PdfColor.fromInt(0xFFE0E0E0);
  static const _successColor = PdfColor.fromInt(0xFF388E3C);
  static const _warningColor = PdfColor.fromInt(0xFFF57C00);

  // ─── Export Order Details PDF ────────────────────────────────────────────────
  Future<void> exportOrderDetails({
    required List<Map<String, dynamic>> orders,
    required DateTime selectedDate,
    required String statusFilter,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          'Order Management Report',
          'Date: ${_formatDate(selectedDate)} | Filter: $statusFilter',
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildOrderSummarySection(orders),
          pw.SizedBox(height: 20),
          _buildOrdersTable(orders),
        ],
      ),
    );

    await _sharePdf(pdf, 'orders_${_fileDate(selectedDate)}.pdf');
  }

  // ─── Export Payment History PDF ──────────────────────────────────────────────
  Future<void> exportPaymentHistory({
    required List<Map<String, dynamic>> payments,
  }) async {
    final pdf = pw.Document();

    final totalCollected = payments.fold<double>(
      0,
      (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          'Payment History Report',
          'Generated: ${_formatDate(DateTime.now())}',
        ),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildPaymentSummarySection(payments, totalCollected),
          pw.SizedBox(height: 20),
          _buildPaymentsTable(payments),
        ],
      ),
    );

    await _sharePdf(pdf, 'payments_${_fileDate(DateTime.now())}.pdf');
  }

  // ─── Header ──────────────────────────────────────────────────────────────────
  pw.Widget _buildHeader(String title, String subtitle) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _primaryColor, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Kaarunya Nursery',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 13,
                  color: _textDark,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                subtitle,
                style: pw.TextStyle(fontSize: 9, color: _textMuted),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: _primaryColor,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              'OFFICIAL',
              style: pw.TextStyle(
                fontSize: 10,
                color: _white,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Footer ──────────────────────────────────────────────────────────────────
  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _divider, width: 1)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Kaarunya Nursery Management System',
            style: pw.TextStyle(fontSize: 8, color: _textMuted),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: _textMuted),
          ),
        ],
      ),
    );
  }

  // ─── Order Summary Section ───────────────────────────────────────────────────
  pw.Widget _buildOrderSummarySection(List<Map<String, dynamic>> orders) {
    final totalOrders = orders.length;
    final totalAmount = orders.fold<double>(
      0,
      (sum, o) => sum + ((o['totalAmount'] as num?)?.toDouble() ?? 0),
    );
    final totalPending = orders.fold<double>(
      0,
      (sum, o) => sum + ((o['pendingAmount'] as num?)?.toDouble() ?? 0),
    );
    final pendingCount = orders.where((o) => o['status'] == 'pending').length;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _bgLight,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _divider),
      ),
      child: pw.Row(
        children: [
          _buildSummaryTile('Total Orders', '$totalOrders', _primaryColor),
          _buildSummaryTile(
            'Invoice Total',
            '₹${totalAmount.toStringAsFixed(2)}',
            _successColor,
          ),
          _buildSummaryTile(
            'Pending Amount',
            '₹${totalPending.toStringAsFixed(2)}',
            _warningColor,
          ),
          _buildSummaryTile('Pending Orders', '$pendingCount', _warningColor),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryTile(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 8, color: _textMuted),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Orders Table ────────────────────────────────────────────────────────────
  pw.Widget _buildOrdersTable(List<Map<String, dynamic>> orders) {
    return pw.Table(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primaryColor),
          children: [
            _tableHeader('Order ID'),
            _tableHeader('Customer'),
            _tableHeader('Village'),
            _tableHeader('Total (₹)'),
            _tableHeader('Pending (₹)'),
            _tableHeader('Status'),
          ],
        ),
        // Data rows
        ...orders.asMap().entries.map((entry) {
          final i = entry.key;
          final order = entry.value;
          final isEven = i % 2 == 0;
          final status = order['status'] as String? ?? 'pending';
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? _white : _bgLight),
            children: [
              _tableCell(
                (order['id'] as String? ?? '').length > 8
                    ? '...${(order['id'] as String).substring((order['id'] as String).length - 8)}'
                    : (order['id'] as String? ?? ''),
              ),
              _tableCell(order['customerName'] as String? ?? ''),
              _tableCell(order['villageName'] as String? ?? ''),
              _tableCell(
                '₹${((order['totalAmount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
              ),
              _tableCell(
                '₹${((order['pendingAmount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
              ),
              _tableCellStatus(status),
            ],
          );
        }),
      ],
    );
  }

  // ─── Payment Summary Section ─────────────────────────────────────────────────
  pw.Widget _buildPaymentSummarySection(
    List<Map<String, dynamic>> payments,
    double totalCollected,
  ) {
    final cashTotal = _sumByMethod(payments, 'cash');
    final upiTotal = _sumByMethod(payments, 'upi');
    final bankTotal = _sumByMethod(payments, 'bank_transfer');
    final chequeTotal = _sumByMethod(payments, 'cheque');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: _primaryColor,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Total Collected',
                    style: pw.TextStyle(fontSize: 10, color: _white),
                  ),
                  pw.Text(
                    '₹${totalCollected.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: _white,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    '${payments.length} Transactions',
                    style: pw.TextStyle(fontSize: 10, color: _white),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _bgLight,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: _divider),
          ),
          child: pw.Row(
            children: [
              _buildMethodSummary('Cash', cashTotal),
              _buildMethodSummary('UPI', upiTotal),
              _buildMethodSummary('Bank Transfer', bankTotal),
              _buildMethodSummary('Cheque', chequeTotal),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMethodSummary(String method, double amount) {
    return pw.Expanded(
      child: pw.Column(
        children: [
          pw.Text(
            '₹${amount.toStringAsFixed(0)}',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            method,
            style: pw.TextStyle(fontSize: 8, color: _textMuted),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Payments Table ──────────────────────────────────────────────────────────
  pw.Widget _buildPaymentsTable(List<Map<String, dynamic>> payments) {
    return pw.Table(
      border: pw.TableBorder.all(color: _divider, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _primaryColor),
          children: [
            _tableHeader('Customer'),
            _tableHeader('Amount (₹)'),
            _tableHeader('Method'),
            _tableHeader('Pending After'),
            _tableHeader('Date'),
          ],
        ),
        ...payments.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final isEven = i % 2 == 0;
          final paidAt = _parseDateDynamic(p['paidAt']);
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: isEven ? _white : _bgLight),
            children: [
              _tableCell(p['customerName'] as String? ?? ''),
              _tableCell(
                '₹${((p['amount'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
              ),
              _tableCell(_methodLabel(p['paymentMode'] as String? ?? 'cash')),
              _tableCell(
                '₹${((p['pendingAfter'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
              ),
              _tableCell(_formatDate(paidAt)),
            ],
          );
        }),
      ],
    );
  }

  // ─── Table helpers ───────────────────────────────────────────────────────────
  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _white,
        ),
      ),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, color: _textDark)),
    );
  }

  pw.Widget _tableCellStatus(String status) {
    final color = status == 'paid' || status == 'delivered'
        ? _successColor
        : status == 'cancelled'
        ? const PdfColor.fromInt(0xFFD32F2F)
        : _warningColor;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          status.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: _white,
          ),
        ),
      ),
    );
  }

  // ─── Utilities ───────────────────────────────────────────────────────────────
  double _sumByMethod(List<Map<String, dynamic>> payments, String method) {
    return payments
        .where((p) => (p['paymentMode'] as String? ?? '') == method)
        .fold<double>(
          0,
          (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0),
        );
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'upi':
        return 'UPI';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'cheque':
        return 'Cheque';
      default:
        return 'Cash';
    }
  }

  DateTime _parseDateDynamic(dynamic val) {
    if (val is DateTime) return val;
    try {
      // Firestore Timestamp has toDate()
      return (val as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _fileDate(DateTime dt) {
    return '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _sharePdf(pw.Document pdf, String filename) async {
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }
}
