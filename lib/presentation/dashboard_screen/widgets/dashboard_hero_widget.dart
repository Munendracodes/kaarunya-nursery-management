import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

// Anatomy locked: full-width card, icon chip row + radial gauge + % + label
// CustomPaint radial gauge showing overall business health score

class DashboardHeroWidget extends StatefulWidget {
  final int score;
  final String label;
  final String filter;

  const DashboardHeroWidget({
    required this.score,
    required this.label,
    required this.filter,
    super.key,
  });

  @override
  State<DashboardHeroWidget> createState() => _DashboardHeroWidgetState();
}

class _DashboardHeroWidgetState extends State<DashboardHeroWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _gaugeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _gaugeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(DashboardHeroWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const List<Map<String, dynamic>> _quickMetrics = [
    {'icon': Icons.shopping_basket_rounded, 'label': 'Orders'},
    {'icon': Icons.local_shipping_rounded, 'label': 'Delivery'},
    {'icon': Icons.payments_rounded, 'label': 'Payment'},
    {'icon': Icons.bolt_rounded, 'label': 'Energy'},
    {'icon': Icons.people_rounded, 'label': 'Customers'},
    {'icon': Icons.eco_rounded, 'label': 'Plants'},
    {'icon': Icons.favorite_rounded, 'label': 'Health'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon chip row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickMetrics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  return Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantLight,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      _quickMetrics[i]['icon'] as IconData,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  );
                },
              ),
            ),
          ),

          // Gauge + score
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedBuilder(
              animation: _gaugeAnimation,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(220, 130),
                  painter: _GaugePainter(
                    progress: _gaugeAnimation.value * widget.score / 100,
                    score: (widget.score * _gaugeAnimation.value).round(),
                  ),
                );
              },
            ),
          ),

          // Label
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Text(
                  widget.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  'Overall Business Health Index',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final int score;

  _GaugePainter({required this.progress, required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width * 0.42;
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // Background arc
    final bgPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Progress arc
    final Color progressColor = progress < 0.4
        ? AppTheme.error
        : progress < 0.7
        ? AppTheme.warning
        : AppTheme.primary;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle * progress,
        colors: [progressColor.withAlpha(179), progressColor],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * progress,
      false,
      progressPaint,
    );

    // Score text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$score%',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: progressColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height - 6,
      ),
    );

    // Tick marks
    final tickPaint = Paint()
      ..color = const Color(0xFFCCCCCC)
      ..strokeWidth = 1.5;

    for (int i = 0; i <= 20; i++) {
      final angle = startAngle + (i / 20) * sweepAngle;
      final innerR = radius - 20;
      final outerR = radius - 26;
      canvas.drawLine(
        Offset(
          center.dx + innerR * math.cos(angle),
          center.dy + innerR * math.sin(angle),
        ),
        Offset(
          center.dx + outerR * math.cos(angle),
          center.dy + outerR * math.sin(angle),
        ),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.progress != progress || old.score != score;
}
