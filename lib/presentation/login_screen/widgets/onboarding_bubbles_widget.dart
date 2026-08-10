import 'dart:math' as math;
import 'package:flutter/material.dart';

// Anatomy locked: scattered circular icon bubbles with glassmorphism tint
// Each bubble: circle container + white icon + glassmorphism gradient tint
// Staggered scale-in entrance via AnimationController

class _BubbleData {
  final IconData icon;
  final Color color;
  final double x; // 0.0 to 1.0 relative
  final double y; // 0.0 to 1.0 relative
  final double size;

  const _BubbleData({
    required this.icon,
    required this.color,
    required this.x,
    required this.y,
    required this.size,
  });
}

class OnboardingBubblesWidget extends StatefulWidget {
  final AnimationController controller;

  const OnboardingBubblesWidget({required this.controller, super.key});

  @override
  State<OnboardingBubblesWidget> createState() =>
      _OnboardingBubblesWidgetState();
}

class _OnboardingBubblesWidgetState extends State<OnboardingBubblesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  static const List<_BubbleData> _bubbles = [
    _BubbleData(
      icon: Icons.local_florist_rounded,
      color: Color(0xFF4CAF50),
      x: 0.18,
      y: 0.12,
      size: 58,
    ),
    _BubbleData(
      icon: Icons.eco_rounded,
      color: Color(0xFF66BB6A),
      x: 0.42,
      y: 0.06,
      size: 50,
    ),
    _BubbleData(
      icon: Icons.grass_rounded,
      color: Color(0xFF81C784),
      x: 0.68,
      y: 0.14,
      size: 62,
    ),
    _BubbleData(
      icon: Icons.spa_rounded,
      color: Color(0xFF43A047),
      x: 0.08,
      y: 0.38,
      size: 54,
    ),
    _BubbleData(
      icon: Icons.yard_rounded,
      color: Color(0xFF2E7D32),
      x: 0.34,
      y: 0.32,
      size: 56,
    ),
    _BubbleData(
      icon: Icons.agriculture_rounded,
      color: Color(0xFF558B2F),
      x: 0.62,
      y: 0.36,
      size: 60,
    ),
    _BubbleData(
      icon: Icons.water_drop_rounded,
      color: Color(0xFF1976D2),
      x: 0.84,
      y: 0.30,
      size: 48,
    ),
    _BubbleData(
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFF9A825),
      x: 0.22,
      y: 0.62,
      size: 52,
    ),
    _BubbleData(
      icon: Icons.shopping_basket_rounded,
      color: Color(0xFF6D4C41),
      x: 0.50,
      y: 0.58,
      size: 58,
    ),
    _BubbleData(
      icon: Icons.delivery_dining_rounded,
      color: Color(0xFF00897B),
      x: 0.76,
      y: 0.60,
      size: 54,
    ),
    _BubbleData(
      icon: Icons.payments_rounded,
      color: Color(0xFF5C6BC0),
      x: 0.10,
      y: 0.76,
      size: 50,
    ),
    _BubbleData(
      icon: Icons.people_rounded,
      color: Color(0xFFE53935),
      x: 0.40,
      y: 0.80,
      size: 56,
    ),
    _BubbleData(
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF8E24AA),
      x: 0.68,
      y: 0.82,
      size: 52,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: _bubbles.asMap().entries.map((entry) {
            final index = entry.key;
            final bubble = entry.value;

            final delay = index / _bubbles.length;
            final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: widget.controller,
                curve: Interval(
                  delay * 0.6,
                  delay * 0.6 + 0.4,
                  curve: Curves.easeOutBack,
                ),
              ),
            );

            final floatOffset = math.sin(index * 0.8) * 6;

            return Positioned(
              left: bubble.x * constraints.maxWidth - bubble.size / 2,
              top: bubble.y * constraints.maxHeight - bubble.size / 2,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  widget.controller,
                  _floatController,
                ]),
                builder: (context, child) {
                  final floatY =
                      floatOffset * math.sin(_floatController.value * math.pi);
                  return Transform.translate(
                    offset: Offset(0, floatY),
                    child: Transform.scale(
                      scale: scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: _BubbleWidget(data: bubble),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _BubbleWidget extends StatelessWidget {
  final _BubbleData data;

  const _BubbleWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: data.size,
      height: data.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [data.color.withAlpha(217), data.color.withAlpha(166)],
        ),
        boxShadow: [
          BoxShadow(
            color: data.color.withAlpha(77),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(data.icon, color: Colors.white, size: data.size * 0.48),
    );
  }
}
