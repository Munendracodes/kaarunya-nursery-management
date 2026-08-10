import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

// Anatomy locked: 2-column equal cards row
// Left card: label + big colored value + bar chart + delta text
// Right card: label + radial gauge + big value + delta text

class InsightMetricRowWidget extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final Color leftValueColor;
  final String leftDelta;
  final bool leftDeltaPositive;
  final String rightLabel;
  final int rightScore;
  final String rightDelta;
  final bool rightDeltaPositive;

  const InsightMetricRowWidget({
    required this.leftLabel,
    required this.leftValue,
    required this.leftValueColor,
    required this.leftDelta,
    required this.leftDeltaPositive,
    required this.rightLabel,
    required this.rightScore,
    required this.rightDelta,
    required this.rightDeltaPositive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LeftMetricCard(
            label: leftLabel,
            value: leftValue,
            valueColor: leftValueColor,
            delta: leftDelta,
            deltaPositive: leftDeltaPositive,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RightGaugeCard(
            label: rightLabel,
            score: rightScore,
            delta: rightDelta,
            deltaPositive: rightDeltaPositive,
          ),
        ),
      ],
    );
  }
}

class _LeftMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final String delta;
  final bool deltaPositive;

  const _LeftMetricCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.delta,
    required this.deltaPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Mini bar chart data
    final barData = [0.6, 0.8, 0.5, 0.9, 0.7, 0.85, 1.0];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          // Mini bar chart
          SizedBox(
            height: 36,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: barData.map((v) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Container(
                      height: 36 * v,
                      decoration: BoxDecoration(
                        color: valueColor.withOpacity(0.3 + v * 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                deltaPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 12,
                color: deltaPositive ? AppTheme.success : AppTheme.error,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  delta,
                  style: TextStyle(
                    fontSize: 11,
                    color: deltaPositive ? AppTheme.success : AppTheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RightGaugeCard extends StatelessWidget {
  final String label;
  final int score;
  final String delta;
  final bool deltaPositive;

  const _RightGaugeCard({
    required this.label,
    required this.score,
    required this.delta,
    required this.deltaPositive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          // Mini radial gauge
          Center(
            child: CustomPaint(
              size: const Size(80, 50),
              painter: _MiniGaugePainter(
                progress: score / 100,
                color: AppTheme.primary,
              ),
            ),
          ),
          Center(
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                deltaPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 12,
                color: deltaPositive ? AppTheme.success : AppTheme.error,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  delta,
                  style: TextStyle(
                    fontSize: 11,
                    color: deltaPositive ? AppTheme.success : AppTheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _MiniGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.9);
    final radius = size.width * 0.4;

    final bgPaint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_MiniGaugePainter old) =>
      old.progress != progress || old.color != color;
}
