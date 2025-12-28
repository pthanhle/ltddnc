import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_1/data/models/weather_model.dart';

class RainfallDetailScreen extends StatefulWidget {
  final WeatherData weatherData;
  final int initialDayIndex; // 0 for today, 1 for tomorrow, etc.

  const RainfallDetailScreen({
    super.key,
    required this.weatherData,
    this.initialDayIndex = 0,
  });

  @override
  State<RainfallDetailScreen> createState() => _RainfallDetailScreenState();
}

class _RainfallDetailScreenState extends State<RainfallDetailScreen> {
  int _selectedDayIndex = 0;
  String _unit = "mm"; // 'mm' or 'inch'

  late List<DateTime> _days;
  
  @override
  void initState() {
    super.initState();
    _generateDays();
    
    // Find today's index
    int todayIndex = _days.indexWhere((d) => _isToday(d));
    if (todayIndex != -1) {
      _selectedDayIndex = todayIndex;
    } else {
      _selectedDayIndex = widget.initialDayIndex;
    }
  }

  void _generateDays() {
    // Assuming weatherData.daily.time contains the dates
    _days = widget.weatherData.daily.time.map((d) => DateTime.parse(d)).toList();
  }
  
  // Helper to get hourly data for the selected day
  List<double> _getHourlyPrecipitationForDay(DateTime date) {
    List<double> precip = [];
    List<String> hours = widget.weatherData.hourly.time;
    List<double> values = widget.weatherData.hourly.precipitation;

    for (int i = 0; i < hours.length; i++) {
        DateTime t = DateTime.parse(hours[i]);
        if (t.year == date.year && t.month == date.month && t.day == date.day) {
            precip.add(values[i]);
        }
    }
    return precip;
  }

  List<int> _getHourlyProbForDay(DateTime date) {
    List<int> probs = [];
    List<String> hours = widget.weatherData.hourly.time;
    List<int> values = widget.weatherData.hourly.precipitationProbability;

    for (int i = 0; i < hours.length; i++) {
        DateTime t = DateTime.parse(hours[i]);
        if (t.year == date.year && t.month == date.month && t.day == date.day) {
            probs.add(values[i]);
        }
    }
    return probs;
  }

  double _getTotalRainfallForDay(int index) {
      if (index >= widget.weatherData.daily.precipitationSum.length) return 0.0;
      return widget.weatherData.daily.precipitationSum[index];
  }
  
  double _getPast24hRainfall() {
      // Logic to sum up last 24h from 'now'
      DateTime now = DateTime.now();
      double sum = 0;
      List<String> hours = widget.weatherData.hourly.time;
      List<double> values = widget.weatherData.hourly.precipitation;
      
      for(int i=0; i<hours.length; i++) {
          DateTime t = DateTime.parse(hours[i]);
          if (t.isBefore(now) && t.isAfter(now.subtract(const Duration(hours: 24)))) {
              sum += values[i];
          }
      }
      return sum;
  }

  double _getNext24hRainfall() {
      DateTime now = DateTime.now();
      double sum = 0;
      List<String> hours = widget.weatherData.hourly.time;
      List<double> values = widget.weatherData.hourly.precipitation;
      
      for(int i=0; i<hours.length; i++) {
          DateTime t = DateTime.parse(hours[i]);
          if (t.isAfter(now) && t.isBefore(now.add(const Duration(hours: 24)))) {
              sum += values[i];
          }
      }
      return sum;
  }

  String _formatVal(double val) {
     if (_unit == "mm") {
         return "${val.toStringAsFixed(1)} mm";
     } else {
         // Convert to inches
         return "${(val * 0.0393701).toStringAsFixed(2)}\"";
     }
  }

  bool _isToday(DateTime date) {
      final now = DateTime.now();
      return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    DateTime selectedDate = _days[_selectedDayIndex];
    List<double> hourlyPrecip = _getHourlyPrecipitationForDay(selectedDate);
    List<int> hourlyProb = _getHourlyProbForDay(selectedDate);
    double totalDaily = _getTotalRainfallForDay(_selectedDayIndex);

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
                   const Row(
                    children: [
                       Icon(Icons.water_drop, color: Colors.white, size: 16),
                       SizedBox(width: 8),
                       Text("Lượng mưa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
            
            // Date Selector
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  DateTime day = _days[index];
                  bool isSelected = index == _selectedDayIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = index),
                    child: Container(
                      width: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('E', 'vi').format(day).replaceAll("Th ", "T"),
                            style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day.day.toString(),
                            style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
             
             Padding(
               padding: const EdgeInsets.symmetric(vertical: 8),
               child: Text(
                 "Thứ ${DateFormat('E', 'vi').format(selectedDate)}, ngày ${DateFormat('d', 'vi').format(selectedDate)} tháng ${DateFormat('M', 'vi').format(selectedDate)}, ${selectedDate.year}",
                 style: TextStyle(color: Colors.grey[400], fontSize: 13),
               ),
             ),
             
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Total Summary & Dropdown
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatVal(totalDaily).replaceAll("\"", " in").replaceAll("mm", " mm"),
                                style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w300),
                              ),
                              Text("Tổng trong ngày", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButton<String>(
                              value: _unit,
                              underline: const SizedBox(),
                              dropdownColor: Colors.grey[800],
                              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                              style: const TextStyle(color: Colors.white),
                              items: const [
                                DropdownMenuItem(value: "mm", child: Text("mm")),
                                DropdownMenuItem(value: "inch", child: Text("inch")),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _unit = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Hourly Chart (Rain Amount)
                      Container(
                        height: 250,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: CustomPaint(
                          size: const Size(double.infinity, 250),
                          painter: RainfallChartPainter(
                            data: hourlyPrecip, 
                            unit: _unit,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Probability Chart
                      const Text(
                        "Khả năng có mưa",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                       const SizedBox(height: 4),
                       Text(
                        "Khả năng có mưa vào ${_isToday(selectedDate) ? "hôm nay" : DateFormat('EEEE', 'vi').format(selectedDate)}: ${hourlyProb.isNotEmpty ? hourlyProb.reduce(max) : 0}%",
                         style: TextStyle(color: Colors.grey[400], fontSize: 15)
                       ),
                       const SizedBox(height: 12),
                       
                       Container(
                        height: 200,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: CustomPaint(
                          size: const Size(double.infinity, 200),
                          painter: ProbabilityChartPainter(data: hourlyProb),
                        ),
                      ),
                       const SizedBox(height: 8),
                       Text(
                         "Khả năng có mưa hàng ngày có xu hướng cao hơn khả năng cho mỗi giờ.",
                         style: TextStyle(color: Colors.grey[500], fontSize: 13),
                       ),
                      
                      const SizedBox(height: 32),
                      
                      // Stats Cards
                      const Text(
                        "Tổng lượng mưa",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isToday(selectedDate) 
                          ? Column(
                              children: [
                                _buildStatRow("24 GIỜ QUA", "Lượng mưa", _getPast24hRainfall()),
                                const Divider(color: Colors.white12, height: 24),
                                _buildStatRow("24 GIỜ TỚI", "Lượng mưa", _getNext24hRainfall()),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Lượng mưa", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                                Text(_formatVal(totalDaily).replaceAll("\"", " in").replaceAll("mm", " mm"), style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                              ],
                            ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Daily Summary
                      const Text(
                        "Tóm tắt hàng ngày",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _isToday(selectedDate)
                              ? "Đã có lượng mưa ${_formatVal(_getPast24hRainfall())} trong 24 giờ qua. Tổng lượng mưa của hôm nay sẽ là ${_formatVal(totalDaily)}."
                              : "Vào ${DateFormat('EEEE', 'vi').format(selectedDate)}, tổng lượng mưa sẽ là ${_formatVal(totalDaily)}.",
                          style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                        ),
                      ),
                      
                       const SizedBox(height: 32),
                       
                       // Intensity Info
                       const Text(
                        "Cường độ mưa",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          "Cường độ được tính toán dựa trên lượng mưa hoặc tuyết rơi mỗi giờ và nhằm cho biết mức độ mưa hoặc tuyết cảm nhận được. Cường độ cũng được sử dụng cho các loại mưa khác.",
                          style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Options
                      const Text(
                        "Tùy chọn",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Đơn vị", style: TextStyle(color: Colors.white, fontSize: 16)),
                            DropdownButton<String>(
                              value: _unit,
                              underline: const SizedBox(),
                              dropdownColor: const Color(0xFF1C1C1E),
                              icon: const Icon(Icons.unfold_more, color: Colors.grey),
                              style: const TextStyle(color: Colors.white),
                              items: const [
                                DropdownMenuItem(value: "mm", child: Text("mm, cm")),
                                DropdownMenuItem(value: "inch", child: Text("inch")),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _unit = val);
                              },
                            ),
                          ],
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

  Widget _buildStatRow(String labelTop, String labelMain, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(labelTop, style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(labelMain, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        Text(_formatVal(value).replaceAll("\"", " in").replaceAll("mm", " mm"), style: TextStyle(color: Colors.grey[400], fontSize: 16)),
      ],
    );
  }
}

class RainfallChartPainter extends CustomPainter {
  final List<double> data;
  final String unit;
  
  RainfallChartPainter({required this.data, required this.unit});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final paintBar = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
      
    // Layout constants
    double bottomLabelHeight = 20;
    double chartHeight = size.height - bottomLabelHeight;
    double barWidth = (size.width / 24.0) * 0.6; // 24 bars
    
    // Draw Grid (Horizontal) - "Lớn", "Trung bình", "Nhỏ"
    // We need 3 zones roughly. 
    // mm/h: Light < 2.5, Mod 2.5-7.6, Heavy > 7.6
    // Let's set Max Y to roughly 10mm (or equiv in inch).
    double maxY = unit == 'mm' ? 10.0 : 0.4; 
    
    List<String> yLabels = ["Nhỏ", "Trung bình", "Lớn"];
    List<double> yPositions = [0.25, 0.5, 0.75]; // % of height from bottom
    
    TextStyle labelStyle = TextStyle(color: Colors.grey[500], fontSize: 12);
    
    for (int i=0; i<3; i++) {
        double y = chartHeight * (1 - yPositions[i]);
        // Draw line
        _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), paintGrid);
        // Label
        TextSpan span = TextSpan(style: labelStyle, text: yLabels[i]);
        TextPainter tp = TextPainter(text: span, textDirection: ui.TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(0, y - 15));
    }
    
    // Draw Bars
    for (int i = 0; i < data.length; i++) {
        // Safe check for 24h
        if (i >= 24) break;
        
        double val = data[i];
        if (unit == 'inch') val *= 0.0393701;
        
        double h = (val / maxY) * chartHeight;
        if (h > chartHeight) h = chartHeight; // Cap at max
        
        double x = (i / 24.0) * size.width;
        // Center bar in slot
        double barX = x + ((size.width / 24.0) - barWidth) / 2;
        
        if (val > 0) {
           RRect barRect = RRect.fromRectAndRadius(
               Rect.fromLTWH(barX, chartHeight - h, barWidth, h),
               const Radius.circular(2)
           );
           canvas.drawRRect(barRect, paintBar);
        }
    }
    
    // Draw Bottom Labels (00, 06, 12, 18)
    List<int> hours = [0, 6, 12, 18];
    for (int h in hours) {
         double x = (h / 24.0) * size.width;
          // Grid line vert
         _drawDashedLine(canvas, Offset(x, 0), Offset(x, chartHeight), paintGrid);
         
         TextSpan span = TextSpan(style: labelStyle, text: "${h.toString().padLeft(2, '0')} giờ");
         TextPainter tp = TextPainter(text: span, textDirection: ui.TextDirection.ltr);
         tp.layout();
         tp.paint(canvas, Offset(x + 2, chartHeight + 2));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    var max = (p2 - p1).distance;
    var dashWidth = 4.0;
    var dashSpace = 4.0;
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

class ProbabilityChartPainter extends CustomPainter {
  final List<int> data;
  
  ProbabilityChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    final paintBar = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    // Layout
    double rightLabelWidth = 35;
    double bottomLabelHeight = 20;
    double chartW = size.width - rightLabelWidth;
    double chartH = size.height - bottomLabelHeight;
    
    // Y Axis Labels (0, 20, 40, 60, 80, 100)
    TextStyle labelStyle = TextStyle(color: Colors.grey[500], fontSize: 12);
    for (int i=0; i<=5; i++) {
        int val = i * 20;
        double y = chartH - (val/100.0 * chartH);
        
        _drawDashedLine(canvas, Offset(0, y), Offset(chartW, y), paintGrid);
        
        TextSpan span = TextSpan(style: labelStyle, text: "$val%");
        TextPainter tp = TextPainter(text: span, textDirection: ui.TextDirection.ltr);
        tp.layout();
        tp.paint(canvas, Offset(chartW + 5, y - 6));
    }
    
    // Bars
    double slotW = chartW / 24.0;
    double barW = slotW * 0.7; // slightly wider than rain chart usually
    
    for (int i=0; i<data.length; i++) {
        if (i >= 24) break;
        double h = (data[i] / 100.0) * chartH;
        double x = i * slotW;
        double barX = x + (slotW - barW)/2;
        
        if (h > 0) {
             RRect barRect = RRect.fromRectAndRadius(
               Rect.fromLTWH(barX, chartH - h, barW, h),
               const Radius.circular(2)
             );
            canvas.drawRRect(barRect, paintBar);
        }
    }
    
    // X Axis Labels
    List<int> hours = [0, 6, 12, 18];
    for (int h in hours) {
         double x = (h / 24.0) * chartW;
         // Vert line
         _drawDashedLine(canvas, Offset(x, 0), Offset(x, chartH), paintGrid);
         
         TextSpan span = TextSpan(style: labelStyle, text: "${h.toString().padLeft(2, '0')} giờ");
         TextPainter tp = TextPainter(text: span, textDirection: ui.TextDirection.ltr);
         tp.layout();
         tp.paint(canvas, Offset(x, chartH + 2));
    }
  }
  
  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    var max = (p2 - p1).distance;
    var dashWidth = 4.0;
    var dashSpace = 4.0;
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
