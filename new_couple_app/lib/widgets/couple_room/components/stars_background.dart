import 'dart:math';
import 'package:flutter/material.dart';

class Star {
  late double x;
  late double y;
  late double radius;
  late double opacity;
  late double twinkleSpeed;
  late double pulsation;

  Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.opacity,
    required this.twinkleSpeed,
    required this.pulsation,
  });
}

class StarsBackground extends StatefulWidget {
  final double starDensity;
  final bool allStarsTwinkle;
  final double twinkleProbability;
  final double minTwinkleSpeed;
  final double maxTwinkleSpeed;

  const StarsBackground({
    Key? key,
    this.starDensity = 0.00015,
    this.allStarsTwinkle = true,
    this.twinkleProbability = 0.7,
    this.minTwinkleSpeed = 0.5,
    this.maxTwinkleSpeed = 1.0,
  }) : super(key: key);

  @override
  State<StarsBackground> createState() => _StarsBackgroundState();
}

class _StarsBackgroundState extends State<StarsBackground> with SingleTickerProviderStateMixin {
  List<Star> stars = [];
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          // Update star opacity for twinkling effect
          for (var star in stars) {
            if (star.twinkleSpeed > 0) {
              star.opacity = 0.5 + (sin((_controller.value * 10 * star.twinkleSpeed)) * 0.5).abs();
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Star> _generateStars(Size size) {
    final width = size.width;
    final height = size.height;
    final area = width * height;
    final numStars = (area * widget.starDensity).floor();
    
    return List.generate(numStars, (_) {
      final shouldTwinkle = widget.allStarsTwinkle || _random.nextDouble() < widget.twinkleProbability;
      
      return Star(
        x: _random.nextDouble() * width,
        y: _random.nextDouble() * height,
        radius: _random.nextDouble() * 1.5 + 0.5, // Star size between 0.5 and 2.0
        opacity: _random.nextDouble() * 0.5 + 0.5, // Opacity between 0.5 and 1.0
        twinkleSpeed: shouldTwinkle
            ? widget.minTwinkleSpeed + _random.nextDouble() * (widget.maxTwinkleSpeed - widget.minTwinkleSpeed)
            : 0,
        pulsation: _random.nextDouble() * 2 * pi, // Random initial phase
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        // Generate stars if the list is empty or if the size changed significantly
        if (stars.isEmpty) {
          stars = _generateStars(size);
        }
        
        return CustomPaint(
          size: size,
          painter: StarsPainter(stars: stars),
        );
      },
    );
  }
}

class StarsPainter extends CustomPainter {
  final List<Star> stars;

  StarsPainter({required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    for (var star in stars) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(star.opacity)
        ..style = PaintingStyle.fill;
        
      // Draw the star with a slight glow effect
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(star.opacity * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        
      canvas.drawCircle(Offset(star.x, star.y), star.radius * 1.5, glowPaint);
      canvas.drawCircle(Offset(star.x, star.y), star.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldPainter) => true;
}
