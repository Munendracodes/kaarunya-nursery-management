import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

// Anatomy locked: 7-day horizontal strip
// Each column: [day label] + [date number] + [avatar dots row]
// Selected day: filled background pill

class OrderCalendarStripWidget extends StatelessWidget {
  final DateTime selectedDate;
  final List<DateTime> orderDates;
  final ValueChanged<DateTime> onDateSelected;

  const OrderCalendarStripWidget({
    required this.selectedDate,
    required this.orderDates,
    required this.onDateSelected,
    super.key,
  });

  static const List<String> _dayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  // Generate 7 days centered around today
  List<DateTime> _getDays() {
    final today = DateTime.now();
    final startOfWeek = today.subtract(
      Duration(days: today.weekday - 1),
    ); // Monday
    return List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
  }

  // Get avatar URLs for orders on a given date
  List<String> _getAvatarUrlsForDate(DateTime date) {
    return orderDates
        .where(
          (d) =>
              d.year == date.year && d.month == date.month && d.day == date.day,
        )
        .take(3)
        .map(
          (_) =>
              'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg',
        )
        .toList();
  }

  bool _isSelected(DateTime date) {
    return date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = _getDays();

    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Row(
        children: days.asMap().entries.map((entry) {
          final i = entry.key;
          final day = entry.value;
          final isSelected = _isSelected(day);
          final isToday = _isToday(day);
          final avatarUrls = _getAvatarUrlsForDate(day);

          return Expanded(
            child: GestureDetector(
              onTap: () => onDateSelected(day),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Day label
                  Text(
                    _dayLabels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Date number in pill
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : isToday
                          ? AppTheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : isToday
                              ? AppTheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Avatar dots row (order indicators)
                  SizedBox(
                    height: 16,
                    child: avatarUrls.isEmpty
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: avatarUrls.take(3).map((url) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.surface,
                                    width: 1,
                                  ),
                                ),
                                child: ClipOval(
                                  child: CustomImageWidget(
                                    imageUrl: url,
                                    width: 14,
                                    height: 14,
                                    fit: BoxFit.cover,
                                    semanticLabel:
                                        'Customer avatar for order on this date',
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
