import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/user_auth_service.dart';
import '../../../theme/app_theme.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({
    super.key,
  });

  @override
  State<CreateUserScreen> createState() =>
      _CreateUserScreenState();
}

class _CreateUserScreenState
    extends State<CreateUserScreen> {
  final _formKey =
  GlobalKey<FormState>();

  final _mobileController =
  TextEditingController();

  final _nameController =
  TextEditingController();

  final _emailController =
  TextEditingController();

  final _nurseryController =
  TextEditingController();

  final _addressController =
  TextEditingController();

  final _pinController =
  TextEditingController();

  bool _obscurePin = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _nurseryController.dispose();
    _addressController.dispose();
    _pinController.dispose();

    super.dispose();
  }

  // ============================================================
  // CREATE USER
  // ============================================================

  Future<void> _createUser() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await UserAuthService.instance.createUser(
        mobileNumber:
        _mobileController.text,
        name:
        _nameController.text,
        email:
        _emailController.text,
        nurseryName:
        _nurseryController.text,
        address:
        _addressController.text,
        password:
        _pinController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'User created successfully.',
          ),
          behavior:
          SnackBarBehavior.floating,
        ),
      );

      context.pop();
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
          _isSaving = false;
        });
      }
    }
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
      String message,
      ) {
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
  // INPUT DECORATION
  // ============================================================

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
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
      border:
      OutlineInputBorder(
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
  // HEADER CARD
  // ============================================================

  Widget _buildHeaderCard(
      BuildContext context,
      ) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.primaryLight,
          ],
        ),
        borderRadius:
        BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary
                .withAlpha(55),
            blurRadius: 22,
            offset:
            const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -30,
            top: -35,
            child: Container(
              width: 120,
              height: 120,
              decoration:
              BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
                    .withAlpha(18),
              ),
            ),
          ),

          // Decorative circle
          Positioned(
            right: 30,
            bottom: -55,
            child: Container(
              width: 100,
              height: 100,
              decoration:
              BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
                    .withAlpha(14),
              ),
            ),
          ),

          Row(
            crossAxisAlignment:
            CrossAxisAlignment.center,
            children: [
              // Logo container
              Container(
                width: 62,
                height: 62,
                decoration:
                BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    19,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withAlpha(30),
                      blurRadius: 12,
                      offset:
                      const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons
                      .person_add_alt_1_rounded,
                  color:
                  AppTheme.primary,
                  size: 31,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              // Header text
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New User',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        color:
                        Colors.white,
                        fontWeight:
                        FontWeight.w800,
                        fontSize: 21,
                        letterSpacing:
                        -0.3,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      'Set up a new nursery account',
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                        color: Colors.white
                            .withAlpha(220),
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      AppTheme.backgroundLight,

      appBar: AppBar(
        title: const Text(
          'Create User',
        ),
        backgroundColor:
        AppTheme.backgroundLight,
        foregroundColor:
        AppTheme.primary,
        elevation: 0,
        centerTitle: false,
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 520,
            ),
            child:
            SingleChildScrollView(
              padding:
              const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                30,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,
                  children: [
                    // ==================================================
                    // RICH HEADER CARD
                    // ==================================================

                    _buildHeaderCard(
                      context,
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // ==================================================
                    // MOBILE
                    // ==================================================

                    TextFormField(
                      controller:
                      _mobileController,
                      keyboardType:
                      TextInputType.phone,
                      maxLength: 10,
                      decoration:
                      _decoration(
                        label:
                        'Mobile Number',
                        icon:
                        Icons.phone_outlined,
                      ).copyWith(
                        counterText: '',
                      ),
                      validator:
                          (value) {
                        final mobile =
                            value?.trim() ??
                                '';

                        if (mobile.isEmpty) {
                          return 'Enter mobile number';
                        }

                        if (mobile.length !=
                            10 ||
                            int.tryParse(
                              mobile,
                            ) ==
                                null) {
                          return 'Enter valid 10 digit mobile number';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // NAME
                    // ==================================================

                    TextFormField(
                      controller:
                      _nameController,
                      textCapitalization:
                      TextCapitalization
                          .words,
                      decoration:
                      _decoration(
                        label: 'Name',
                        icon:
                        Icons.person_outline,
                      ),
                      validator:
                          (value) {
                        if (value == null ||
                            value.trim()
                                .isEmpty) {
                          return 'Enter name';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // EMAIL
                    // ==================================================

                    TextFormField(
                      controller:
                      _emailController,
                      keyboardType:
                      TextInputType
                          .emailAddress,
                      decoration:
                      _decoration(
                        label:
                        'Email ID',
                        icon:
                        Icons.email_outlined,
                      ),
                      validator:
                          (value) {
                        final email =
                            value?.trim() ??
                                '';

                        if (email.isEmpty) {
                          return 'Enter email ID';
                        }

                        if (!RegExp(
                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                        ).hasMatch(
                          email,
                        )) {
                          return 'Enter valid email ID';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // NURSERY NAME
                    // ==================================================

                    TextFormField(
                      controller:
                      _nurseryController,
                      textCapitalization:
                      TextCapitalization
                          .words,
                      decoration:
                      _decoration(
                        label:
                        'Nursery Name',
                        icon: Icons
                            .local_florist_outlined,
                      ),
                      validator:
                          (value) {
                        if (value == null ||
                            value.trim()
                                .isEmpty) {
                          return 'Enter nursery name';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // ADDRESS
                    // ==================================================

                    TextFormField(
                      controller:
                      _addressController,
                      textCapitalization:
                      TextCapitalization
                          .sentences,
                      maxLines: 3,
                      decoration:
                      _decoration(
                        label:
                        'Address',
                        icon: Icons
                            .location_on_outlined,
                      ),
                      validator:
                          (value) {
                        if (value == null ||
                            value.trim()
                                .isEmpty) {
                          return 'Enter address';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // PIN
                    // ==================================================

                    TextFormField(
                      controller:
                      _pinController,
                      obscureText:
                      _obscurePin,
                      keyboardType:
                      TextInputType.number,
                      maxLength: 6,
                      decoration:
                      _decoration(
                        label:
                        '6 Digit PIN',
                        icon:
                        Icons.lock_outline,
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
                      validator:
                          (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return 'Enter 6 digit PIN';
                        }

                        if (value.length !=
                            6) {
                          return 'PIN must contain exactly 6 digits';
                        }

                        if (int.tryParse(
                          value,
                        ) ==
                            null) {
                          return 'PIN must contain only digits';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // ==================================================
                    // CREATE BUTTON
                    // ==================================================

                    Center(
                      child: SizedBox(
                        width: 230,
                        height: 52,
                        child:
                        ElevatedButton(
                          onPressed:
                          _isSaving
                              ? null
                              : _createUser,
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
                                15,
                              ),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                            width: 23,
                            height: 23,
                            child:
                            CircularProgressIndicator(
                              strokeWidth:
                              2,
                              color:
                              Colors.white,
                            ),
                          )
                              : Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                            children: const [
                              Icon(
                                Icons
                                    .person_add_alt_1_rounded,
                                size: 20,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Create User',
                                style:
                                TextStyle(
                                  fontSize:
                                  16,
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
                      height: 12,
                    ),

                    // ==================================================
                    // SECURITY NOTE
                    // ==================================================

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}