import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Optimized animated background widget with minimal performance impact
class AnimatedGameBackground extends StatefulWidget {
  final List<String> gameIcons;
  final Color backgroundColor;
  final double opacity;

  const AnimatedGameBackground({
    Key? key,
    required this.gameIcons,
    this.backgroundColor = Colors.transparent,
    this.opacity = 0.3,
  }) : super(key: key);

  @override
  State<AnimatedGameBackground> createState() => _AnimatedGameBackgroundState();
}

class _AnimatedGameBackgroundState extends State<AnimatedGameBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    
    // Single, slow animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 60), // Much slower
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Container(
      width: screenSize.width,
      height: screenSize.height,
      color: widget.backgroundColor,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: OptimizedGameIconsPainter(
              animationProgress: _controller.value,
              opacity: widget.opacity,
              screenSize: screenSize,
            ),
          );
        },
      ),
    );
  }
}

/// Highly optimized custom painter with minimal computations
class OptimizedGameIconsPainter extends CustomPainter {
  final double animationProgress;
  final double opacity;
  final Size screenSize;

  OptimizedGameIconsPainter({
    required this.animationProgress,
    required this.opacity,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.3)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw simple geometric shapes instead of complex icons
    _drawSimpleIcons(canvas, paint, strokePaint, size);
  }

  void _drawSimpleIcons(Canvas canvas, Paint fillPaint, Paint strokePaint, Size size) {
    const columns = 4;
    const rows = 6;
    const iconSize = 40.0;
    
    final horizontalSpacing = size.width / (columns + 1);
    final verticalSpacing = size.height / (rows + 1);
    
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        final x = horizontalSpacing * (col + 1);
        final y = verticalSpacing * (row + 1);
        
        // Add subtle movement
        final offsetX = math.sin(animationProgress * 2 * math.pi + row) * 10;
        final offsetY = math.cos(animationProgress * 2 * math.pi + col) * 5;
        
        final center = Offset(x + offsetX, y + offsetY);
        
        // Draw different simple shapes
        final shapeType = (row + col) % 4;
        switch (shapeType) {
          case 0:
            // Circle (game controller button)
            canvas.drawCircle(center, iconSize * 0.3, fillPaint);
            canvas.drawCircle(center, iconSize * 0.3, strokePaint);
            break;
          case 1:
            // Square (game tile)
            final rect = Rect.fromCenter(
              center: center,
              width: iconSize * 0.6,
              height: iconSize * 0.6,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, const Radius.circular(8)),
              fillPaint,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, const Radius.circular(8)),
              strokePaint,
            );
            break;
          case 2:
            // Triangle (play button)
            final path = Path()
              ..moveTo(center.dx, center.dy - iconSize * 0.3)
              ..lineTo(center.dx - iconSize * 0.25, center.dy + iconSize * 0.15)
              ..lineTo(center.dx + iconSize * 0.25, center.dy + iconSize * 0.15)
              ..close();
            canvas.drawPath(path, fillPaint);
            canvas.drawPath(path, strokePaint);
            break;
          case 3:
            // Diamond (gem)
            final path = Path()
              ..moveTo(center.dx, center.dy - iconSize * 0.3)
              ..lineTo(center.dx + iconSize * 0.2, center.dy)
              ..lineTo(center.dx, center.dy + iconSize * 0.3)
              ..lineTo(center.dx - iconSize * 0.2, center.dy)
              ..close();
            canvas.drawPath(path, fillPaint);
            canvas.drawPath(path, strokePaint);
            break;
        }
      }
    }
  }

  @override
  bool shouldRepaint(OptimizedGameIconsPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress;
  }
} 