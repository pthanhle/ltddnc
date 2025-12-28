import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/ui/widgets/glass_container.dart';
import 'package:flutter_1/ui/widgets/details/wind_detail_screen.dart'; // To navigate to detail

class WindCard extends StatelessWidget {
  final WeatherData weatherData;
  final double latitude;
  final double longitude;

  const WindCard({
    super.key,
    required this.weatherData,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    // Navigate to detail screen on tap
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => WindDetailScreen(weatherData: weatherData, latitude: latitude, longitude: longitude)));
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Icon(CupertinoIcons.wind, color: Colors.white54, size: 16), // Slightly larger icon
                const SizedBox(width: 8),
                Text("GIÓ", style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Content
            Row(
              children: [
                // Left Column: Stats
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow("Gió", "${weatherData.current.windSpeed10m}", "km/h"),
                      const Divider(color: Colors.white24, height: 24),
                      _buildRow("Gió giật", "${weatherData.current.windGusts10m}", "km/h"),
                      const Divider(color: Colors.white24, height: 24),
                      _buildDirectionRow("Hướng", "${weatherData.current.windDirection10m}° ${_getDirection(weatherData.current.windDirection10m)}"),
                    ],
                  ),
                ),
                
                // Right Column: Compass
                Expanded(
                  flex: 4,
                  child: Center(
                    child: SizedBox(
                      width: 130, // Adjust size as needed
                      height: 130, // Adjust size as needed
                      child: CustomPaint(
                        painter: CompassPainter(
                           direction: weatherData.current.windDirection10m,
                        ),
                        child: Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    Text(
                                        "${weatherData.current.windSpeed10m.toInt()}", 
                                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)
                                    ),
                                    const Text("km/h", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ]
                            )
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, String unit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        Row(
            children: [
                Text(value, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(width: 4),
                Text(unit, style: const TextStyle(color: Colors.white30, fontSize: 16)),
            ]
        )
      ],
    );
  }
  
  Widget _buildDirectionRow(String label, String value) {
      return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 16)),
      ],
    );
  }

  String _getDirection(int degrees) {
    const directions = ["B", "BĐB", "ĐB", "ĐĐB", "Đ", "ĐĐN", "ĐN", "NĐN", "N", "NTN", "TN", "TTN", "T", "TTB", "TB", "BTB"];
    int index = ((degrees + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }
}

class CompassPainter extends CustomPainter {
  final int direction;

  CompassPainter({required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    
    // Draw Ticks
    final paintTick = Paint()
      ..color = Colors.white24
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
      
    final paintMajorTick = Paint()
      ..color = Colors.white54
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 360; i += 6) { // 60 ticks
         bool isMajor = i % 90 == 0;
         double tickLen = isMajor ? 10 : 6;
         double angle = (i - 90) * pi / 180;
         
         double x1 = center.dx + (radius - tickLen) * cos(angle);
         double y1 = center.dy + (radius - tickLen) * sin(angle);
         double x2 = center.dx + radius * cos(angle);
         double y2 = center.dy + radius * sin(angle);
         
         if (isMajor) continue; // Skip major spots to draw labels instead? No, labels are inside or outside?
         // In iOS, labels N, S, W, E replace the ticks or are near them.
         // Let's draw ticks everywhere except where labels are.
         // Actually in the image, ticks go all around. Labels are INSIDE the ticks ring.
         
         canvas.drawLine(Offset(x1, y1), Offset(x2, y2), isMajor ? paintMajorTick : paintTick);
    }
    
    // Draw Labels (B, Đ, N, T)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final labels = {"B": -90, "Đ": 0, "N": 90, "T": 180}; // B (North), D (East), N (South), T (West) - Standard Compass 
    // Wait, -90 is Top (North). 0 is East. 90 is South. 180 is West.
    
    labels.forEach((label, angleDeg) {
         // Draw label slightly inside
         double angle = (angleDeg) * pi / 180;
         // Adjust position
         double dist = radius - 18; // Padding
         double x = center.dx + dist * cos(angle);
         double y = center.dy + dist * sin(angle);
         
         textPainter.text = TextSpan(text: label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold));
         textPainter.layout();
         textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    });
    
    // Draw Main Direction Arrow
    // Arrow points FROM center TO direction? Or indicates flow? Usually indicates where wind comes FROM?
    // In weather apps, arrow points in the direction wind is blowing TO or FROM?
    // "203° NTN" -> South West. Arrow in image points up-right (North East).
    // Wait. 203° is SSW (Nam Tay Nam).
    // If the image shows 203° and the arrow points to ~30° (NE), it means wind is blowing FROM SSW towards NNE?
    // Standard meteorology: Wind Direction is where it comes FROM.
    // The arrow usually points in the direction of the wind flow (Stream). 
    // So if it comes from 203, it flows to 203 + 180 = 23.
    // Let's assume arrow points "TO" destination.
    // 203° comes from SSW. So arrow should point NNE.
    
    double windAngle = (direction - 90 + 180) * pi / 180; // Points to opposite
    // Wait, let's Stick to standard: Arrow points rotated by `direction`.
    // If we want it to point like a Compass needle showing "North is North", that's different.
    // But here, the compass is fixed (North is Up). The arrow shows wind direction.
    // If wind is FROM 203 (SW), it blows TO NE.
    // Arrow should point NE.
    // So angle = direction - 90 + 180.
    
    // DRAW ARROW
    // Arrow head at edge of circle? Or just a needle?
    // Image shows a white arrow with a circle tail at the edge?
    // Actually, look closely at the uploaded image.
    // Center is "2 km/h".
    // There is a small white circle on the ring at approx 200°?
    // And a white Arrow head at approx 20°?
    // This looks like an axis passing through.
    // Small circle (tail) at Source. Arrow (head) at Destination.
    // So wind comes from Dot, goes to Arrow.
    
    double arrowAngle = (direction - 90 + 180) * pi / 180; // Destination
    double tailAngle = (direction - 90) * pi / 180; // Source
    
    // Draw Dot at Source
    double dotR = radius - 5; // On the ring
    double dotX = center.dx + dotR * cos(tailAngle);
    double dotY = center.dy + dotR * sin(tailAngle);
    
    canvas.drawCircle(Offset(dotX, dotY), 4, Paint()..color = Colors.white);
    
    // Draw Arrow at Destination
    double arrowR = radius - 10;
    double arrowX = center.dx + arrowR * cos(arrowAngle);
    double arrowY = center.dy + arrowR * sin(arrowAngle);
    
    // Draw arrow path
    canvas.save();
    canvas.translate(arrowX, arrowY);
    canvas.rotate(arrowAngle + pi/2); // Align with radial line
    
    Path arrowPath = Path();
    arrowPath.moveTo(0, -6);
    arrowPath.lineTo(-5, 4);
    arrowPath.lineTo(5, 4);
    arrowPath.close();
    
    canvas.drawPath(arrowPath, Paint()..color = Colors.white);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
