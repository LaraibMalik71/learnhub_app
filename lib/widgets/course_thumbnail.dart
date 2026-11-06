import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class CourseThumbnail extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final double borderRadius;

  const CourseThumbnail({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imagePath.isNotEmpty
          ? Image.asset(
              imagePath,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _placeholder();
              },
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.primary.withValues(alpha: 0.12),
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: AppColors.primary,
          size: 35,
        ),
      ),
    );
  }
}
