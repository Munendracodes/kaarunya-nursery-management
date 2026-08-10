import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/firebase_service.dart';
import '../../../theme/app_theme.dart';
import '../../../services/firestore_repository.dart';

class LoginFormWidget extends StatefulWidget {
  final String language;
  final VoidCallback onSuccess;
  final bool isTablet;

  const LoginFormWidget({
    required this.language,
    required this.onSuccess,
    this.isTablet = false,
    super.key,
  });

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _pinController = TextEditingController();
  bool _obscurePin = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Fallback credentials (used if Firestore is unavailable)
  static const String _fallbackMobile = '9876543210';
  static const String _fallbackPin = '123456';

  @override
  void dispose() {
    _mobileController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  String _t(String en, String te) => widget.language == 'TE' ? te : en;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try to validate against Firestore auth settings
      final settings =
      await FirestoreRepository.instance.getAuthSettings();

      String validMobile = _fallbackMobile;
      String validPin = _fallbackPin;

      if (settings != null) {
        validMobile =
            settings['managerMobile'] as String? ??
                _fallbackMobile;

        validPin =
            settings['managerPin'] as String? ??
                _fallbackPin;
      }

      // ==========================================================
      // LOGIN SUCCESS
      // ==========================================================

      if (_mobileController.text.trim() == validMobile &&
          _pinController.text == validPin) {

        // Initialize the current user for
        // Firebase Realtime Database.
        FirebaseService.instance.setCurrentUser(
          _mobileController.text.trim(),
        );

        widget.onSuccess();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = _t(
            'Invalid credentials. Use registered mobile & PIN.',
            'తప్పు వివరాలు. నమోదిత మొబైల్ & పిన్ వాడండి.',
          );
        });
      }
    } catch (_) {
      // ==========================================================
      // FALLBACK LOGIN
      // ==========================================================

      if (_mobileController.text.trim() ==
          _fallbackMobile &&
          _pinController.text == _fallbackPin) {

        // Initialize the current user even when
        // Firestore is unavailable.
        FirebaseService.instance.setCurrentUser(
          _mobileController.text.trim(),
        );

        widget.onSuccess();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = _t(
            'Invalid credentials — use 9876543210 / 123456',
            'తప్పు వివరాలు — 9876543210 / 123456 వాడండి',
          );
        });
      }
    }
  }

  void _autofill() {
    _mobileController.text = _fallbackMobile;
    _pinController.text = _fallbackPin;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, widget.isTablet ? 0 : 24),
      decoration: widget.isTablet
          ? null
          : BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isTablet) ...[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text(
              _t('Welcome Back 👋', 'స్వాగతం 👋'),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _t(
                'Sign in to manage your nursery',
                'మీ నర్సరీని నిర్వహించడానికి సైన్ ఇన్ చేయండి',
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Mobile number field
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText: _t('Mobile Number', 'మొబైల్ నంబర్'),
                hintText: _t('Enter 10-digit mobile', '10 అంకెల నంబర్'),
                prefixIcon: const Icon(Icons.phone_android_rounded),
                prefixText: '+91  ',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return _t('Mobile number required', 'మొబైల్ నంబర్ అవసరం');
                }
                if (v.length < 10) {
                  return _t(
                    'Enter valid 10-digit number',
                    'చెల్లుబాటు అయ్యే నంబర్ నమోదు చేయండి',
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // PIN field
            TextFormField(
              controller: _pinController,
              obscureText: _obscurePin,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: InputDecoration(
                labelText: _t('6-digit PIN', '6 అంకెల పిన్'),
                hintText: _t('Enter your PIN', 'మీ పిన్ నమోదు చేయండి'),
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePin
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscurePin = !_obscurePin),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return _t('PIN required', 'పిన్ అవసరం');
                }
                if (v.length < 6) {
                  return _t('PIN must be 6 digits', 'పిన్ 6 అంకెలు ఉండాలి');
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Remember me row
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _t('Remember me', 'నన్ను గుర్తుంచుకో'),
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    _t('Forgot PIN?', 'పిన్ మర్చిపోయారా?'),
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: AppTheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppTheme.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Login button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _t('Sign In', 'సైన్ ఇన్'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Demo autofill
            Center(
              child: TextButton(
                onPressed: _autofill,
                child: Text(
                  _t('Use demo credentials', 'డెమో వివరాలు వాడండి'),
                  style: TextStyle(color: AppTheme.primaryLight, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
