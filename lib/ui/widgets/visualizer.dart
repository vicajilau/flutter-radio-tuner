import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class Visualizer extends StatefulWidget {
  final bool isPlaying;
  final double height;
  final double width;

  const Visualizer({
    super.key,
    required this.isPlaying,
    this.height = 120.0,
    this.width = double.infinity,
  });

  @override
  State<Visualizer> createState() => _VisualizerState();
}

class _VisualizerState extends State<Visualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant Visualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
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
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, widget.height),
          painter: WaveformPainter(
            animationValue: _controller.value,
            isPlaying: widget.isPlaying,
          ),
        );
      },
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double animationValue;
  final bool isPlaying;

  WaveformPainter({required this.animationValue, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double width = size.width;

    // Draw background subtle glow
    final Paint glowPaint = Paint()
      ..color = AppTheme.primaryStart.withValues(alpha: 0.02)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), glowPaint);

    // If not playing, draw a simple straight line with tiny noise
    if (!isPlaying) {
      final Paint flatPaint = Paint()
        ..color = AppTheme.primaryStart.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final Path path = Path();
      path.moveTo(0, midY);
      for (double x = 0; x <= width; x += 5) {
        final double y = midY + 1.5 * math.sin(x * 0.05);
        path.lineTo(x, y);
      }
      canvas.drawPath(path, flatPaint);
      return;
    }

    // Parameters for 3 overlapping waves
    final waves = [
      _WaveParam(
        amplitude: size.height * 0.28,
        frequency: 0.025,
        phaseShift: animationValue * 2 * math.pi * 2,
        color: AppTheme.primaryStart.withValues(alpha: 0.7),
        strokeWidth: 2.5,
      ),
      _WaveParam(
        amplitude: size.height * 0.20,
        frequency: 0.038,
        phaseShift: -animationValue * 2 * math.pi * 1.5 + 1.0,
        color: AppTheme.primaryEnd.withValues(alpha: 0.5),
        strokeWidth: 2.0,
      ),
      _WaveParam(
        amplitude: size.height * 0.15,
        frequency: 0.052,
        phaseShift: animationValue * 2 * math.pi * 1.0 + 2.5,
        color: AppTheme.secondary.withValues(alpha: 0.4),
        strokeWidth: 1.5,
      ),
    ];

    for (var wave in waves) {
      final Paint paint = Paint()
        ..color = wave.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = wave.strokeWidth
        ..strokeCap = StrokeCap.round;

      final Path path = Path();

      // Start path
      path.moveTo(0, midY);

      // Draw sine wave across width
      for (double x = 0; x <= width; x += 2) {
        // Fade out amplitude at the edges for a clean look
        final double edgeFade = math.sin((x / width) * math.pi);

        final double y =
            midY +
            wave.amplitude *
                math.sin(x * wave.frequency + wave.phaseShift) *
                edgeFade;

        path.lineTo(x, y);
      }

      // Draw glowing shadow under the wave
      if (wave.strokeWidth > 2.0) {
        final Paint shadowPaint = Paint()
          ..color = wave.color.withValues(alpha: 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = wave.strokeWidth * 4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(path, shadowPaint);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.isPlaying != isPlaying;
  }
}

class _WaveParam {
  final double amplitude;
  final double frequency;
  final double phaseShift;
  final Color color;
  final double strokeWidth;

  _WaveParam({
    required this.amplitude,
    required this.frequency,
    required this.phaseShift,
    required this.color,
    required this.strokeWidth,
  });
}
