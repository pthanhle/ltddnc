import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/utils/sun_calculator.dart';
import 'package:flutter_1/ui/widgets/details/sunrise_detail_screen.dart';

class SunriseSunsetCard extends StatelessWidget {
  final DailyWeather daily;
  final double latitude;
  final double longitude;
  final TimeOfDay? timeZoneOffset; // Optional if needed for precise utc handling

  const SunriseSunsetCard({
    super.key,
    required this.daily,
    required this.latitude,
    required this.longitude,
    this.timeZoneOffset,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Parse today's sunrise/sunset
    // Note: The API Model strings are usually ISO8601 e.g. "2023-10-27T06:05"
    // We assume daily.sunrise[0] is today (or the first requested day).
    
    DateTime? sunriseTime;
    DateTime? sunsetTime;
    
    try {
      if (daily.sunrise.isNotEmpty) sunriseTime = DateTime.parse(daily.sunrise[0]);
      if (daily.sunset.isNotEmpty) sunsetTime = DateTime.parse(daily.sunset[0]);
    } catch (e) {
      // Fallback
    }

    // Determine what to show
    // If before sunrise: Show Sunrise "06:05"
    // If day (sunrise < now < sunset): Show Sunset "17:35" (Title: Sunset) ?? 
    // Actually iPhone "Sunrise" widget acts as follows:
    // It shows the next event? Or consistently Sunrise? 
    // The user image shows "MẶT TRỜI MỌC" (Sunrise) at 06:05 (Past?) or Future?
    // If it's 22:16 (User screenshot time), showing 06:05 (Sunrise tomorrow?)
    // Note user screenshot 2 says "Mặt trời mọc ngày mai" (Sunrise tomorrow).
    // So if the event passed, it shows the next one.
    
    bool showNextDay = false;
    DateTime? displayTime = sunriseTime;
    String title = "MẶT TRỜI MỌC";
    String bottomText = "";
    
    if (sunriseTime != null && sunsetTime != null) {
      if (now.isAfter(sunsetTime)) {
        // Night after sunset: Show Next Sunrise (Tomorrow)
        // We can try to get tomorrow's data from index 1 if available
        if (daily.sunrise.length > 1) {
          displayTime = DateTime.parse(daily.sunrise[1]);
          showNextDay = true;
          // Bottom text: Sunset was at ...? Or Sunset tomorrow?
          // iPhone logic: "Mặt trời lặn: 17:35" (likely previous sunset or next?)
          // Screenshot shows "Mặt trời lặn: 17:35". 
          // If it is 22:16, 17:35 is the sunset that just happened.
          bottomText = "Mặt trời lặn: ${DateFormat('HH:mm').format(sunsetTime)}";
        }
      } else if (now.isAfter(sunriseTime)) {
        // Day time: Switch to Sunset? Or keep Sunrise but show "Sunset is in..."?
        // iPhone usually switches to "SUNSET" widget title if it's during the day.
        // However, the REQUEST asks for "Mặt trời mọc" (Sunrise) feature.
        // But to be "Similar to iPhone", it should be dynamic.
        // Let's assume the user wants the DYNAMIC behavior.
        // Screenshot 1: 06:05 (Sunrise) | Current time: Unknown in scr 1.
        // Screenshot 2: 22:16 | "06:05" (Sunrise tomorrow).
        
        // I'll implement: 
        // If current time < Sunset: Show Sunset Widget??
        // Wait, the user provided screenshot specifically says "Mặt trời mọc" (Sunrise). 
        // It might be they want that specific view.
        // BUT, usually these widgets toggle. 
        // Let's implement the "Next Event" logic or distinct Sunrise/Sunset logic.
        // Reference: Screen 1 shows "MẶT TRỜI MỌC" 06:05.
        // Screen 2 shows "Mặt trời mọc" detail.
        // I will stick to "Sunrise" focused card if looking at "Sunrise" feature? 
        // No, let's implement the smart toggle.
        // If (now < sunrise) -> Show Sunrise.
        // If (sunrise < now < sunset) -> Show Sunset.
        // If (sunset < now) -> Show Next Sunrise.
        
        // Let's refine based on user text "giống mặt trời mọc trên iphone".
        // It likely refers to the "Sunrise/Sunset" module.
        
        title = "MẶT TRỜI LẶN";
        displayTime = sunsetTime;
        bottomText = "Mặt trời mọc: ${DateFormat('HH:mm').format(sunriseTime)}"; // Next? No, past sunrise.
      } else {
        // Early morning before sunrise
        title = "MẶT TRỜI MỌC";
        displayTime = sunriseTime;
        bottomText = "Mặt trời lặn: ${DateFormat('HH:mm').format(sunsetTime)}";
      }
      
      // Override for "Now > Sunset" case which was handled first
       if (now.isAfter(sunsetTime)) {
         title = "MẶT TRỜI MỌC"; 
       }
    }
    
    // Fallback if formatting fails
    displayTime ??= DateTime.now();
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SunriseDetailScreen(
            daily: daily,
            latitude: latitude,
            longitude: longitude,
          )),
        );
      },
      child: Container(
        // height: 160, // Removed for flexibility
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  title == "MẶT TRỜI MỌC" ? Icons.wb_twilight : Icons.nights_stay, // Approx icons
                  color: Colors.white54,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Time
            Text(
              DateFormat('HH:mm').format(displayTime),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.normal, // San Francisco usually regular/medium here
              ),
            ),
            
            Expanded(
              child: CustomPaint(
                painter: SunGraphPainter(
                  latitude: latitude,
                  longitude: longitude,
                  now: now,
                  sunrise: sunriseTime,
                  sunset: sunsetTime,
                ),
                size: Size.infinite,
              ),
            ),
            
            Text(
              bottomText,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SunGraphPainter extends CustomPainter {
  final double latitude;
  final double longitude;
  final DateTime now;
  final DateTime? sunrise;
  final DateTime? sunset;

  SunGraphPainter({
    required this.latitude,
    required this.longitude,
    required this.now,
    this.sunrise,
    this.sunset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (sunrise == null || sunset == null) return;
    
    final paintLine = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    final paintHorizon = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final paintCurrent = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Draw Horizon
    double horizonY = size.height * 0.6; // Slightly below center
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), paintHorizon);
    
    // Draw Sine Wave (Sun Path)
    // We iterate from 0 to 24 hours
    final path = Path();
    bool firstPoint = true;
    
    // We want the curve to fit nicely.
    // Sunrise at x?, Sunset at x?
    // Map time 0..24 to width 0..size.width
    // Map elevation -90..90 to... well, we just want the visible part mostly.
    
    // We use the SunCalculator to get elevation for every hour/minute
    // Optimization: Calculate every 30 mins
    
    // Create a base date for calculation (today)
    DateTime baseDate = DateTime(now.year, now.month, now.day);
    
    Offset? currentPos;

    for (int i = 0; i <= 24 * 60; i += 15) { // every 15 mins
       double t = i / (24 * 60); // 0.0 to 1.0
       double x = t * size.width;
       
       DateTime time = baseDate.add(Duration(minutes: i));
       double elevation = SunCalculator.getSunElevation(time, latitude, longitude);
       
       // Map elevation to Y
       // Max elevation is typically < 90 (unless equator)
       // Let's say max usually 60-80. 
       // Scale: 90 deg -> 0 height? No, let's auto scale or fixed scale.
       // Fixed scale: 90 deg = 0, 0 deg = horizonY / -90 = height
       
       // Simplification: 
       // y = horizonY - (elevation * scale)
       double scale = size.height * 0.4 / 45; // 45 degrees takes 40% height
       double y = horizonY - (elevation * scale);
       
       if (firstPoint) {
         path.moveTo(x, y);
         firstPoint = false;
       } else {
         path.lineTo(x, y);
       }
       
       // Check for current time dot
       // Convert now to minutes from start of day
       int nowMinutes = now.hour * 60 + now.minute;
       if ((i <= nowMinutes) && ((i + 15) > nowMinutes)) {
          // Interpolate
          double subT = (nowMinutes - i) / 15.0;
          double nextX = ((i + 15) / (24 * 60)) * size.width;
          DateTime nextTime = baseDate.add(Duration(minutes: i + 15));
          double nextElev = SunCalculator.getSunElevation(nextTime, latitude, longitude);
          double nextY = horizonY - (nextElev * scale);
          
          currentPos = Offset(
            x + (nextX - x) * subT,
            y + (nextY - y) * subT
          );
       }
    }
    
    // Draw the path
    // We can use a Gradient or Solid color. The image shows a solid/faded grey curve.
    canvas.drawPath(path, paintLine);
    
    // Draw dot for current time
    if (currentPos != null) {
      canvas.drawCircle(currentPos, 4, paintCurrent);
      // Optional: Shadow/Glow
      canvas.drawCircle(currentPos, 4, Paint()..color = Colors.white.withOpacity(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
