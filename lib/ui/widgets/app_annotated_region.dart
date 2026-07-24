import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// A wrapper around [AnnotatedRegion<SystemUiOverlayStyle>] that automatically
/// configures system status bar transparency and icon brightness based on current theme.
class AppAnnotatedRegion extends StatelessWidget {
  final Widget child;

  const AppAnnotatedRegion({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.systemUiOverlayStyle,
      child: child,
    );
  }
}
