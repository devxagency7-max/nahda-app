import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class UserAvatar extends StatelessWidget {
  final double radius;
  final String? avatarUrl;
  final String name;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    this.radius = 28,
    this.avatarUrl,
    required this.name,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarChild;

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      avatarChild = CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(avatarUrl!),
      );
    } else {
      avatarChild = CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        child: Text(
          name.isEmpty ? 'م' : name.substring(0, 1),
          style: TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: avatarChild,
      );
    }

    return avatarChild;
  }
}
