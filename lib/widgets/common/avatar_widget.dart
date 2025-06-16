import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AvatarWidget extends StatelessWidget {
  final String initials;
  final String? photoUrl;
  final double size;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    required this.initials,
    this.photoUrl,
    this.size = 40.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: photoUrl == null ? AppColors.primaryGradient : null,
          shape: BoxShape.circle,
          image: photoUrl != null
              ? DecorationImage(
                  image: NetworkImage(photoUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: photoUrl == null
            ? Center(
                child: Text(
                  initials,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textLight,
                    fontSize: size * 0.4,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
