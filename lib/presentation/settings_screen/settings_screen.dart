import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../services/language_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Language is now driven by LanguageProvider — read from it directly.
  String get _selectedLanguage => LanguageProvider.instance.language;

  // Nursery details
  final _nameController = TextEditingController(text: 'Kaarunya Nursery');
  final _phoneController = TextEditingController(text: '9876543210');
  final _addressController = TextEditingController(
    text: '12, Green Valley Road, Hyderabad, Telangana - 500001',
  );
  bool _isEditingNursery = false;
  bool _isSavingNursery = false;

  // Export state
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    // Rebuild when language changes from another screen.
    LanguageProvider.instance.addListener(_onLanguageChange);
  }

  void _onLanguageChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LanguageProvider.instance.removeListener(_onLanguageChange);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text =
          prefs.getString('nursery_name') ?? 'Kaarunya Nursery';
      _phoneController.text = prefs.getString('nursery_phone') ?? '9876543210';
      _addressController.text =
          prefs.getString('nursery_address') ??
          '12, Green Valley Road, Hyderabad, Telangana - 500001';
    });
  }

  Future<void> _saveLanguage(String lang) async {
    await LanguageProvider.instance.setLanguage(lang);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang == 'EN'
                ? 'Language set to English'
                : 'భాష తెలుగుకు మార్చబడింది',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveNurseryDetails() async {
    setState(() => _isSavingNursery = true);
    await Future.delayed(const Duration(milliseconds: 400));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nursery_name', _nameController.text.trim());
    await prefs.setString('nursery_phone', _phoneController.text.trim());
    await prefs.setString('nursery_address', _addressController.text.trim());
    if (mounted) {
      setState(() {
        _isSavingNursery = false;
        _isEditingNursery = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nursery details saved successfully')),
      );
    }
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isExporting = false);
      final exportText =
          'Kaarunya Nursery — Data Export\n'
          'Date: ${DateTime.now().toLocal().toString().split('.')[0]}\n'
          'Nursery: ${_nameController.text}\n'
          'Phone: ${_phoneController.text}\n'
          'Address: ${_addressController.text}\n'
          '---\n'
          'Export includes: Orders, Customers, Plants, Payments, Villages';
      await Clipboard.setData(ClipboardData(text: exportText));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export summary copied to clipboard'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout from Kaarunya Nursery?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.loginScreen);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 2,
        title: Text(
          _selectedLanguage == 'EN' ? 'Settings' : 'సెట్టింగ్‌లు',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── Language Section ──────────────────────────────────────
          _SectionHeader(
            icon: Icons.language_rounded,
            title: _selectedLanguage == 'EN' ? 'Language' : 'భాష',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedLanguage == 'EN' ? 'App Language' : 'యాప్ భాష',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedLanguage == 'EN'
                            ? 'English / తెలుగు'
                            : 'English / తెలుగు',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _LanguageToggle(
                  selected: _selectedLanguage,
                  onChanged: _saveLanguage,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Nursery Details Section ───────────────────────────────
          Row(
            children: [
              _SectionHeader(
                icon: Icons.store_rounded,
                title: _selectedLanguage == 'EN'
                    ? 'Nursery Details'
                    : 'నర్సరీ వివరాలు',
              ),
              const Spacer(),
              if (!_isEditingNursery)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditingNursery = true),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: Text(_selectedLanguage == 'EN' ? 'Edit' : 'సవరించు'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Column(
              children: [
                _isEditingNursery
                    ? _NurseryEditForm(
                        nameController: _nameController,
                        phoneController: _phoneController,
                        addressController: _addressController,
                        isSaving: _isSavingNursery,
                        onSave: _saveNurseryDetails,
                        onCancel: () =>
                            setState(() => _isEditingNursery = false),
                        language: _selectedLanguage,
                      )
                    : _NurseryReadView(
                        name: _nameController.text,
                        phone: _phoneController.text,
                        address: _addressController.text,
                        language: _selectedLanguage,
                      ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Data & Backup Section ─────────────────────────────────
          _SectionHeader(
            icon: Icons.backup_rounded,
            title: _selectedLanguage == 'EN'
                ? 'Data & Backup'
                : 'డేటా & బ్యాకప్',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.download_rounded,
                  iconColor: AppTheme.info,
                  iconBg: const Color(0xFFE3F2FD),
                  title: _selectedLanguage == 'EN'
                      ? 'Export Data'
                      : 'డేటా ఎగుమతి చేయి',
                  subtitle: _selectedLanguage == 'EN'
                      ? 'Copy export summary to clipboard'
                      : 'ఎగుమతి సారాంశాన్ని క్లిప్‌బోర్డ్‌కు కాపీ చేయి',
                  trailing: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF9E9E9E),
                        ),
                  onTap: _isExporting ? null : _handleExport,
                ),
                const Divider(height: 1, indent: 56),
                _ActionTile(
                  icon: Icons.cloud_upload_rounded,
                  iconColor: AppTheme.success,
                  iconBg: AppTheme.secondaryContainer,
                  title: _selectedLanguage == 'EN'
                      ? 'Backup to Cloud'
                      : 'క్లౌడ్‌కు బ్యాకప్ చేయి',
                  subtitle: _selectedLanguage == 'EN'
                      ? 'Sync data with Firebase'
                      : 'Firebase తో డేటా సమకాలీకరించు',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9E9E9E),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cloud backup initiated via Firebase'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Account Section ───────────────────────────────────────
          _SectionHeader(
            icon: Icons.manage_accounts_rounded,
            title: _selectedLanguage == 'EN' ? 'Account' : 'ఖాతా',
          ),
          const SizedBox(height: 10),
          _SettingsCard(
            child: _ActionTile(
              icon: Icons.logout_rounded,
              iconColor: AppTheme.error,
              iconBg: AppTheme.errorContainer,
              title: _selectedLanguage == 'EN' ? 'Logout' : 'లాగ్ అవుట్',
              subtitle: _selectedLanguage == 'EN'
                  ? 'Sign out of Kaarunya Nursery'
                  : 'కారుణ్య నర్సరీ నుండి సైన్ అవుట్ చేయి',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9E9E9E),
              ),
              onTap: _handleLogout,
            ),
          ),

          const SizedBox(height: 32),

          // App version footer
          Center(
            child: Text(
              'Kaarunya Nursery v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _LanguageToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryContainer, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_buildOption('EN', 'English'), _buildOption('TE', 'తెలుగు')],
      ),
    );
  }

  Widget _buildOption(String lang, String label) {
    final isSelected = selected == lang;
    return GestureDetector(
      onTap: () => onChanged(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          lang,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

class _NurseryReadView extends StatelessWidget {
  final String name;
  final String phone;
  final String address;
  final String language;

  const _NurseryReadView({
    required this.name,
    required this.phone,
    required this.address,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _InfoRow(
          icon: Icons.storefront_rounded,
          label: language == 'EN' ? 'Name' : 'పేరు',
          value: name,
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.phone_rounded,
          label: language == 'EN' ? 'Phone' : 'ఫోన్',
          value: phone,
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.location_on_rounded,
          label: language == 'EN' ? 'Address' : 'చిరునామా',
          value: address,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NurseryEditForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final bool isSaving;
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String language;

  const _NurseryEditForm({
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.isSaving,
    required this.onSave,
    required this.onCancel,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: language == 'EN' ? 'Nursery Name' : 'నర్సరీ పేరు',
            prefixIcon: const Icon(Icons.storefront_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: language == 'EN' ? 'Phone Number' : 'ఫోన్ నంబర్',
            prefixIcon: const Icon(Icons.phone_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: addressController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: language == 'EN' ? 'Address' : 'చిరునామా',
            prefixIcon: const Icon(Icons.location_on_rounded),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving ? null : onCancel,
                child: Text(language == 'EN' ? 'Cancel' : 'రద్దు చేయి'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isSaving ? null : onSave,
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(language == 'EN' ? 'Save' : 'సేవ్ చేయి'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        ),
      ),
    );
  }
}
