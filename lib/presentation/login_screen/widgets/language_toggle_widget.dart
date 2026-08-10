import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class LanguageToggleWidget extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const LanguageToggleWidget({
    required this.selected,
    required this.onChanged,
    super.key,
  });

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
        children: ['EN', 'TE'].map((lang) {
          final isSelected = selected == lang;
          return GestureDetector(
            onTap: () => onChanged(lang),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
        }).toList(),
      ),
    );
  }
}
