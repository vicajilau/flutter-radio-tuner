import 'package:flutter/material.dart';

/// A wrapper widget that animates its child with a subtle, continuous oscillation
/// (jiggling) simulating the iOS App Library edit mode.
class JiggleWidget extends StatefulWidget {
  final Widget child;
  final bool animate;

  const JiggleWidget({super.key, required this.child, required this.animate});

  @override
  State<JiggleWidget> createState() => _JiggleWidgetState();
}

class _JiggleWidgetState extends State<JiggleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    // Oscillation of ~0.8 degrees (0.015 radians) back and forth
    _animation = Tween<double>(
      begin: -0.015,
      end: 0.015,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _startJiggling();
    }
  }

  void _startJiggling() {
    // Introduce an organic, desynchronized start delay so that cards do not wiggle in lockstep
    final int delayMs = (widget.child.hashCode % 80);
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted && widget.animate) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant JiggleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _startJiggling();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(angle: _animation.value, child: child);
      },
      child: widget.child,
    );
  }
}
