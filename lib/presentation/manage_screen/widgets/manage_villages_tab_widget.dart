import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../services/firestore_repository.dart';

class ManageVillagesTabWidget extends StatefulWidget {
  const ManageVillagesTabWidget({super.key});

  @override
  State<ManageVillagesTabWidget> createState() =>
      _ManageVillagesTabWidgetState();
}

class _ManageVillagesTabWidgetState extends State<ManageVillagesTabWidget> {
  String _query = '';
  List<Map<String, dynamic>> _villages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final villages = await FirestoreRepository.instance.getVillages();
      if (mounted) {
        setState(() {
          _villages = villages;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _villages;
    return _villages
        .where(
          (v) =>
              (v['name'] as String? ?? '').toLowerCase().contains(
                _query.toLowerCase(),
              ) ||
              (v['district'] as String? ?? '').toLowerCase().contains(
                _query.toLowerCase(),
              ),
        )
        .toList();
  }

  void _showAddVillageDialog() {
    final nameCtrl = TextEditingController();
    final districtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Village'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Village Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: districtCtrl,
              decoration: const InputDecoration(labelText: 'District'),
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
              if (nameCtrl.text.isNotEmpty) {
                await FirestoreRepository.instance.addVillage({
                  'name': nameCtrl.text,
                  'district': districtCtrl.text,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextFormField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search villages...',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
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
                        Icons.location_on_outlined,
                        size: 48,
                        color: AppTheme.primaryLight,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No villages found',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _showAddVillageDialog,
                        icon: const Icon(Icons.add_location),
                        label: const Text('Add Village'),
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
                      final village = _filtered[i];
                      final pending =
                          (village['pendingAmount'] as num?)?.toDouble() ?? 0.0;
                      final isActive = village['active'] as bool? ?? true;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: !isActive
                              ? Border.all(
                                  color: AppTheme.error.withAlpha(77),
                                  width: 1,
                                )
                              : null,
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.location_city_rounded,
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
                                    village['name'] as String? ?? '',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${village['district'] ?? ''} District',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _statChip(
                                        Icons.people_outline_rounded,
                                        '${village['customerCount'] ?? 0} customers',
                                        theme,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (pending > 0) ...[
                                  Text(
                                    pending >= 1000
                                        ? '₹${(pending / 1000).toStringAsFixed(1)}K'
                                        : '₹${pending.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                  const Text(
                                    'pending',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                ] else
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppTheme.success,
                                    size: 20,
                                  ),
                                const SizedBox(height: 8),
                                Icon(
                                  isActive
                                      ? Icons.toggle_on_rounded
                                      : Icons.toggle_off_rounded,
                                  color: isActive
                                      ? AppTheme.primary
                                      : Colors.grey,
                                  size: 28,
                                ),
                              ],
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

  Widget _statChip(IconData icon, String label, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
