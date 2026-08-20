import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routes/app_routes.dart';
import '../../../services/user_auth_service.dart';
import '../../../theme/app_theme.dart';

class LoginFormWidget extends StatefulWidget {
  final String language;
  final VoidCallback onSuccess;
  final bool isTablet;

  const LoginFormWidget({
    super.key,
    required this.language,
    required this.onSuccess,
    this.isTablet = false,
  });

  @override
  State<LoginFormWidget> createState() =>
      _LoginFormWidgetState();
}

class _LoginFormWidgetState
    extends State<LoginFormWidget> {
  final _mobileController =
  TextEditingController();

  final _pinController =
  TextEditingController();

  bool _obscurePin = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final mobile =
    _mobileController.text.trim();

    final pin =
    _pinController.text.trim();

    if (mobile.isEmpty) {
      _showError(
        'Please enter mobile number.',
      );
      return;
    }

    if (mobile.length != 10) {
      _showError(
        'Please enter a valid 10 digit mobile number.',
      );
      return;
    }

    if (pin.isEmpty) {
      _showError(
        'Please enter your 6 digit PIN.',
      );
      return;
    }

    if (pin.length != 6) {
      _showError(
        'PIN must contain exactly 6 digits.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await UserAuthService.instance.login(
        mobileNumber: mobile,
        password: pin,
      );

      if (!mounted) return;

      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;

      _showError(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
          SnackBarBehavior.floating,
          margin:
          const EdgeInsets.all(16),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ============================================================
  // PIN CHANGE
  // ============================================================

  void _onPinChanged(String value) {
    if (value.length == 6) {
      FocusScope.of(context).unfocus();
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: AppTheme.primary,
      ),
      filled: true,
      fillColor: Colors.white,

      contentPadding:
      const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),

      border: OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: BorderSide(
          color:
          Colors.grey.shade300,
        ),
      ),

      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: BorderSide(
          color:
          Colors.grey.shade300,
        ),
      ),

      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppTheme.primary,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    // Keep the login form compact.
    final double formWidth =
    widget.isTablet
        ? 420
        : 360;

    return Center(
      child: ConstrainedBox(
        constraints:
        BoxConstraints(
          maxWidth: formWidth,
        ),
        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          child: Column(
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Text(
                'Welcome Back',
                textAlign:
                TextAlign.center,
                style: theme
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                  fontWeight:
                  FontWeight.w800,
                  color:
                  AppTheme.primary,
                  letterSpacing:
                  -0.4,
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                'Login to manage your nursery',
                textAlign:
                TextAlign.center,
                style: theme
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  color:
                  Colors.grey.shade600,
                ),
              ),

              // Slightly reduced spacing
              // so Create User remains visible.
              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // MOBILE NUMBER
              // ==================================================

              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller:
                  _mobileController,
                  keyboardType:
                  TextInputType.phone,
                  maxLength: 10,
                  textInputAction:
                  TextInputAction.next,
                  decoration:
                  _inputDecoration(
                    label:
                    'Mobile Number',
                    hint:
                    'Enter 10 digit mobile number',
                    icon:
                    Icons.phone_outlined,
                  ).copyWith(
                    counterText: '',
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // PIN
              // ==================================================

              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller:
                  _pinController,
                  obscureText:
                  _obscurePin,
                  keyboardType:
                  TextInputType.number,
                  maxLength: 6,
                  textInputAction:
                  TextInputAction.done,
                  onChanged:
                  _onPinChanged,
                  onSubmitted: (_) =>
                      _login(),
                  decoration:
                  _inputDecoration(
                    label:
                    '6 Digit PIN',
                    hint:
                    'Enter your 6 digit PIN',
                    icon:
                    Icons
                        .lock_outline_rounded,
                  ).copyWith(
                    counterText: '',
                    suffixIcon:
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePin =
                          !_obscurePin;
                        });
                      },
                      icon: Icon(
                        _obscurePin
                            ? Icons
                            .visibility_outlined
                            : Icons
                            .visibility_off_outlined,
                        color: Colors
                            .grey
                            .shade600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 5,
              ),

              // ==================================================
              // PIN INFO
              // ==================================================

              Align(
                alignment:
                Alignment.centerLeft,
                child: Padding(
                  padding:
                  const EdgeInsets
                      .only(
                    left: 4,
                  ),
                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Icon(
                        Icons
                            .info_outline_rounded,
                        size: 14,
                        color: Colors
                            .grey
                            .shade500,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Text(
                        'Enter your 6 digit PIN',
                        style: theme
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                          color: Colors
                              .grey
                              .shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ==================================================
              // LOGIN BUTTON
              // ==================================================

              Center(
                child: SizedBox(
                  width:
                  widget.isTablet
                      ? 220
                      : 180,
                  height: 48,
                  child:
                  ElevatedButton(
                    onPressed:
                    _isLoading
                        ? null
                        : _login,
                    style:
                    ElevatedButton
                        .styleFrom(
                      backgroundColor:
                      AppTheme
                          .primary,
                      foregroundColor:
                      Colors.white,
                      elevation: 2,
                      shadowColor:
                      AppTheme
                          .primary
                          .withAlpha(
                        60,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(
                          14,
                        ),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 21,
                      height: 21,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                        color: Colors
                            .white,
                      ),
                    )
                        : Row(
                      mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                      children: const [
                        Icon(
                          Icons
                              .login_rounded,
                          size: 19,
                        ),
                        SizedBox(
                          width: 7,
                        ),
                        Text(
                          'Login',
                          style:
                          TextStyle(
                            fontSize:
                            15,
                            fontWeight:
                            FontWeight
                                .w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              // ==================================================
              // CREATE USER
              // ==================================================

              TextButton.icon(
                onPressed:
                _isLoading
                    ? null
                    : () {
                  context.push(
                    AppRoutes
                        .createUserScreen,
                  );
                },
                style:
                TextButton.styleFrom(
                  foregroundColor:
                  AppTheme.primary,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                ),
                icon: const Icon(
                  Icons
                      .person_add_alt_1_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Create User',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}