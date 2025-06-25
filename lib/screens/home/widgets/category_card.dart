import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../models/category_model.dart';

class SimplifiedCategoryCard extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const SimplifiedCategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  State<SimplifiedCategoryCard> createState() => _SimplifiedCategoryCardState();
}

class _SimplifiedCategoryCardState extends State<SimplifiedCategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(
            color: _isPressed ? widget.category.color : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _isPressed
                  ? widget.category.color.withOpacity(0.2)
                  : AppColors.shadow.withOpacity(0.05),
              blurRadius: _isPressed ? 15 : 10,
              offset: Offset(0, _isPressed ? 6 : 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.category.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
                child: Icon(
                  widget.category.icon,
                  size: 28,
                  color: widget.category.color,
                ),
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                widget.category.name,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimensions.paddingXXS),
              Text(
                '${widget.category.quizCount} quizzes',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
