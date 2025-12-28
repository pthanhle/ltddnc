import 'dart:math';
import 'package:flutter/material.dart';

// --- VISUAL PAINTERS FOR GRID ---

class UVMeterWidget extends StatelessWidget {
  final double uvIndex;
  const UVMeterWidget({super.key, required this.uvIndex});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
       width: double.infinity,
       height: 12,
       child: CustomPaint(
        painter: UVPainter(uvIndex),
      ),
    );
  }
}

class UVPainter extends CustomPainter {
  final double uvIndex;
  UVPainter(this.uvIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final barRect = Rect.fromLTWH(0, size.height/2 - 2, size.width, 4);
    
    // iOS UV Bar Gradient
    paint.shader = const LinearGradient(
      colors: [Colors.green, Colors.yellow, Colors.orange, Colors.red, Colors.purple],
      stops: [0.0, 0.3, 0.6, 0.8, 1.0]
    ).createShader(barRect);
    
    canvas.drawRRect(RRect.fromRectAndRadius(barRect, const Radius.circular(2)), paint);
    
    // Dot indicator
    final maxUV = 12.0;
    final normalized = (uvIndex / maxUV).clamp(0.0, 1.0);
    final dotX = normalized * size.width;
    
    final dotPaint = Paint()..color = Colors.white;
    // White circle with shadow
    canvas.drawCircle(Offset(dotX, size.height/2), 5, dotPaint);
    canvas.drawCircle(Offset(dotX, size.height/2), 5, Paint()..color = Colors.black.withOpacity(0.3) ..style = PaintingStyle.stroke ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WindCompassWidget extends StatelessWidget {
  final int directionDegree;
  final double speed;
  const WindCompassWidget({super.key, required this.directionDegree, required this.speed});

  @override
  Widget build(BuildContext context) {
    // Reduced size slightly to fit better in dense grids
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
            CustomPaint(
              size: const Size(60, 60),
              painter: CompassPainter(directionDegree),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("${speed.round()}", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                const Text("km/h", style: TextStyle(color: Colors.white60, fontSize: 9)),
              ],
            )
        ],
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  final int degree;
  CompassPainter(this.degree);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    final paint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw main circle
    canvas.drawCircle(center, radius, paint);
    
    // Draw ticks
    final tickPaint = Paint()..color = Colors.white24 ..strokeWidth = 1;
    for(int i=0; i<360; i+=30) {
       // Only major ticks
       if (i % 90 == 0) continue; // Skip NESW positions
       double rad = i * pi / 180;
       Offset p1 = Offset(center.dx + (radius-4) * cos(rad), center.dy + (radius-4) * sin(rad));
       Offset p2 = Offset(center.dx + radius * cos(rad), center.dy + radius * sin(rad));
       canvas.drawLine(p1, p2, tickPaint);
    }
    
    // Draw NESW labels
    _drawText(canvas, center, radius - 10, "B", -90); // N
    _drawText(canvas, center, radius - 10, "Đ", 0);   // E
    _drawText(canvas, center, radius - 10, "N", 90);  // S
    _drawText(canvas, center, radius - 10, "T", 180); // W
    
    // Arrow
    final arrowPaint = Paint()..color = Colors.white ..style = PaintingStyle.fill;
    final rad = (degree - 90) * pi / 180;
    
    // Draw exact arrow triangle logic
    final tip = Offset(center.dx + radius * 0.85 * cos(rad), center.dy + radius * 0.85 * sin(rad));
    
    canvas.drawCircle(tip, 3, arrowPaint);
    // Line to center (faded tail)
    canvas.drawLine(center, tip, Paint()..color = Colors.white ..strokeWidth = 2);
    canvas.drawCircle(center, 2, Paint()..color = Colors.white24);
  }
  
  void _drawText(Canvas canvas, Offset center, double radius, String text, double angleDeg) {
      final rad = angleDeg * pi / 180;
      final x = center.dx + radius * cos(rad);
      final y = center.dy + radius * sin(rad);
      
      final textSpan = TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width/2, y - tp.height/2));
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RainBarWidget extends StatelessWidget {
   const RainBarWidget({super.key});
   
   @override
   Widget build(BuildContext context) {
      return Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         crossAxisAlignment: CrossAxisAlignment.end,
         children: List.generate(8, (index) {
            // Mock varied heights simulating forecast
            // index 0 is now.
            final h = [4.0, 10.0, 20.0, 15.0, 10.0, 12.0, 8.0, 5.0][index % 8];
            return Container(
               width: 4,
               height: h,
               decoration: BoxDecoration(
                 color: Colors.blueAccent.withOpacity(0.9),
                 borderRadius: BorderRadius.circular(2)
               ),
            );
         }),
      );
   }
}

class PressureWidget extends StatelessWidget {
  final double pressure;
  const PressureWidget({super.key, required this.pressure});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: CustomPaint(
        painter: PressurePainter(pressure),
      ),
    );
  }
}

class PressurePainter extends CustomPainter {
  final double pressure;
  PressurePainter(this.pressure);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
      
    // Bg Arc 
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius-5), 3 * pi / 4, 3 * pi / 2, false, paint);
    
    // Active Arc (placeholder logic for range)
    // Scale 950 to 1050
    final normalized = ((pressure - 950) / 100).clamp(0.0, 1.0);
    final sweep = normalized * 3 * pi / 2;
    
    // Gradient arc logic is hard without shader on path, simple solid for now
    // Or just needle
    
    // Needle
    final angle = (3 * pi / 4) + sweep;
    final tip = Offset(center.dx + (radius - 5) * cos(angle), center.dy + (radius - 5) * sin(angle));
    
    final tickPaint = Paint()..color = Colors.white ..strokeWidth = 2 ..strokeCap = StrokeCap.round;
    // Draw tick at current value
    final startTick = Offset(center.dx + (radius - 15) * cos(angle), center.dy + (radius - 15) * sin(angle));
    canvas.drawLine(startTick, tip, tickPaint);
    
    // Center dot
    canvas.drawCircle(center, 2, Paint()..color = Colors.white24);

    // Text Labels "L" and "H"
    _drawText(canvas, center, radius - 15, "Thấp", 135);
    _drawText(canvas, center, radius - 15, "Cao", 45);
  }
  
  void _drawText(Canvas canvas, Offset center, double radius, String text, double angleDeg) {
      final rad = angleDeg * pi / 180;
      final x = center.dx + radius * cos(rad);
      final y = center.dy + radius * sin(rad);
      
      final textSpan = TextSpan(
        text: text,
        style: const TextStyle(color: Colors.white30, fontSize: 7, fontWeight: FontWeight.bold),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width/2, y - tp.height/2));
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
