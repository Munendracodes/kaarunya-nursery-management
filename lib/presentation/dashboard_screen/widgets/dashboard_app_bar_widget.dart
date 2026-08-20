import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class DashboardAppBarWidget extends StatelessWidget {
  final VoidCallback onNotificationTap;
  final VoidCallback onAvatarTap;

  const DashboardAppBarWidget({
    required this.onNotificationTap,
    required this.onAvatarTap,
    super.key,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 2,
      shadowColor: Colors.black.withAlpha(20),
      automaticallyImplyLeading: false,
      toolbarHeight: 72,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, Munendra 🌿',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            _greeting(),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        // Notification bell
        Stack(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantLight,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onNotificationTap,
                icon: CustomIconWidget(
                  iconName: 'notifications_outlined',
                  color: theme.colorScheme.onSurface,
                  size: 22,
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        // Avatar
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primaryContainer, width: 2),
            ),
            child: ClipOval(
              child: CustomImageWidget(
                imageUrl:
                    'https://images.pexels.com/photos/1222271/pexels-photo-1222271.jpeg',
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                semanticLabel:
                    'Nursery manager profile photo, Indian man in casual attire',
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}
