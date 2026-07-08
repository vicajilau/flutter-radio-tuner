import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable glassmorphic UI container applying backdrop blur filter effects
/// and semi-transparent borders for modern design aesthetics.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderOpacity;
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double? height;
  final Border? border;
  final BoxShape shape;

  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.opacity = 0.05,
    this.borderOpacity = 0.1,
    this.borderRadius = const BorderRadius.all(Radius.circular(24.0)),
    this.padding = const EdgeInsets.all(16.0),
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
    this.border,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Premium light/dark adaptive color schemes
    final Color dynamicCardColor = isDark
        ? Colors.white.withValues(alpha: opacity)
        : Colors.white.withValues(alpha: 0.80);

    final Color dynamicBorderColor = isDark
        ? Colors.white.withValues(alpha: borderOpacity)
        : Colors.black.withValues(alpha: 0.06);

    final Color dynamicShadowColor = isDark
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.04);

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : borderRadius,
        boxShadow: [
          BoxShadow(
            color: dynamicShadowColor,
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: shape == BoxShape.circle
            ? BorderRadius.circular(9999)
            : (borderRadius as BorderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              shape: shape,
              color: dynamicCardColor,
              borderRadius: shape == BoxShape.circle ? null : borderRadius,
              border:
                  border ?? Border.all(color: dynamicBorderColor, width: 1.0),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
