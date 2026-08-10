import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/firestore_repository.dart';

class PlantItemsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Function(List<Map<String, dynamic>>) onItemsChanged;

  const PlantItemsWidget({
    required this.items,
    required this.onItemsChanged,
    super.key,
  });

  @override
  State<PlantItemsWidget> createState() => _PlantItemsWidgetState();
}

class _PlantItemsWidgetState extends State<PlantItemsWidget> {
  List<Map<String, dynamic>> _plants = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    try {
      final plants = await FirestoreRepository.instance.getPlants();
      if (mounted) {
        setState(() {
          _plants = plants.where((p) => p['active'] as bool? ?? true).toList();
          _filtered = _plants;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _filtered = _plants;
      } else {
        final lower = query.toLowerCase();
        _filtered = _plants
            .where(
              (p) => (p['name'] as String? ?? '').toLowerCase().contains(lower),
            )
            .toList();
      }
    });
  }

  int _getQty(String plantId) {
    final item = widget.items.firstWhere(
      (i) => i['id'] == plantId,
      orElse: () => {},
    );
    return item.isEmpty ? 0 : (item['qty'] as int? ?? 0);
  }

  void _updateQty(Map<String, dynamic> plant, int delta) {
    final id = plant['id'] as String;
    final currentItems = List<Map<String, dynamic>>.from(widget.items);
    final idx = currentItems.indexWhere((i) => i['id'] == id);
    final currentQty = idx >= 0 ? (currentItems[idx]['qty'] as int) : 0;
    final newQty = (currentQty + delta).clamp(0, 9999);

    if (newQty == 0) {
      if (idx >= 0) currentItems.removeAt(idx);
    } else if (idx >= 0) {
      currentItems[idx] = {...currentItems[idx], 'qty': newQty};
    } else {
      currentItems.add({
        'id': id,
        'name': plant['name'],
        'variant': plant['variant'] ?? '',
        'price': (plant['price'] as num?)?.toDouble() ?? 0.0,
        'qty': newQty,
      });
    }
    widget.onItemsChanged(currentItems);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: _onSearch,
            decoration: const InputDecoration(
              hintText: 'Search plants...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        if (widget.items.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  color: AppTheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.items.length} item(s) · ₹${widget.items.fold(0.0, (s, i) => s + (i['price'] as double) * (i['qty'] as int)).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
              ? Center(
                  child: Text(
                    'No plants found',
                    style: theme.textTheme.bodyLarge,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final plant = _filtered[i];
                    final id = plant['id'] as String;
                    final qty = _getQty(id);
                    final stock = (plant['stock'] as num?)?.toInt() ?? 0;
                    final price = (plant['price'] as num?)?.toDouble() ?? 0.0;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: qty > 0
                            ? AppTheme.primaryContainer
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: qty > 0
                            ? Border.all(color: AppTheme.primary, width: 1.5)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariantLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.eco_rounded,
                              color: AppTheme.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  plant['name'] as String? ?? '',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${plant['variant'] ?? ''} · Stock: $stock',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '₹${price.toStringAsFixed(0)} each',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (qty > 0) ...[
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline_rounded,
                                  ),
                                  color: AppTheme.primary,
                                  onPressed: () => _updateQty(plant, -1),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '$qty',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                                color: AppTheme.primary,
                                onPressed: stock > 0
                                    ? () => _updateQty(plant, 1)
                                    : null,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
