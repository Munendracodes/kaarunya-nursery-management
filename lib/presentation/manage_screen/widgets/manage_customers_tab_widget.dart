import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/firestore_repository.dart';

class ManageCustomersTabWidget extends StatefulWidget {
  const ManageCustomersTabWidget({super.key});

  @override
  State<ManageCustomersTabWidget> createState() =>
      _ManageCustomersTabWidgetState();
}

class _ManageCustomersTabWidgetState extends State<ManageCustomersTabWidget> {
  String _query = '';
  String _selectedVillage = 'All';
  List<Map<String, dynamic>> _customers = [];
  List<String> _villages = ['All'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final customers = await FirestoreRepository.instance.getCustomers();
      final villageSet =
          customers
              .map((c) => c['villageName'] as String? ?? '')
              .where((v) => v.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      if (mounted) {
        setState(() {
          _customers = customers;
          _villages = ['All', ...villageSet];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _customers.where((c) {
      final matchVillage =
          _selectedVillage == 'All' ||
          (c['villageName'] as String? ?? '') == _selectedVillage;
      final matchQuery =
          _query.isEmpty ||
          (c['name'] as String? ?? '').toLowerCase().contains(
            _query.toLowerCase(),
          ) ||
          (c['mobile'] as String? ?? '').contains(_query);
      return matchVillage && matchQuery;
    }).toList();
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    String selectedVillage = _villages.length > 1 ? _villages[1] : '';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Add Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Customer Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Mobile Number'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedVillage.isEmpty ? null : selectedVillage,
                decoration: const InputDecoration(labelText: 'Village'),
                items: _villages
                    .where((v) => v != 'All')
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setDlgState(() => selectedVillage = v ?? ''),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && mobileCtrl.text.isNotEmpty) {
                  await FirestoreRepository.instance.addCustomer({
                    'name': nameCtrl.text,
                    'mobile': mobileCtrl.text,
                    'villageName': selectedVillage,
                    'villageId': '',
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextFormField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search customers...',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: _villages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final v = _villages[i];
              final isSelected = v == _selectedVillage;
              return GestureDetector(
                onTap: () => setState(() => _selectedVillage = v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : AppTheme.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    v,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.primary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48,
                        color: AppTheme.primaryLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No customers found',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddCustomerDialog,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Customer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = _filtered[i];
                      final outstanding =
                          (c['pendingAmount'] as num?)?.toDouble() ?? 0.0;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: outstanding > 0
                              ? Border(
                                  left: BorderSide(
                                    color: AppTheme.warning,
                                    width: 3,
                                  ),
                                )
                              : Border(
                                  left: BorderSide(
                                    color: AppTheme.success,
                                    width: 3,
                                  ),
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariantLight,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  (c['name'] as String? ?? 'C').substring(0, 1),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['name'] as String? ?? '',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 11,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        c['villageName'] as String? ?? '',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 11,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        c['mobile'] as String? ?? '',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _statChip(
                                        Icons.receipt_outlined,
                                        '${c['totalOrders'] ?? 0} orders',
                                        theme,
                                      ),
                                      const SizedBox(width: 8),
                                      if (outstanding > 0)
                                        _statChip(
                                          Icons.pending_outlined,
                                          '₹${outstanding.toStringAsFixed(0)} due',
                                          theme,
                                          color: AppTheme.warning,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                size: 20,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _statChip(
    IconData icon,
    String label,
    ThemeData theme, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 11,
            color: color ?? theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color ?? theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
