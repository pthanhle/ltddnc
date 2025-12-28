import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/ui/widgets/glass_container.dart';

class VisibilityDetailScreen extends StatefulWidget {
  final WeatherData weatherData;

  const VisibilityDetailScreen({super.key, required this.weatherData});

  @override
  State<VisibilityDetailScreen> createState() => _VisibilityDetailScreenState();
}

class _VisibilityDetailScreenState extends State<VisibilityDetailScreen> {
  int _selectedDayIndex = 0;
  bool _isKm = true; // true = km, false = miles
  late List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    _generateDays();
    // Default to today
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
  
  // Helpers
  double _metersToUnit(double meters) {
      if (_isKm) return meters / 1000.0;
      return meters / 1609.34;
  }
  
  String _unitString() => _isKm ? "km" : "mi";

  List<double> _getHourlyVisibility(DateTime date) {
    List<double> result = [];
    List<String> hours = widget.weatherData.hourly.time;
    List<double> values = widget.weatherData.hourly.visibility; // in meters

    for (int i = 0; i < hours.length; i++) {
        DateTime t = DateTime.parse(hours[i]);
        if (t.year == date.year && t.month == date.month && t.day == date.day) {
            result.add(_metersToUnit(values[i]));
        }
    }
    return result;
  }

  String _getVisibilityDescription(double value, bool isKm) {
      // Thresholds approx: 
      // < 1km: Foggy/Poor
      // 1-10km: Moderate
      // > 10km: Clear/Good
      // "Tầm nhìn bằng hoặc trên 10 km được coi là rõ." -> From image text
      double valInKm = isKm ? value : value * 1.60934;
      
      if (valInKm >= 10) return "Hoàn toàn rõ";
      if (valInKm >= 5) return "Rõ";
      if (valInKm >= 1) return "Trung bình";
      return "Kém";
  }

  @override
  Widget build(BuildContext context) {
    DateTime selectedDate = _days[_selectedDayIndex];
    List<double> hourlyData = _getHourlyVisibility(selectedDate);
    
    // Stats
    double minVis = hourlyData.isNotEmpty ? hourlyData.reduce(min) : 0;
    double maxVis = hourlyData.isNotEmpty ? hourlyData.reduce(max) : 0;
    
    // Current or Summary Display
    double displayValue = 0;
    String displayDesc = "";
    
    if (_isToday(selectedDate)) {
        displayValue = _metersToUnit(widget.weatherData.current.visibility);
        displayDesc = _getVisibilityDescription(displayValue, _isKm) == "Hoàn toàn rõ" 
             ? "Tầm nhìn hoàn toàn rõ" 
             : "Tầm nhìn ${_getVisibilityDescription(displayValue, _isKm).toLowerCase()}";
    } else {
        displayValue = maxVis; // Show max potential? Or Avg?
        displayDesc = "Tầm nhìn tối đa ${displayValue.round()} ${_unitString()}";
    }

    // Comparison Data (Yesterday)
    double? yestAvg;
    if (_selectedDayIndex > 0) {
        DateTime yestDate = _days[_selectedDayIndex - 1];
        List<double> yestData = _getHourlyVisibility(yestDate);
        if (yestData.isNotEmpty) {
            yestAvg = yestData.reduce((a,b)=>a+b) / yestData.length;
        }
    }
    double curAvg = hourlyData.isEmpty ? 0 : hourlyData.reduce((a,b)=>a+b) / hourlyData.length;

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
                        Icon(CupertinoIcons.eye_fill, color: Colors.white, size: 16), 
                        SizedBox(width: 8),
                        Text("Tầm nhìn", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
             // Date Selector (Reuse style)
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
                            Text("${displayValue.round()}", style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w400)),
                            Text(" ${_unitString()}", style: const TextStyle(color: Colors.grey, fontSize: 32, fontWeight: FontWeight.w400)),
                          ],
                        ),
                        Text(
                          displayDesc,
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        
                        // CHART
                        Container(
                         height: 300,
                         padding: const EdgeInsets.fromLTRB(10, 25, 15, 10),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: CustomPaint(
                             size: const Size(double.infinity, 300),
                             painter: VisibilityChartPainter(data: hourlyData, isKm: _isKm),
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
                           "Hôm nay, tầm nhìn thấp nhất sẽ là ${_getVisibilityDescription(minVis, _isKm)} ở mức ${minVis.round()} ${_unitString()} và cao nhất sẽ là ${_getVisibilityDescription(maxVis, _isKm)} ở mức ${maxVis.round()} ${_unitString()}.",
                           style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                         ),
                       ),

                       const SizedBox(height: 32),
                       
                       // COMPARISON
                       const Text("So sánh hàng ngày", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                              Text(
                               yestAvg == null
                                 ? "Không có dữ liệu hôm qua."
                                 : (curAvg - yestAvg).abs() < 1 
                                     ? "Tầm nhìn hôm nay tương tự như hôm qua."
                                     : "Tầm nhìn hôm nay ${curAvg > yestAvg ? "tốt hơn" : "kém hơn"} hôm qua.",
                               style: const TextStyle(color: Colors.white, fontSize: 15),
                              ),
                              if (yestAvg != null) ...[
                                  const SizedBox(height: 16),
                                  _buildComparisonBar("Hôm nay", curAvg, true, _unitString()),
                                  const SizedBox(height: 12),
                                  _buildComparisonBar("Hôm qua", yestAvg, false, _unitString()),
                              ]
                           ],
                         ),
                       ),

                       const SizedBox(height: 32),
                       
                       // INTRO
                       const Text("Giới thiệu về Tầm nhìn", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: const Text(
                           "Tầm nhìn cho biết khoảng cách mà bạn có thể nhìn rõ các vật thể như tòa nhà và đồi núi. Đó là một số đo về độ trong suốt của không khí và không tính đến lượng ánh sáng mặt trời hoặc sự hiện diện của các vật cản. Tầm nhìn bằng hoặc trên 10 km được coi là rõ.",
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
                             _buildOptionRow("Đơn vị", _isKm ? "km" : "mi", ["km", "mi"], (val) {
                                 setState(() {
                                     _isKm = val == "km";
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
        padding: const EdgeInsets.symmetric(vertical: 0), // Compact vertical padding inside as in FeelsLike
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
                DropdownButton<String>(
                  value: items.contains(currentVal) ? currentVal : items[0],
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF2C2C2E), // Slightly lighter than background for contrast or match
                  icon: const Icon(Icons.unfold_more, color: Colors.grey, size: 20),
                  style: const TextStyle(color: Colors.white, fontSize: 16), // White text for value
                  items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) {
                      if (val != null) onChanged(val);
                  },
                )
            ],
        ),
      );
  }

  Widget _buildComparisonBar(String label, double value, bool highlight, String unit) {
      return Row(
          children: [
              SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
              Expanded(
                  child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                          Container(
                              height: 6,
                              decoration: BoxDecoration(
                                  color: Colors.grey[800],
                                  borderRadius: BorderRadius.circular(3)
                              ),
                          ),
                          FractionallySizedBox(
                              widthFactor: (value / 50.0).clamp(0.0, 1.0), // Scale max 50km
                              child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: highlight ? Colors.white : Colors.grey[600],
                                      borderRadius: BorderRadius.circular(3)
                                  ),
                              ),
                          )
                      ],
                  )
              ),
              const SizedBox(width: 12),
              SizedBox(width: 55, child: Text("${value.round()} $unit", textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 16))),
          ],
      );
  }
}

class VisibilityChartPainter extends CustomPainter {
  final List<double> data;
  final bool isKm;
  VisibilityChartPainter({required this.data, required this.isKm});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    // Params
    double padTop = 20;
    double padBottom = 20;
    double padRight = 30; // Axis
    
    double h = size.height - padTop - padBottom;
    double w = size.width - padRight;
    double stepX = w / 24.0;
    
    // Y Scale: Max 45 km? Or data dependent + buffer?
    // Image shows 0 - 45 for scale.
    double maxY = 45; 
    if (!isKm) maxY = 28; // approx 45km in miles
    
    // Paints
    final paintGrid = Paint()..color = Colors.grey.withOpacity(0.2)..strokeWidth=1..style=PaintingStyle.stroke;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    
    // Y Axis Labels (Right)
    // 5, 10, 15... 
    // Image shows: 0, 5, 10, 15... 45?
    // Let's draw every 10?
    // Image: "0 km" at bottom, then 5, 10... 45.
    double yStepVal = 5;
    if (!isKm) yStepVal = 3;
    
    for (double v=0; v<=maxY; v+=yStepVal) {
        if (v > maxY) break;
        double y = padTop + h - (v/maxY)*h;
        
        // Grid line
        if (v>0) _drawDashedGridLine(canvas, Offset(0, y), Offset(w, y), paintGrid);
        
        // Label
        String label = "${v.toInt()}";
        if (v==0) label = "0 ${isKm ? 'km' : 'mi'}"; // "0 km"
        
        // Skip some if crowded?
        if (v % (yStepVal*2) != 0 && v!=0 && v!=maxY) continue; 
        
        textPainter.text = TextSpan(text: label, style: TextStyle(color: Colors.grey[500], fontSize: 11));
        textPainter.layout();
        textPainter.paint(canvas, Offset(size.width - textPainter.width, y - textPainter.height/2));
    }
    
    // X Axis Labels (00 giờ...)
    List<int> timeMarks = [0, 6, 12, 18];
    for(int hr in timeMarks) {
        double x = hr * stepX + stepX/2;
        _drawDashedGridLine(canvas, Offset(x, padTop), Offset(x, padTop + h), paintGrid);
        
        textPainter.text = TextSpan(text: "${hr.toString().padLeft(2,'0')} giờ", style: TextStyle(color: Colors.grey[500], fontSize: 11));
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width/2, size.height - 15));
    }
    
    // Top Data Labels
    // Draw every 2-3 hours
    for (int i=0; i<data.length; i++) {
        if (i >= 24) break;
        if (i % 3 != 0 && i != data.length-1) continue; // Sparse
        
        double x = i * stepX + stepX/2;
        double val = data[i];
        
        textPainter.text = TextSpan(text: "${val.round()}", style: TextStyle(color: Colors.grey[400], fontSize: 12));
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width/2, 0));
    }
    
    // Curve
    Path path = Path();
    for (int i=0; i<data.length; i++) {
        if (i>=24) break;
        double x = i*stepX + stepX/2;
        double val = data[i];
        if (val > maxY) val = maxY;
        double y = padTop + h - (val/maxY)*h;
        
        if (i==0) path.moveTo(x, y);
        else {
             // Cubic
             double prevX = (i-1)*stepX + stepX/2;
             double prevVal = data[i-1] > maxY ? maxY : data[i-1];
             double prevY = padTop + h - (prevVal/maxY)*h;
             double cpX = (prevX + x)/2;
             path.cubicTo(cpX, prevY, cpX, y, x, y);
        }
    }
    
    // Fill Gradient (Bottom)
    Path fillPath = Path.from(path);
    fillPath.lineTo((data.length > 24 ? 23 : data.length-1)*stepX + stepX/2, padTop+h);
    fillPath.lineTo(stepX/2, padTop+h);
    fillPath.close();
    
    Paint fillPaint = Paint()
      ..shader = ui.Gradient.linear(
          Offset(0, padTop),
          Offset(0, padTop + h),
          [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.0)],
      );
    canvas.drawPath(fillPath, fillPaint);
    
    // Dashed Stroke
    Paint strokePaint = Paint()
      ..color = Colors.grey[400]!
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
   _drawDashedPath(canvas, path, strokePaint);
   
   // Current Dot
   if (data.isNotEmpty) {
       int lastIdx = data.length - 1;
       if (lastIdx >= 24) lastIdx = 23;
       double x = lastIdx * stepX + stepX/2;
       double val = data[lastIdx] > maxY ? maxY : data[lastIdx];
       double y = padTop + h - (val/maxY)*h;
       
       canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
   }
  }

  void _drawDashedGridLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    var max = (p2 - p1).distance;
    var dashWidth = 2.0; // small dash for grid
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

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    ui.PathMetrics pathMetrics = path.computeMetrics();
    for (ui.PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        // Dash length 8, space 6
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + 8),
          paint,
        );
        distance += 14; 
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
