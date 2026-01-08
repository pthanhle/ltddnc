import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/utils/weather_utils.dart';

class DailyDetailModal extends StatefulWidget {
  final WeatherData weather;
  final int initialIndex;

  const DailyDetailModal({
    super.key,
    required this.weather,
    required this.initialIndex,
  });

  @override
  State<DailyDetailModal> createState() => _DailyDetailModalState();
}

class _DailyDetailModalState extends State<DailyDetailModal> {
  late PageController _pageController;
  late int _selectedIndex;
  
  // Options
  String _tempUnit = "°C";
  String _precipUnit = "mm";
  int _chartMode = 0; // 0: Thực tế, 1: Cảm nhận

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  void _onDaySelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  // --- Helpers ---
  List<double> _getHourlyData(List<double> source, int dayIndex) {
    int start = dayIndex * 24;
    int end = start + 24;
    if (source.length < end) return [];
    return source.sublist(start, end);
  }

  List<int> _getHourlyIntData(List<int> source, int dayIndex) {
    int start = dayIndex * 24;
    int end = start + 24;
    if (source.length < end) return [];
    return source.sublist(start, end);
  }
  
  List<int> _getCodesForDay(int dayIndex) {
    int start = dayIndex * 24;
    int end = start + 24;
    if (widget.weather.hourly.weatherCode.length < end) return [];
    return widget.weather.hourly.weatherCode.sublist(start, end);
  }

  String _formatTemp(double val) {
    if (_tempUnit == "°F") {
      return "${((val * 9/5) + 32).round()}°";
    }
    return "${val.round()}°";
  }

  String _formatPrecip(double val) {
     if (_precipUnit == "inch") {
         return "${(val * 0.0393701).toStringAsFixed(2)}\"";
     }
     return "${val.toStringAsFixed(1)} mm";
  }

  bool _isToday(int index) {
    DateTime date = DateTime.parse(widget.weather.daily.time[index]);
    DateTime now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                     const SizedBox(width: 40), 
                     const Text(
                       "Chi tiết hàng ngày", 
                       style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)
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
  
              // Day Selector
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: widget.weather.daily.time.length,
                  itemBuilder: (context, index) {
                    final dateStr = widget.weather.daily.time[index];
                    final date = DateTime.parse(dateStr);
                    final isSelected = index == _selectedIndex;
                    
                    String dayName = DateFormat('E', 'vi').format(date);
                    // Normalize Vietnamese Dates
                    if (dayName == 'Mon') dayName = 'T2';
                    else if (dayName == 'Tue') dayName = 'T3';
                    else if (dayName == 'Wed') dayName = 'T4';
                    else if (dayName == 'Thu') dayName = 'T5';
                    else if (dayName == 'Fri') dayName = 'T6';
                    else if (dayName == 'Sat') dayName = 'T7';
                    else if (dayName == 'Sun') dayName = 'CN';
                    
                    return GestureDetector(
                      onTap: () => _onDaySelected(index),
                      child: Container(
                        width: 50,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: isSelected ? const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ) : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(dayName, style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white54, 
                              fontWeight: FontWeight.bold,
                              fontSize: 13
                            )),
                            const SizedBox(height: 4),
                            Text(date.day.toString(), style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white, 
                              fontWeight: FontWeight.bold,
                              fontSize: 17
                            )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.weather.daily.time.length,
                  onPageChanged: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  itemBuilder: (context, index) {
                    return _buildPage(index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    final daily = widget.weather.daily;
    final date = DateTime.parse(daily.time[index]);
    final fullDate = "Thứ ${DateFormat('E', 'vi').format(date)}, ngày ${date.day} tháng ${date.month}, ${date.year}"; 
    
    // Hourly Data Slicing
    final actual = _getHourlyData(widget.weather.hourly.temperature2m, index);
    final feels = _getHourlyData(widget.weather.hourly.apparentTemperature, index);
    final probs = _getHourlyIntData(widget.weather.hourly.precipitationProbability, index);
    final codes = _getCodesForDay(index);
    
    // Summary Logic
    double minT = daily.temperature2mMin[index];
    double maxT = daily.temperature2mMax[index];
    
    // Total Rain logic (SUM of hourly precip for that day or daily sum)
    double dailyRainSum = daily.precipitationSum[index];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Center(child: Text(fullDate, style: const TextStyle(color: Colors.grey, fontSize: 14))),
            const SizedBox(height: 10),
            
            // Big Temp Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(_formatTemp(maxT), style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w200)),
                         Text(_formatTemp(minT), style: const TextStyle(color: Colors.white54, fontSize: 30, fontWeight: FontWeight.w300, height: 2.5)),
                       ],
                     ),
                     Text(WeatherUtils.getWeatherDescription(daily.weatherCode[index]), style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
                Icon(WeatherUtils.getWeatherIcon(daily.weatherCode[index]), color: Colors.amber, size: 48),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // 1. Temp Chart
            Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFF1C1C1E),
                 borderRadius: BorderRadius.circular(20),
               ),
               child: Column(
                 children: [
                    // Segmented Control
                    Container(
                        height: 32,
                        decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Expanded(child: _buildSegmentBtn("Thực tế", 0)),
                            Expanded(child: _buildSegmentBtn("Cảm nhận", 1)),
                          ],
                        ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: TempChartPainter(
                          actualData: actual,
                          feelsLikeData: feels,
                          weatherCodes: codes,
                          isFansLikeMode: _chartMode == 1,
                          tempUnit: _tempUnit
                        ),
                      ),
                    )
                 ],
               ),
            ),
            
            const SizedBox(height: 20),
            
            // 2. Rain Chance (Probability)
            const Text("Khả năng có mưa", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("Cao nhất: ${daily.precipitationProbabilityMax[index]}%", style: const TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 10),
            Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFF1C1C1E),
                 borderRadius: BorderRadius.circular(20),
               ),
               child: Column(
                 children: [
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: ProbabilityChartPainter(data: probs),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text("Khả năng có mưa hàng ngày có xu hướng cao hơn khả năng cho mỗi giờ.", style: TextStyle(color: Colors.white30, fontSize: 12)),
                 ],
               ),
            ),
            
            const SizedBox(height: 20),
            
            // 3. Total Rainfall
            const Text("Tổng lượng mưa", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
               padding: const EdgeInsets.all(20),
               decoration: BoxDecoration(
                 color: const Color(0xFF1C1C1E),
                 borderRadius: BorderRadius.circular(20),
               ),
               child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tổng cộng", style: TextStyle(color: Colors.white, fontSize: 16)),
                    Text(_formatPrecip(dailyRainSum), style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
               ),
            ),
            
            const SizedBox(height: 20),
            
            // 4. Daily Summary
             const Text("Tóm tắt hàng ngày", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 10),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFF1C1C1E),
                 borderRadius: BorderRadius.circular(20),
               ),
               child: Text(
                 "Nhiệt độ thấp nhất là ${_formatTemp(minT)}, cao nhất là ${_formatTemp(maxT)}. Tổng lượng mưa dự kiến khoảng ${_formatPrecip(dailyRainSum)}.",
                 style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
               ),
             ),
             
             const SizedBox(height: 20),
             
             // 5. Intro
             const Text("Giới thiệu về Nhiệt độ cảm nhận", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 10),
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFF1C1C1E),
                 borderRadius: BorderRadius.circular(20),
               ),
               child: const Text(
                 "Nhiệt độ cảm nhận biểu thị độ ấm hoặc độ lạnh mà bạn cảm thấy và có thể khác với nhiệt độ thực tế. Nhiệt độ cảm nhận bị ảnh hưởng bởi độ ẩm, ánh nắng và gió.",
                 style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.5),
               ),
             ),
             
             const SizedBox(height: 20),
             
             // 6. Options
             const Text("Tùy chọn", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 10),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               decoration: BoxDecoration(
                 color: const Color(0xFF1C1C1E),
                 borderRadius: BorderRadius.circular(16),
               ),
               child: Column(
                 children: [
                   _buildOptionRow("Nhiệt độ", _tempUnit, ["°C", "°F"], (v) => setState(() => _tempUnit = v)),
                   const Divider(color: Colors.white12, height: 1),
                   _buildOptionRow("Lượng mưa", _precipUnit, ["mm", "inch"], (v) => setState(() => _precipUnit = v)),
                 ],
               ),
             ),
             
             const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSegmentBtn(String title, int value) {
    bool isSelected = _chartMode == value;
    return GestureDetector(
      onTap: () => setState(() => _chartMode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF636366) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
  
  Widget _buildOptionRow(String label, String currentVal, List<String> items, Function(String) onChanged) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
                DropdownButton<String>(
                  value: items.contains(currentVal) ? currentVal : items[0],
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF1C1C1E),
                  icon: const Icon(Icons.unfold_more, color: Colors.grey, size: 20),
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
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

// --- Painters ---

class TempChartPainter extends CustomPainter {
  final List<double> actualData;
  final List<double> feelsLikeData;
  final List<int> weatherCodes;
  final bool isFansLikeMode;
  final String tempUnit;

  TempChartPainter({
    required this.actualData, 
    required this.feelsLikeData, 
    required this.weatherCodes,
    required this.isFansLikeMode,
    required this.tempUnit
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (actualData.isEmpty || feelsLikeData.isEmpty) return;
    
    final paintGrid = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    final paintText = TextPainter(textDirection: ui.TextDirection.ltr);

    List<double> mainData = isFansLikeMode ? feelsLikeData : actualData;
    List<double> secondaryData = isFansLikeMode ? actualData : feelsLikeData;
    
    double minV = [actualData.reduce(min), feelsLikeData.reduce(min)].reduce(min) - 2;
    double maxV = [actualData.reduce(max), feelsLikeData.reduce(max)].reduce(max) + 2;
    double range = maxV - minV;
    if (range < 5) range = 5;

    double bottomH = 30; // Labels
    double topH = 30; // Icons
    double chartH = size.height - bottomH - topH;
    double w = size.width;
    double stepX = w / 24.0;
    
    // Draw Icons (every 3h)
    for (int i=0; i<weatherCodes.length; i+=3) { 
       if (i >= 24) break;
       double x = i * stepX + (stepX/2);
       IconData icon = WeatherUtils.getWeatherIcon(weatherCodes[i]);
       paintText.text = TextSpan(
         text: String.fromCharCode(icon.codePoint),
         style: TextStyle(fontSize: 16, fontFamily: icon.fontFamily, package: icon.fontPackage, color: Colors.white)
       );
       paintText.layout();
       paintText.paint(canvas, Offset(x - paintText.width/2, 0));
    }
    
    double getY(double val) => topH + chartH - ((val - minV) / range * chartH);

    // Secondary Line (Dashed)
    Paint secPaint = Paint()..color = Colors.grey.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round;
    _drawDashedPath(canvas, _buildPath(secondaryData, stepX, getY), secPaint);
    
    // Main Line (Solid + Fill)
    Paint mainPaint = Paint()..color = Colors.orangeAccent..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    Path mainPath = _buildPath(mainData, stepX, getY);
    
    // Fill
    Path fillPath = Path.from(mainPath);
    fillPath.lineTo((mainData.length-1) * stepX + stepX/2, topH + chartH);
    fillPath.lineTo(stepX/2, topH + chartH);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..shader = LinearGradient(colors: [Colors.orange.withOpacity(0.3), Colors.orange.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, topH, w, chartH)));
    canvas.drawPath(mainPath, mainPaint);
    
    // Bottom Labels
    List<int> hours = [0, 6, 12, 18];
    for (int h in hours) {
        double x = h * stepX + stepX/2;
         _drawDashedLine(canvas, Offset(x, topH), Offset(x, topH + chartH), paintGrid);
         paintText.text = TextSpan(text: "${h}h", style: TextStyle(color: Colors.grey[500], fontSize: 10));
         paintText.layout();
         paintText.paint(canvas, Offset(x - paintText.width/2, topH + chartH + 5));
    }
  }
  
  Path _buildPath(List<double> data, double stepX, Function(double) getY) {
      Path path = Path();
      for (int i=0; i<data.length; i++) {
           double x = i * stepX + stepX/2;
           double y = getY(data[i]);
           if (i==0) path.moveTo(x, y);
           else {
               double prevX = (i-1) * stepX + stepX/2;
               double prevY = getY(data[i-1]);
               double cp1x = (prevX + x) / 2;
               path.cubicTo(cp1x, prevY, cp1x, y, x, y);
           }
      }
      return path;
  }
  
  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    var maxDist = (p2 - p1).distance;
    var dash = 4.0;
    var space = 4.0;
    double current = 0;
    while (current < maxDist) {
      canvas.drawLine(p1 + (p2 - p1) * (current / maxDist), p1 + (p2-p1) * ((current+dash)/maxDist), paint);
      current += dash + space;
    }
  }
   void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    ui.PathMetrics pathMetrics = path.computeMetrics();
    for (ui.PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(pathMetric.extractPath(distance, distance + 4), paint);
        distance += 8; 
      }
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
    final paintGrid = Paint()..color = Colors.grey.withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 1;
    final paintBar = Paint()..color = Colors.blueAccent..style = PaintingStyle.fill;
    
    double rightLabel = 35;
    double bottomLabel = 20;
    double chartW = size.width - rightLabel;
    double chartH = size.height - bottomLabel;
    
    for (int i=0; i<=5; i++) {
        int val = i * 20;
        double y = chartH - (val/100.0 * chartH);
        _drawDashedLine(canvas, Offset(0, y), Offset(chartW, y), paintGrid);
        
        TextSpan span = TextSpan(style: TextStyle(color: Colors.grey[500], fontSize: 10), text: "$val%");
        TextPainter tp = TextPainter(text: span, textDirection: ui.TextDirection.ltr)..layout();
        tp.paint(canvas, Offset(chartW + 5, y - 6));
    }
    
    double slotW = chartW / 24.0;
    double barW = slotW * 0.7;
    
    for (int i=0; i<data.length; i++) {
        double h = (data[i] / 100.0) * chartH;
        double x = i * slotW;
        if (h > 0) {
            canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + (slotW-barW)/2, chartH - h, barW, h), const Radius.circular(2)), paintBar);
        }
    }
    
    List<int> hours = [0, 6, 12, 18];
    for (int h in hours) {
         double x = (h / 24.0) * chartW;
         _drawDashedLine(canvas, Offset(x, 0), Offset(x, chartH), paintGrid);
         TextSpan span = TextSpan(style: TextStyle(color: Colors.grey[500], fontSize: 10), text: "${h.toString().padLeft(2, '0')} giờ");
         TextPainter tp = TextPainter(text: span, textDirection: ui.TextDirection.ltr)..layout();
         tp.paint(canvas, Offset(x, chartH + 2));
    }
  }
  
  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    var maxDist = (p2 - p1).distance;
    var dash = 4.0;
    var space = 4.0;
    double current = 0;
    while (current < maxDist) {
      canvas.drawLine(p1 + (p2 - p1) * (current / maxDist), p1 + (p2-p1) * ((current+dash)/maxDist), paint);
      current += dash + space;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


