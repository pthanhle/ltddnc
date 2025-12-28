import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_1/data/models/weather_model.dart';

class HumidityDetailScreen extends StatefulWidget {
  final WeatherData weatherData;
  final int initialDayIndex; 

  const HumidityDetailScreen({
    super.key,
    required this.weatherData,
    this.initialDayIndex = 0,
  });

  @override
  State<HumidityDetailScreen> createState() => _HumidityDetailScreenState();
}

class _HumidityDetailScreenState extends State<HumidityDetailScreen> {
  int _selectedDayIndex = 0;
  late List<DateTime> _days;
  
  @override
  void initState() {
    super.initState();
    _generateDays();
    
    // Find today
    int todayIndex = _days.indexWhere((d) => _isToday(d));
    if (todayIndex != -1) {
      _selectedDayIndex = todayIndex;
    } else {
      _selectedDayIndex = widget.initialDayIndex;
    }
  }

  void _generateDays() {
    _days = widget.weatherData.daily.time.map((d) => DateTime.parse(d)).toList();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Get Hourly Humidity for the selected day
  List<double> _getHourlyHumidity(DateTime date) {
    List<double> result = [];
    List<String> hours = widget.weatherData.hourly.time;
    List<double> values = widget.weatherData.hourly.relativeHumidity2m;

    for (int i = 0; i < hours.length; i++) {
        DateTime t = DateTime.parse(hours[i]);
        if (t.year == date.year && t.month == date.month && t.day == date.day) {
            result.add(values[i]);
        }
    }
    return result;
  }
  
  // Calculate Dew Point: Td = c * gamma / (b - gamma)
  double _calculateDewPoint(double temp, double rh) {
      // Magnus formula constants
      const double b = 17.625;
      const double c = 243.04;
      if (rh <= 0) return temp; // Avoid log(0)
      double gamma = log(rh / 100.0) + (b * temp) / (c + temp);
      return (c * gamma) / (b - gamma);
  }

  // Get Dew Points for the day
  List<double> _getHourlyDewPoints(DateTime date) {
      List<double> result = [];
      List<String> hours = widget.weatherData.hourly.time;
      List<double> temps = widget.weatherData.hourly.temperature2m;
      List<double> rh = widget.weatherData.hourly.relativeHumidity2m;

      for (int i = 0; i < hours.length; i++) {
          DateTime t = DateTime.parse(hours[i]);
          if (t.year == date.year && t.month == date.month && t.day == date.day) {
              result.add(_calculateDewPoint(temps[i], rh[i]));
          }
      }
      return result;
  }
  
  double _getAverage(List<double> data) {
      if (data.isEmpty) return 0;
      return data.reduce((a, b) => a + b) / data.length;
  }

  @override
  Widget build(BuildContext context) {
    DateTime selectedDate = _days[_selectedDayIndex];
    List<double> humidityData = _getHourlyHumidity(selectedDate);
    List<double> dewPointData = _getHourlyDewPoints(selectedDate);
    
    // Stats
    double avgHumidity = _getAverage(humidityData);
    double minDew = dewPointData.isNotEmpty ? dewPointData.reduce(min) : 0;
    double maxDew = dewPointData.isNotEmpty ? dewPointData.reduce(max) : 0;
    
    // Comparison
    double? yestAvgHumidity;
    bool hasYest = false;
    if (_selectedDayIndex > 0) {
        DateTime yestDate = _days[_selectedDayIndex - 1];
        List<double> yestData = _getHourlyHumidity(yestDate);
        if (yestData.isNotEmpty) {
            yestAvgHumidity = _getAverage(yestData);
            hasYest = true;
        }
    }
    
    // Current Display (Real-time if Today)
    double currentHumidity = 0;
    double currentDewPoint = 0;
    if (_isToday(selectedDate)) {
        currentHumidity = widget.weatherData.current.relativeHumidity2m;
        currentDewPoint = _calculateDewPoint(widget.weatherData.current.temperature2m, currentHumidity);
    } else {
        currentHumidity = avgHumidity;
        currentDewPoint = _calculateDewPoint(
            widget.weatherData.daily.temperature2mMax[_selectedDayIndex], // Approx using max temp? Or avg
            avgHumidity
        ); 
        // Better to just show range or avg for past days
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    const SizedBox(width: 40), 
                    const Row(
                     children: [
                        Icon(CupertinoIcons.drop_fill, color: Colors.white, size: 16), 
                        SizedBox(width: 8),
                        Text("Độ ẩm", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                         // MAIN DISPLAY
                       Text("${currentHumidity.round()}%", style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w400)),
                       Text(
                          "Điểm sương: ${currentDewPoint.round()}°",
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                       ),
                       const SizedBox(height: 24),
                       
                       // CHART
                        Container(
                         height: 250,
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: CustomPaint(
                             size: const Size(double.infinity, 250),
                             painter: HumidityChartPainter(data: humidityData),
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
                           "Hôm nay, độ ẩm trung bình là ${avgHumidity.round()}%. Điểm sương là ${minDew.round()}° đến ${maxDew.round()}°.",
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
                               !hasYest 
                                 ? "Không có dữ liệu hôm qua."
                                 : "Độ ẩm trung bình hôm nay ${avgHumidity > yestAvgHumidity! ? "cao hơn" : "thấp hơn"} hôm qua.",
                               style: const TextStyle(color: Colors.white, fontSize: 15),
                              ),
                              if (hasYest) ...[
                                  const SizedBox(height: 16),
                                  _buildComparisonBar("Hôm nay", avgHumidity, true),
                                  const SizedBox(height: 12),
                                  _buildComparisonBar("Hôm qua", yestAvgHumidity!, false),
                              ]
                           ],
                         ),
                       ),
                       
                       const SizedBox(height: 32),
                       
                       // INFO Humidity
                       const Text("Giới thiệu về Độ ẩm tương đối", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: const Text(
                           "Độ ẩm tương đối, thường được gọi đơn giản là độ ẩm, là lượng hơi ẩm có trong không khí so với lượng hơi ẩm mà không khí có thể lưu giữ. Không khí có thể lưu giữ nhiều hơi ẩm hơn ở nhiệt độ cao hơn. Độ ẩm tương đối gần 100% nghĩa là có thể có sương hoặc sương mù.",
                           style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                         ),
                       ),
                       
                       const SizedBox(height: 32),
                       
                        // INFO Dew Point
                       const Text("Giới thiệu về Điểm sương", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: const Text(
                           "Điểm sương là ngưỡng mà nhiệt độ cần giảm xuống để hình thành sương. Đó có thể là một cách hữu ích để cho biết cảm giác về độ ẩm không khí – điểm sương càng cao thì cảm giác độ ẩm càng lớn. Điểm sương khớp với nhiệt độ hiện tại nghĩa là độ ẩm tương đối bằng 100% và có thể có sương hoặc sương mù.",
                           style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                         ),
                       ),
                       
                       const SizedBox(height: 40),
                    ]
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildComparisonBar(String label, double value, bool highlight) {
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
                              widthFactor: value / 100.0,
                              child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: highlight ? Colors.blue : Colors.grey[500],
                                      borderRadius: BorderRadius.circular(3)
                                  ),
                              ),
                          )
                      ],
                  )
              ),
              const SizedBox(width: 12),
              SizedBox(width: 40, child: Text("${value.round()}%", textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 16))),
          ],
      );
  }
}

class HumidityChartPainter extends CustomPainter {
  final List<double> data;
  HumidityChartPainter({required this.data});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    double bottomH = 20;
    double topH = 20;
    double h = size.height - bottomH - topH;
    double w = size.width;
    double stepX = w / 24.0; // 24 hours
    
    final paintGrid = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    // Y-Axis Labels (Right side)
    // 0, 20, 40, 60, 80, 100
    List<int> yLevels = [0, 20, 40, 60, 80, 100];
    TextStyle yStyle = TextStyle(color: Colors.grey[500], fontSize: 10);
    double rightPadding = 30;
    double chartW = w - rightPadding;

    for (int lvl in yLevels) {
        double y = topH + h - (lvl / 100 * h);
        
        // Grid Line
        if (lvl > 0 && lvl < 100) {
           _drawDashedGridLine(canvas, Offset(0, y), Offset(chartW, y), paintGrid);
        }
        
        // Label
        textPainter.text = TextSpan(text: "$lvl%", style: yStyle);
        textPainter.layout();
        textPainter.paint(canvas, Offset(w - textPainter.width, y - textPainter.height/2));
    }
    
    // X-Axis Grid & Labels (00 giờ, 06 giờ...)
    List<int> hours = [0, 6, 12, 18];
    TextStyle xStyle = TextStyle(color: Colors.grey[500], fontSize: 10);
    
    for (int hr in hours) {
        double x = hr * stepX + stepX/2; // Center of the hour slot
        
        // Vertical Grid Line
        _drawDashedGridLine(canvas, Offset(x, topH), Offset(x, topH + h), paintGrid);
        
        // Label
        textPainter.text = TextSpan(text: "${hr.toString().padLeft(2, '0')} giờ", style: xStyle);
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width/2, topH + h + 5));
        
        // Top Value Label (Value at this hour)
        if (hr < data.length) {
            double val = data[hr];
            textPainter.text = TextSpan(text: "${val.round()}%", style: const TextStyle(color: Colors.white, fontSize: 12));
            textPainter.layout();
            textPainter.paint(canvas, Offset(x - textPainter.width/2, 0)); // At very top
        }
    }
    
    // Build Path
    Path path = Path();
    for (int i=0; i<data.length; i++) {
        if (i >= 24) break;
        double x = i * stepX + stepX/2;
        double val = data[i];
        double y = topH + h - (val / 100 * h);
        
        if (i==0) path.moveTo(x, y);
        else {
             double prevX = (i-1) * stepX + stepX/2;
             double prevY = topH + h - (data[i-1] / 100 * h);
             double cp1x = (prevX + x) / 2;
             path.cubicTo(cp1x, prevY, cp1x, y, x, y);
        }
    }
    
    // Gradient Fill
    // iOS Humidity: Purple (High) -> Blue (Mid) -> Green (Low)
    List<Color> gradientColors = [
        const Color(0xFF6A5ACD), // SlateBlue / Purple
        const Color(0xFF4169E1), // RoyalBlue
        const Color(0xFF2E8B57), // SeaGreen
    ];
    List<double> stops = [0.0, 0.5, 1.0];
    
    Path fillPath = Path.from(path);
    fillPath.lineTo((data.length-1 < 24 ? data.length-1 : 23) * stepX + stepX/2, topH + h);
    fillPath.lineTo(stepX/2, topH + h);
    fillPath.close();
    
    Paint fillPaint = Paint()
       ..shader = ui.Gradient.linear(
           Offset(0, topH),
           Offset(0, topH + h),
           gradientColors.map((c) => c.withOpacity(0.5)).toList(),
           stops
       );
       
    canvas.drawPath(fillPath, fillPaint);
    
    // Stroke (Dashed Gradient)
    Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
           Offset(0, topH),
           Offset(0, topH + h),
           gradientColors,
           stops
       );
       
     _drawDashedPath(canvas, path, strokePaint);
     
     // Current Dot (Last point of data)
     if (data.isNotEmpty) {
         int lastIdx = data.length - 1;
         if (lastIdx >= 24) lastIdx = 23;
         double x = lastIdx * stepX + stepX/2;
         double y = topH + h - (data[lastIdx] / 100 * h);
         
         canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.white);
         canvas.drawCircle(Offset(x, y), 5, Paint()..color = Colors.black.withOpacity(0.2)..style=PaintingStyle.stroke..strokeWidth=1);
     }
  }
  
  void _drawDashedGridLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    var max = (p2 - p1).distance;
    var dashWidth = 2.0;
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
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + 6),
          paint,
        );
        distance += 10; 
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
