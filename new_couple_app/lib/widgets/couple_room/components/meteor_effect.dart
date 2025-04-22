import 'dart:math';
import 'package:flutter/material.dart';

class Meteor {
  final double startX;
  final double startY;
  final double length;
  final double angle;
  final double speed;
  final double? animationStart; // Value between 0 and 1 to stagger animation
  final double width;
  
  Meteor({
    required this.startX,
    required this.startY,
    required this.length,
    required this.angle,
    required this.speed,
    this.animationStart,
    required this.width,
  });
}

class MeteorEffect extends StatefulWidget {
  final int number;
  final Color color;
  
  const MeteorEffect({
    Key? key,
    this.number = 20,
    this.color = Colors.white,
  }) : super(key: key);

  @override
  State<MeteorEffect> createState() => _MeteorEffectState();
}

class _MeteorEffectState extends State<MeteorEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Meteor> _meteors;
  final Random _random = Random();
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _meteors = [];
    _controller.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  List<Meteor> _generateMeteors(Size size) {
    return List.generate(widget.number, (_) {
      // Generate meteor start positions off-screen to the top/sides
      double startX = _random.nextDouble() * size.width * 1.5 - size.width * 0.25;
      double startY = -_random.nextDouble() * size.height * 0.5; // Start above the screen
      
      // Force some meteors to stay within the visible area
      if (_random.nextDouble() > 0.7) {
        startX = _random.nextDouble() * size.width;
        startY = _random.nextDouble() * size.height * 0.3; // Top 30% of screen
      }
      
      return Meteor(
        startX: startX,
        startY: startY,
        length: _random.nextDouble() * 100 + 50, // Length between 50 and 150
        angle: _random.nextDouble() * 0.5 + 0.25, // Angle in radians, around π/4 (45°)
        speed: _random.nextDouble() * 5 + 3, // Speed between 3 and 8
        animationStart: _random.nextDouble(), // Random start time for staggered animation
        width: _random.nextDouble() * 1.5 + 0.5, // Width between 0.5 and 2.0
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        if (_meteors.isEmpty) {
          _meteors = _generateMeteors(size);
        }
        
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: size,
              painter: MeteorPainter(
                meteors: _meteors,
                animationValue: _controller.value,
                color: widget.color,
              ),
            );
          },
        );
      },
    );
  }
}

class MeteorPainter extends CustomPainter {
  final List<Meteor> meteors;
  final double animationValue;
  final Color color;
  
  MeteorPainter({
    required this.meteors,
    required this.animationValue,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var meteor in meteors) {
      // Calculate animation time including the meteor's individual delay
      final startTime = meteor.animationStart ?? 0;
      double individualAnimationTime = (animationValue + startTime) % 1.0;
      
      // Calculate position based on animation
      final speedFactor = meteor.speed * individualAnimationTime;
      final x = meteor.startX + cos(meteor.angle) * speedFactor * size.width * 0.3;
      final y = meteor.startY + sin(meteor.angle) * speedFactor * size.height * 0.3;
      
      // Calculate trail end position
      final endX = x - cos(meteor.angle) * meteor.length;
      final endY = y - sin(meteor.angle) * meteor.length;
      
      // Create a gradient for the trail
      final paint = Paint()
        ..strokeWidth = meteor.width
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            color.withOpacity(0), // Transparent at the end
            color.withOpacity(0.7), // Solid at the head
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(
          Rect.fromPoints(
            Offset(endX, endY),
            Offset(x, y),
          ),
        );
      
      // Draw the meteor trail
      canvas.drawLine(
        Offset(x, y),
        Offset(endX, endY),
        paint,
      );
      
      // Draw a small glow at the head of the meteor
      final glowPaint = Paint()
        ..color = color.withOpacity(0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        
      canvas.drawCircle(Offset(x, y), meteor.width * 1.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldPainter) => true;
}
