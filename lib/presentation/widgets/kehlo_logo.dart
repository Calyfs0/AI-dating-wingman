import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Kehlo wordmark — neon cursive script (no image plate).
class KehloLogo extends StatelessWidget {
  const KehloLogo({
    super.key,
    this.fontSize = 56,
    this.showHeart = true,
  });

  final double fontSize;
  final bool showHeart;

  @override
  Widget build(BuildContext context) {
    final heartSize = (fontSize * 0.28).clamp(12.0, 20.0);
    final heartTop = fontSize * 0.28;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kehlo',
          style: AppTypography.brandScript.copyWith(fontSize: fontSize),
        ),
        if (showHeart) ...[
          SizedBox(width: fontSize * 0.08),
          Padding(
            padding: EdgeInsets.only(top: heartTop),
            child: Icon(
              Icons.favorite_rounded,
              size: heartSize,
              color: AppColors.neonPink.withValues(alpha: 0.95),
            ),
          ),
        ],
      ],
    );
  }
}
