import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/ui/widgets/glass_container.dart';

class PressureDetailScreen extends StatefulWidget {
  final WeatherData weatherData;

  const PressureDetailScreen({super.key, required this.weatherData});

  @override
  State<PressureDetailScreen> createState() => _PressureDetailScreenState();
}

class _PressureDetailScreenState extends State<PressureDetailScreen> {
  int _selectedDayIndex = 0;
  String _unit = "hPa"; // hPa, mmHg, mbar, kPa
  late List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    _generateDays();
    int todayIndex = _days.indexWhere((d) => _isToday(d));
    if (todayIndex != -1) {
      _selectedDayIndex = todayIndex;
    }
  }

  void _generateDays() {
    _days = widget.weatherData.daily.time.map((d) => DateTime.parse(d)).toList();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  double _convertPressure(double hPa) {
      switch (_unit) {
          case "mmHg": return hPa * 0.750062;
          case "mbar": return hPa;
          case "kPa": return hPa / 10.0;
          default: return hPa; // hPa
      }
  }
  
  String _formatVal(double val) {
      if (_unit == "kPa") return val.toStringAsFixed(2);
      if (_unit == "mmHg") return val.round().toString();
      return val.round().toString(); // hPa, mbar
  }

  // Get Hourly Pressure
  List<double> _getHourlyPressure(DateTime date) {
    List<double> result = [];
    List<String> hours = widget.weatherData.hourly.time;
    List<double> values = widget.weatherData.hourly.surfacePressure; 

    for (int i = 0; i < hours.length; i++) {
        DateTime t = DateTime.parse(hours[i]);
        if (t.year == date.year && t.month == date.month && t.day == date.day) {
            result.add(_convertPressure(values[i]));
        }
    }
    return result;
  }
  
  // Calculate Trend for a specific hour index in the day list
  // Returns: -1 (Down), 0 (Stable), 1 (Up)
  int _getTrend(List<double> data, int i) {
      if (i == 0) return 0;
      double diff = data[i] - data[i-1];
      // Threshold? 
      // If units are small (kPa), diff is small.
      double threshold = 0.5;
      if (_unit == "kPa") threshold = 0.05;
      
      if (diff > threshold) return 1;
      if (diff < -threshold) return -1;
      return 0; // Stable
  }

  String _getTrendText(int trend) {
      if (trend > 0) return "tăng";
      if (trend < 0) return "giảm";
      return "ổn định";
  }

  @override
  Widget build(BuildContext context) {
    DateTime selectedDate = _days[_selectedDayIndex];
    List<double> hourlyData = _getHourlyPressure(selectedDate);
    
    // Stats
    double minP = hourlyData.isNotEmpty ? hourlyData.reduce(min) : 0;
    double maxP = hourlyData.isNotEmpty ? hourlyData.reduce(max) : 0;
    double avgP = hourlyData.isNotEmpty ? hourlyData.reduce((a,b)=>a+b)/hourlyData.length : 0;
    
    // Display Logic
    double currentVal = 0;
    String status = "";
    
    if (_isToday(selectedDate)) {
        currentVal = _convertPressure(widget.weatherData.current.surfacePressure);
        // Find rough trend from last few hours?
        // Or simplified: just comparisons
        status = "Ổn định"; // Placeholder logic, could be more complex
        
        // Let's refine trend based on current hour data if available
        int currentHour = DateTime.now().hour;
        if (currentHour < hourlyData.length && currentHour > 0) {
            int trend = _getTrend(hourlyData, currentHour);
            if (trend > 0) status = "Đang tăng";
            else if (trend < 0) status = "Đang giảm";
        }
    } else {
        currentVal = maxP; // Show Max for other days
        status = "Trung bình ${avgP.round()} $_unit";
    }

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
                        Icon(CupertinoIcons.gauge, color: Colors.white, size: 16), 
                        SizedBox(width: 8),
                        Text("Áp suất", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                        // Main Value
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(_formatVal(currentVal), style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w400)),
                            Text(" $_unit", style: const TextStyle(color: Colors.grey, fontSize: 32, fontWeight: FontWeight.w400)),
                          ],
                        ),
                        Text(
                          status,
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        
                        // CHART
                        Container(
                         height: 300,
                         padding: const EdgeInsets.fromLTRB(10, 10, 15, 10),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: CustomPaint(
                             size: const Size(double.infinity, 300),
                             painter: PressureChartPainter(
                                 data: hourlyData, 
                                 unit: _unit,
                                 isToday: _isToday(selectedDate)
                             ),
                         ),
                       ),
                       
                       const SizedBox(height: 32),
                       
                       // SUMMARY
                       const Text("Tóm tắt hàng ngày", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                             ? "Áp suất hiện tại là ${_formatVal(currentVal)} $_unit và ${status.toLowerCase()}. Hôm nay, áp suất trung bình sẽ là ${_formatVal(avgP)} $_unit và áp suất thấp nhất sẽ là ${_formatVal(minP)} $_unit."
                             : "Vào ${DateFormat('EEEE', 'vi').format(selectedDate)}, áp suất trung bình là ${_formatVal(avgP)} $_unit và áp suất thấp nhất là ${_formatVal(minP)} $_unit.",
                           style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                         ),
                       ),

                       const SizedBox(height: 32),
                       
                       // INTRO
                       const Text("Giới thiệu về Áp suất", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: const Text(
                           "Những thay đổi nhanh, đáng kể về áp suất được sử dụng để dự đoán các thay đổi về thời tiết. Ví dụ: sự sụt giảm áp suất có thể nghĩa là sắp có mưa hoặc tuyết và áp suất tăng có thể nghĩa là thời tiết sẽ cải thiện. Áp suất cũng được gọi là áp suất khí quyển hoặc áp suất không khí.",
                           style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                         ),
                       ),
                       
                       const SizedBox(height: 32),
                       
                       // OPTIONS
                       const Text("Tùy chọn", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Column(
                           children: [
                             _buildOptionRow("Đơn vị", _unit, ["hPa", "mmHg", "mbar", "kPa"], (val) {
                                 setState(() {
                                     _unit = val;
                                 });
                             }),
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

  Widget _buildOptionRow(String label, String currentVal, List<String> items, Function(String) onChanged) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
                DropdownButton<String>(
                  value: items.contains(currentVal) ? currentVal : items[0],
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF2C2C2E),
                  icon: const Icon(Icons.unfold_more, color: Colors.grey, size: 20),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) {
                      if (val != null) onChanged(val);
                  },
                )
            ],
        ),
      );
  }
}

class PressureChartPainter extends CustomPainter {
  final List<double> data;
  final String unit;
  final bool isToday;

  PressureChartPainter({required this.data, required this.unit, required this.isToday});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final double padTop = 30; // Space for arrows
    final double padBottom = 20;
    final double padRight = 40;
    final double chartH = size.height - padTop - padBottom;
    final double w = size.width - padRight;
    final double stepX = w / 24.0;
    
    // Bounds (Dynamic)
    double minV = data.reduce(min);
    double maxV = data.reduce(max);
    // Add buffer
    double span = maxV - minV;
    if (span < 5) span = 5; // Minimum span for visual
    if (unit == "kPa") if (span < 0.5) span = 0.5;
    
    double yMin = minV - span * 0.2;
    double yMax = maxV + span * 0.2;
    
    final paintGrid = Paint()..color = Colors.grey.withOpacity(0.2)..strokeWidth=1..style=PaintingStyle.stroke;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    
    // Y Grid & Labels
    int steps = 4;
    for (int i=0; i<=steps; i++) {
        double val = yMin + (span * 1.4) * (i/steps); // spanning yMin to yMax logic? 
        // Better:
        val = yMin + ((yMax-yMin)/steps)*i;
        
        double y = padTop + chartH - ((val-yMin)/(yMax-yMin))*chartH;
        
        // Grid Line
        if(i>0 && i<steps) _drawDashedLine(canvas, Offset(0, y), Offset(w, y), paintGrid);
        
        // Label
        String label = (unit == "kPa") ? val.toStringAsFixed(2) : val.round().toString();
        textPainter.text = TextSpan(text: label, style: TextStyle(color: Colors.grey[500], fontSize: 11));
        textPainter.layout();
        textPainter.paint(canvas, Offset(size.width - textPainter.width, y - textPainter.height/2));
    }
    
    // X Axis Labels
    List<int> timeMarks = [0, 6, 12, 18];
    for (int hr in timeMarks) {
        double x = hr * stepX + stepX/2;
        _drawDashedLine(canvas, Offset(x, padTop), Offset(x, padTop + chartH), paintGrid);
         textPainter.text = TextSpan(text: "${hr.toString().padLeft(2,'0')} giờ", style: TextStyle(color: Colors.grey[500], fontSize: 11));
         textPainter.layout();
         textPainter.paint(canvas, Offset(x - textPainter.width/2, size.height - 15));
    }
    
    // Top Trend Arrows
    for (int i=1; i<data.length; i++) { // From 1 to show change from prev
        if (i%2 != 0) continue; // Show every 2 hours? Or 3? Image shows packed arrows.
        if (i>=24) break;
        
        double diff = data[i] - data[i-1];
        String arrow = "=";
        
        // Thresholds depend on unit
        double thres = 0.1;
        if (unit == "kPa") thres = 0.01;
        
        if (diff > thres) arrow = "↑";
        else if (diff < -thres) arrow = "↓";
        
        double x = i*stepX + stepX/2;
        textPainter.text = TextSpan(text: arrow, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold));
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width/2, 5));
    }

    // Curve
    Path path = Path();
    for (int i=0; i<data.length; i++) {
        if (i>=24) break;
        double x = i*stepX + stepX/2;
        double y = padTop + chartH - ((data[i] - yMin) / (yMax - yMin) * chartH);
        
        if (i==0) path.moveTo(x, y);
        else {
             double prevX = (i-1)*stepX + stepX/2;
             double prevY = padTop + chartH - ((data[i-1] - yMin) / (yMax - yMin) * chartH);
             double cpX = (prevX + x)/2;
             path.cubicTo(cpX, prevY, cpX, y, x, y);
        }
    }
    
    // Fill
    Path fillPath = Path.from(path);
    fillPath.lineTo((data.length>24?23:data.length-1)*stepX+stepX/2, padTop+chartH);
    fillPath.lineTo(stepX/2, padTop+chartH);
    fillPath.close();
    
    Paint fillPaint = Paint()
      ..shader = ui.Gradient.linear(
          Offset(0, padTop),
          Offset(0, padTop + chartH),
          [Colors.purpleAccent.withOpacity(0.5), Colors.purpleAccent.withOpacity(0.0)],
      );
    canvas.drawPath(fillPath, fillPaint);
    
    // Stroke
    Paint strokePaint = Paint()
      ..color = Colors.purpleAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);
    
    // Current Dot
    if (isToday) {
         DateTime now = DateTime.now();
         double frac = (now.hour + now.minute/60.0) / 23.0; // rough placement
         // Find exact pos on curve? 
         // Let's just place point at current hour index interpolation
         int hr = now.hour;
         if (hr < data.length) {
             double min = now.minute.toDouble();
             double v1 = data[hr];
             double v2 = (hr+1 < data.length) ? data[hr+1] : v1;
             double val = v1 + (v2-v1)*(min/60.0);
             
             double x = (hr + min/60.0) * stepX + stepX/2;
             double y = padTop + chartH - ((val - yMin) / (yMax - yMin) * chartH);
             
             canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
             canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.black.withOpacity(0.2)..style=PaintingStyle.stroke..strokeWidth=1);
         }
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
