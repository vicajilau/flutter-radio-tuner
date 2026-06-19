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
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle ? null : borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
              color: Colors.white.withValues(alpha: opacity),
              borderRadius: shape == BoxShape.circle ? null : borderRadius,
              border:
                  border ??
                  Border.all(
                    color: Colors.white.withValues(alpha: borderOpacity),
                    width: 1.0,
                  ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
