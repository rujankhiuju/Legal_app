import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class PillButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? disabledColor;
  final double height;
  final double? width;
  final double fontSize;
  final bool loading;

  const PillButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
    this.disabledColor,
    this.height = 52,
    this.width,
    this.fontSize = 15,
    this.loading = false,
  });

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
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
    final enabled = widget.onTap != null && !widget.loading;

    final bg = widget.backgroundColor ??
        (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);
    final fg = widget.foregroundColor ??
        (isDark ? AppColors.darkBackground : AppColors.white);
    final disabledBg = widget.disabledColor ??
        (isDark ? AppColors.darkDivider : AppColors.lightDivider);

    return GestureDetector(
      onTapDown: enabled ? (_) {
        setState(() => _pressed = true);
        _controller.forward();
      } : null,
      onTapUp: enabled ? (_) {
        setState(() => _pressed = false);
        _controller.reverse();
        widget.onTap?.call();
      } : null,
      onTapCancel: enabled ? () {
        setState(() => _pressed = false);
        _controller.reverse();
      } : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: enabled ? bg : disabledBg,
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: bg.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: fg,
                    ),
                  )
                : Row(
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
                          color: enabled ? fg : fg.withOpacity(0.5),
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}
