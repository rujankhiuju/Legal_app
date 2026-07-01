import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PolishedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;

  const PolishedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.backgroundColor,
    this.onTap,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ??
        (isDark ? AppColors.darkCard : AppColors.lightCard);

    final defaultShadows = [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];

    return Container(
      margin: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: shadows ?? defaultShadows,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
