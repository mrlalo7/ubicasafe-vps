import 'package:flutter/material.dart';
import 'package:ubicasafe/core/app_theme.dart';

/// Botón personalizado base — ahora con animación de escala
/// Compatible con código legacy que lo usa en login.dart original
class CustomButton extends StatefulWidget {
  final String text;
  final Color color;
  final Color textColor;
  final bool iconVisible;
  final Widget? icon;
  final VoidCallback? onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.color,
    required this.textColor,
    required this.iconVisible,
    this.icon,
    this.onPressed,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.94,
      upperBound: 1.0,
    )..value = 1.0;
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) {
        _ctrl.forward();
        widget.onPressed?.call();
      },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 54,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.iconVisible && widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 10),
              ],
              Text(
                widget.text.trim(),
                style: AppTextStyles.button.copyWith(color: widget.textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
