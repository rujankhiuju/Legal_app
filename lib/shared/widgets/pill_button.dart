import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class PillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;
  final double? width;
  final double fontSize;

  const PillButton({
    super.key,
    required this.label,
    this.icon,
    required this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.height = 52,
    this.width,
    this.fontSize = 15,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scale = Tween<double>(begin: 1, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = widget.backgroundColor ??
        (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);
    final fg = widget.foregroundColor ??
        (isDark ? AppColors.darkBackground : AppColors.white);

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedScaleBuilder(
        scale: _scale,
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: [
              BoxShadow(
                color: bg.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: fg,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedScaleBuilder extends AnimatedWidget {
  final Widget child;

  const AnimatedScaleBuilder({
    super.key,
    required super.listenable,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Transform.scale(
      scale: 1 - animation.value,
      child: child,
    );
  }
}
