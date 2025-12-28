import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/utils/sun_calculator.dart';

class SunriseDetailScreen extends StatefulWidget {
  final DailyWeather daily;
  final double latitude;
  final double longitude;

  const SunriseDetailScreen({
    super.key,
    required this.daily,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<SunriseDetailScreen> createState() => _SunriseDetailScreenState();
}

class _SunriseDetailScreenState extends State<SunriseDetailScreen> {
  late Map<String, DateTime?> _todaySolarEvents;
  late List<Map<String, dynamic>> _monthlyAverages;
  late Map<String, dynamic> _longestDay;
  double _minGraphHour = 4.0;
  double _maxGraphHour = 20.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _todaySolarEvents = SunCalculator.calculateSunTimes(now, widget.latitude, widget.longitude);
    _monthlyAverages = SunCalculator.getMonthlyAverages(now.year, widget.latitude, widget.longitude);
    
    // Calculate min/max for graph scaling
    double minH = 24.0;
    double maxH = 0.0;
    
    for (var m in _monthlyAverages) {
      DateTime sunr = m['sunrise'];
      DateTime suns = m['sunset'];
      double r = sunr.hour + sunr.minute/60.0;
      double s = suns.hour + suns.minute/60.0;
      if (r < minH) minH = r;
      if (s > maxH) maxH = s;
    }
    
    // Add padding (e.g. 1 hour) and clamp
    _minGraphHour = (minH - 1.0).clamp(0.0, 24.0);
    _maxGraphHour = (maxH + 1.0).clamp(0.0, 24.0);
    
    _longestDay = SunCalculator.getLongestDayOfYear(now.year, widget.latitude, widget.longitude);
  }

  @override
  Widget build(BuildContext context) {
    // ... existing initialization ...
    DateTime? apiSunrise;
    DateTime? apiSunset;
    
    try {
      if (widget.daily.sunrise.isNotEmpty) apiSunrise = DateTime.parse(widget.daily.sunrise[0]);
      if (widget.daily.sunset.isNotEmpty) apiSunset = DateTime.parse(widget.daily.sunset[0]);
    } catch (_) {}

    DateTime displaySunrise = apiSunrise ?? _todaySolarEvents['sunrise'] ?? DateTime.now();
    DateTime displaySunset = apiSunset ?? _todaySolarEvents['sunset'] ?? DateTime.now();
    
    Duration dayLen = displaySunset.difference(displaySunrise);
    String dayLenStr = "${dayLen.inHours}giờ ${dayLen.inMinutes % 60}phút";
    
    // Process Longest Day
    Duration maxDuration = _longestDay['duration'];
    DateTime maxDate = _longestDay['date'];
    String maxDayStr = "${maxDuration.inHours}giờ ${maxDuration.inMinutes % 60}phút";
    String maxDateStr = "${maxDate.day} thg ${maxDate.month}";

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const SizedBox(width: 40), 
                   Row(
                    children: [
                       Icon(Icons.wb_twilight, color: Colors.white, size: 16),
                       const SizedBox(width: 8),
                       Text("Mặt trời mọc", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.withOpacity(0.3)),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Big Time
                      Center(
                        child: Text(
                          DateFormat('HH:mm').format(displaySunrise), 
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 60,
                            fontWeight: FontWeight.w300,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          "Mặt trời mọc hôm nay", 
                          style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Chart
                      ClipRect(
                        child: SizedBox(
                          height: 250, // Keep height but ensure painter fits
                          width: double.infinity,
                          child: CustomPaint(
                            painter: DetailedSunGraphPainter(
                              latitude: widget.latitude,
                              longitude: widget.longitude,
                              now: DateTime.now(),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 50), 
                      
                      // Details List
                      _buildDetailRow("Ánh sáng đầu tiên", _todaySolarEvents['first_light']),
                      const Divider(color: Colors.white12),
                      _buildDetailRow("Mặt trời mọc hôm nay", displaySunrise, highlight: true),
                      const Divider(color: Colors.white12),
                      _buildDetailRow("Mặt trời lặn hôm nay", displaySunset, highlight: true),
                      const Divider(color: Colors.white12),
                      _buildDetailRow("Ánh sáng cuối cùng", _todaySolarEvents['last_light']),
                      const Divider(color: Colors.white12),
                      _buildDetailRowText("Tổng ánh sáng ban ngày", dayLenStr),
                       
                      const SizedBox(height: 40),
                      
                      // Averages Section
                      const Text(
                         "Mặt trời mọc và mặt trời lặn trung bình",
                         style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Ánh sáng ban ngày dài nhất: tổng $maxDayStr vào $maxDateStr",
                        style: TextStyle(color: Colors.grey[400], fontSize: 15),
                      ),
                      const SizedBox(height: 20),
                      
                      // Monthly Table
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: _monthlyAverages.map((m) => _buildMonthRow(m)).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, DateTime? time, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[300], fontSize: 17, fontWeight: FontWeight.w500)),
          Text(
            time != null ? DateFormat('HH:mm').format(time) : '--:--', 
            style: TextStyle(color: highlight ? Colors.white : Colors.grey[300], fontSize: 18, fontWeight: highlight ? FontWeight.bold : FontWeight.normal)
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRowText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[300], fontSize: 17, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMonthRow(Map<String, dynamic> data) {
    int month = data['month'];
    DateTime sunrise = data['sunrise'];
    DateTime sunset = data['sunset'];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          // Month Name
          SizedBox(
            width: 70, 
            child: Text("Tháng $month", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
          
          // Sunrise Time (Fixed Column)
          SizedBox(
            width: 50,
            child: Text(
              DateFormat('HH:mm').format(sunrise),
              style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          
          // Timeline Bar
          Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white10, // Track color (night/background)
                borderRadius: BorderRadius.circular(2),
              ),
              child: LayoutBuilder(
                 builder: (context, constraints) {
                 double w = constraints.maxWidth;
                 // Dynamic scaling based on min/max hours from data
                 double totalRange = _maxGraphHour - _minGraphHour;
                 if (totalRange <= 0) totalRange = 12.0;

                 double currentSunrise = sunrise.hour + sunrise.minute/60.0;
                 double currentSunset = sunset.hour + sunset.minute/60.0;
                 
                 double startPct = (currentSunrise - _minGraphHour) / totalRange;
                 double endPct = (currentSunset - _minGraphHour) / totalRange;
                 
                 // Clamp to 0..1 per row for rendering safety
                 startPct = startPct.clamp(0.0, 1.0);
                 endPct = endPct.clamp(startPct, 1.0);
                   
                   double barLeft = startPct * w;
                   double barRight = endPct * w;
                   double barWidth = barRight - barLeft;
                   
                   // Clamp values just in case
                   if (barWidth < 0) barWidth = 0;
                   
                   return Stack(
                      children: [
                         Positioned(
                            left: barLeft,
                            width: barWidth,
                            top: 0,
                            bottom: 0,
                            child: Container(
                               decoration: BoxDecoration(
                                 color: Colors.cyanAccent, 
                                 borderRadius: BorderRadius.circular(2),
                               ),
                            ),
                         ),
                      ],
                   );
                 },
              ),
            ),
          ),
          
          // Sunset Time (Fixed Column)
          SizedBox(
            width: 50,
            child: Text(
              DateFormat('HH:mm').format(sunset),
              textAlign: TextAlign.end,
              style: TextStyle(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class DetailedSunGraphPainter extends CustomPainter {
  final double latitude;
  final double longitude;
  final DateTime now;

  DetailedSunGraphPainter({required this.latitude, required this.longitude, required this.now});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    final paintCurve = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final paintCurrent = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // 1. Draw Horizon
    double horizonY = size.height * 0.55; 
    canvas.drawLine(Offset(0, horizonY), Offset(size.width, horizonY), paintGrid);
    
    // 2. Draw Vertical Time Grid (00, 06, 12, 18)
    TextStyle gridStyle = const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500);
    List<int> hours = [0, 6, 12, 18];
    double bottomLabelY = size.height - 20; // More space
    
    for (int h in hours) {
      double x = (h / 24.0) * size.width;
      // Draw line (dotted preferably)
      _drawDashedLine(canvas, Offset(x, 0), Offset(x, bottomLabelY - 5), paintGrid);
      
      // Draw Text. Align logic: 
      // 00 -> Left align
      // 24/18 -> Right align?
      // Grid typically centers, but edge cases matter.
      TextSpan span = TextSpan(style: gridStyle, text: "${h.toString().padLeft(2, '0')} giờ");
      TextPainter tp = TextPainter(text: span, textDirection: ui.TextDirection.ltr);
      tp.layout();
      
      double textX = x - tp.width / 2;
      if (h == 0) textX = x; // flush left
      if (h == 18) textX = x - tp.width; // closer to right edge often
      
      tp.paint(canvas, Offset(textX, bottomLabelY)); 
    }
    
    // 3. Draw Curve
    Path path = Path();
    DateTime baseDate = DateTime(now.year, now.month, now.day);
    double scale = size.height * 0.35 / 45; 
    
    Offset? currentPos;
    int nowMinutes = now.hour * 60 + now.minute;

    for (int i = 0; i <= 24 * 60; i += 5) { // More precision
      double t = i / (24 * 60);
      double x = t * size.width;
      DateTime time = baseDate.add(Duration(minutes: i));
      double elevation = SunCalculator.getSunElevation(time, latitude, longitude);
      double y = horizonY - (elevation * scale);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      // Better hit detection for current time
      if ((i <= nowMinutes) && ((i + 5) > nowMinutes)) {
          double subT = (nowMinutes - i) / 5.0;
          double nextX = ((i + 5) / (24 * 60)) * size.width;
          DateTime nextTime = baseDate.add(Duration(minutes: i + 5));
          double nextElev = SunCalculator.getSunElevation(nextTime, latitude, longitude);
          double nextY = horizonY - (nextElev * scale);
          currentPos = Offset(x + (nextX - x) * subT, y + (nextY - y) * subT);
       }
    }
    
    // Smooth curve
    canvas.drawPath(path, paintCurve);
    
    // FORCE DRAW CURRENT POS if found
    if (currentPos != null) {
      // Glow
      canvas.drawCircle(currentPos, 10, Paint()..color = Colors.white.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      // Outer Ring
      canvas.drawCircle(currentPos, 7, Paint()..color = Colors.black); 
      // Dot
      canvas.drawCircle(currentPos, 5, paintCurrent);
      // Stroke
      canvas.drawCircle(currentPos, 7, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth=2);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    var max = (p2 - p1).distance;
    var dashWidth = 5.0;
    var dashSpace = 5.0;
    double currentDistance = 0;
    while (currentDistance < max) {
      canvas.drawLine(
        p1 + (p2 - p1) * (currentDistance / max),
        p1 + (p2 - p1) * ((currentDistance + dashWidth) / max),
        paint,
      );
      currentDistance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
