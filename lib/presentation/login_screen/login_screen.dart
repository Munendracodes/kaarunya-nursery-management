import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../services/language_provider.dart';
import './widgets/language_toggle_widget.dart';
import './widgets/login_form_widget.dart';
import './widgets/onboarding_bubbles_widget.dart';

// TODO: Replace with Riverpod for production auth state

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _bubblesController;
  late AnimationController _formController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _formSlide;
  late Animation<double> _formOpacity;

  bool _showForm = false;

  // Language is now driven by LanguageProvider — no local state needed.
  String get _selectedLanguage => LanguageProvider.instance.language;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bubblesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));
    _formSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
    );
    _formOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeOut));

    // Staggered entrance
    _logoController.forward().then((_) {
      _bubblesController.forward().then((_) {
        setState(() => _showForm = true);
        _formController.forward();
      });
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _bubblesController.dispose();
    _formController.dispose();
    super.dispose();
  }

  void _onLanguageChanged(String lang) {
    LanguageProvider.instance.setLanguage(lang);
    // setState triggers rebuild so the toggle reflects the new selection.
    setState(() {});
  }

  void _onLoginSuccess() {
    context.go(AppRoutes.dashboardScreen);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: isTablet ? _buildTabletLayout() : _buildPhoneLayout(),
      ),
    );
  }

  Widget _buildPhoneLayout() {
    return Column(
      children: [
        // Top bar with language toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedBuilder(
                animation: _logoOpacity,
                builder: (context, child) =>
                    Opacity(opacity: _logoOpacity.value, child: _buildLogo()),
              ),
              LanguageToggleWidget(
                selected: _selectedLanguage,
                onChanged: _onLanguageChanged,
              ),
            ],
          ),
        ),

        // Bubbles hero zone
        Expanded(
          flex: _showForm ? 4 : 6,
          child: OnboardingBubblesWidget(controller: _bubblesController),
        ),

        // Form section
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          child: _showForm
              ? AnimatedBuilder(
                  animation: _formController,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _formSlide.value),
                    child: Opacity(opacity: _formOpacity.value, child: child),
                  ),
                  child: LoginFormWidget(
                    language: _selectedLanguage,
                    onSuccess: _onLoginSuccess,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Center(
      child: SizedBox(
        width: 480,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _logoScale,
              builder: (context, child) => Transform.scale(
                scale: _logoScale.value,
                child: Opacity(
                  opacity: _logoOpacity.value,
                  child: _buildLogo(size: 80),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_showForm)
              AnimatedBuilder(
                animation: _formController,
                builder: (context, child) =>
                    Opacity(opacity: _formOpacity.value, child: child),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(20),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(32),
                  child: LoginFormWidget(
                    language: _selectedLanguage,
                    onSuccess: _onLoginSuccess,
                    isTablet: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo({double size = 48}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppTheme.primaryContainer,
            borderRadius: BorderRadius.circular(size * 0.3),
          ),
          child: Icon(
            Icons.park_rounded,
            color: AppTheme.primary,
            size: size * 0.6,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kaarunya',
              style: TextStyle(
                fontSize: size * 0.35,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Nursery',
              style: TextStyle(
                fontSize: size * 0.25,
                fontWeight: FontWeight.w400,
                color: AppTheme.primaryLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
