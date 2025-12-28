import 'package:flutter/material.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'dart:math' as math;

class UVDetailScreen extends StatefulWidget {
  final WeatherData weatherData;

  const UVDetailScreen({super.key, required this.weatherData});

  @override
  State<UVDetailScreen> createState() => _UVDetailScreenState();
}

class _UVDetailScreenState extends State<UVDetailScreen> {
  int _selectedDayIndex = 1;

  @override
  void initState() {
    super.initState();
    if (widget.weatherData.daily.time.length < 2) {
      _selectedDayIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daily = widget.weatherData.daily;
    final hourly = widget.weatherData.hourly;
    final currentUV = widget.weatherData.current.uvIndex;

    // Safety check
    if (_selectedDayIndex >= daily.time.length) _selectedDayIndex = 0;

    // Dates
    final DateTime selectedDate = DateTime.parse(daily.time[_selectedDayIndex]);
    final DateTime now = DateTime.now();
    final DateTime dateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final DateTime todayOnly = DateTime(now.year, now.month, now.day);
    final DateTime yesterdayOnly = todayOnly.subtract(const Duration(days: 1));

    bool isToday = dateOnly.isAtSameMomentAs(todayOnly);
    bool isYesterday = dateOnly.isAtSameMomentAs(yesterdayOnly);

    // Data Extraction
    List<double> dayHourlyUV = [];
    for(int i=0; i<hourly.time.length; i++) {
        DateTime t = DateTime.parse(hourly.time[i]);
        if (t.year == selectedDate.year && t.month == selectedDate.month && t.day == selectedDate.day) {
             dayHourlyUV.add(hourly.uvIndex[i]);
        }
    }
    if (dayHourlyUV.isEmpty) dayHourlyUV = List.filled(24, 0.0);

    // Display Values
    double displayValue = isToday ? currentUV : daily.uvIndexMax[_selectedDayIndex];
    String description = _getUVDescription(displayValue);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text("Chỉ số UV", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // 1. Day Selector (Premium style)
             const SizedBox(height: 10),
             _buildPremiumDaySelector(daily.time),
             
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 10),
               child: Divider(color: Colors.white12, height: 1),
             ),

             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 20),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                     // 2. Date Label
                     Center(
                         child: Text(
                             DateFormat("EEEE, 'ngày' d 'tháng' M", 'vi').format(selectedDate),
                             style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)
                         )
                     ),
                     const SizedBox(height: 5),
                     
                     // 3. Hero Value
                     Center(
                       child: Column(
                         children: [
                           Text("${displayValue.round()}", style: const TextStyle(color: Colors.white, fontSize: 96, fontWeight: FontWeight.w200, height: 1.0)),
                           Text(description, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
                         ],
                       )
                     ),
                     const SizedBox(height: 10),
                     const Center(child: Text("UVI Tổ chức Y tế Thế giới", style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.w500))),
                     
                     const SizedBox(height: 40),
                     
                     // 4. Chart Card (iPhone-like container)
                     Container(
                         height: 320,
                         padding: const EdgeInsets.fromLTRB(10, 25, 15, 10),
                         decoration: BoxDecoration(
                             color: const Color(0xFF1C1C1E),
                             borderRadius: BorderRadius.circular(25),
                             border: Border.all(color: Colors.white.withOpacity(0.05))
                         ),
                         child: Column(
                             children: [
                                 Expanded(
                                     child: CustomPaint(
                                         painter: UVChartPainter(
                                             uvData: dayHourlyUV,
                                             isToday: isToday
                                         ),
                                         size: Size.infinite,
                                     )
                                 )
                             ],
                         ),
                     ),
                     
                     const SizedBox(height: 30),
                     
                     // 5. Summary Text
                     Text(
                        _getDateTitleForSummary(isToday, isYesterday, selectedDate),
                        style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)
                     ),
                     const SizedBox(height: 10),
                     Text(
                        _generateSummaryBody(isToday, isYesterday, displayValue, dayHourlyUV),
                        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5, fontWeight: FontWeight.w400)
                     ),
                     
                     const SizedBox(height: 40),
                     
                     // 6. Comparison Card
                     if (isToday && _selectedDayIndex > 0)
                        _buildComparisonCard(daily),
                     
                     const SizedBox(height: 40),
                     
                     // 7. About Section
                     const Text("Giới thiệu về Chỉ số UV", style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
                     const SizedBox(height: 15),
                     Container(
                         padding: const EdgeInsets.all(20),
                         decoration: BoxDecoration(
                             color: const Color(0xFF1C1C1E), 
                             borderRadius: BorderRadius.circular(20),
                             border: Border.all(color: Colors.white.withOpacity(0.05))
                         ),
                         child: const Text(
                             "Chỉ số UV (UVI) của Tổ chức Y tế Thế giới đo mức bức xạ cực tím. UVI càng cao thì khả năng gây hại càng lớn và tốc độ xảy ra tổn thương có thể càng nhanh.\n\nUVI có thể giúp bạn quyết định khi nào cần tự bảo vệ khỏi ánh nắng mặt trời và khi nào cần tránh ra ngoài trời. WHO khuyến cáo sử dụng vật che chắn, kem chống nắng, nón và quần áo bảo vệ ở mức 3 (Trung bình) trở lên.",
                             style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
                         )
                     ),
                     const SizedBox(height: 50),
                 ],
               ),
             )
          ],
        ),
      ),
    );
  }

  // --- Helpers & Widgets ---

  String _getUVDescription(double uv) {
      if (uv < 3) return "Thấp";
      if (uv < 6) return "Trung bình";
      if (uv < 8) return "Cao";
      if (uv < 11) return "Rất cao";
      return "Cực đoan";
  }

  String _getDateTitleForSummary(bool isToday, bool isYesterday, DateTime date) {
      if (isToday) {
          return "Bây giờ, ${DateFormat('HH:mm').format(DateTime.now())}";
      }
      return DateFormat("d 'thg' M, yyyy", 'vi').format(date);
  }

  String _generateSummaryBody(bool isToday, bool isYesterday, double displayValue, List<double> hourlyUV) {
      if (isYesterday) {
          return "Hôm qua, chỉ số UV cao nhất là ${displayValue.round()}.";
      }
      
      int startHour = -1;
      int endHour = -1;
      for(int i=0; i<hourlyUV.length; i++) {
          if (hourlyUV[i] >= 3) {
              if (startHour == -1) startHour = i;
              endHour = i;
          }
      }
      if (endHour != -1) endHour += 1;

      String rangeText = "";
      if (startHour != -1 && endHour != -1) {
          rangeText = "từ ${startHour.toString().padLeft(2,'0')}:00 đến ${endHour.toString().padLeft(2,'0')}:00";
      }

      if (isToday) {
           String currentDesc = _getUVDescription(displayValue).toLowerCase();
           String suffix = rangeText.isNotEmpty 
               ? "Đạt tới các mức trung bình hoặc cao hơn $rangeText."
               : "Chỉ số thấp trong suốt cả ngày.";
           return "Hiện tại ở mức $currentDesc. $suffix";
      } else {
           return rangeText.isNotEmpty 
               ? "Nên sử dụng biện pháp chống nắng $rangeText."
               : "Chỉ số UV dự báo sẽ thấp trong cả ngày.";
      }
  }

  Widget _buildPremiumDaySelector(List<String> times) {
      return SizedBox(
           height: 70,
           child: ListView.builder(
             physics: const BouncingScrollPhysics(),
             scrollDirection: Axis.horizontal,
             itemCount: times.length,
             padding: const EdgeInsets.symmetric(horizontal: 16),
             itemBuilder: (context, index) {
               final date = DateTime.parse(times[index]);
               final isSelected = _selectedDayIndex == index;
               return GestureDetector(
                 onTap: () => setState(() => _selectedDayIndex = index),
                 child: AnimatedContainer(
                   duration: const Duration(milliseconds: 200),
                   width: 60,
                   margin: const EdgeInsets.only(right: 8),
                   decoration: BoxDecoration(
                     color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
                     borderRadius: BorderRadius.circular(30),
                     border: isSelected ? null : Border.all(color: Colors.white12),
                   ),
                   child: Column(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Text(
                         DateFormat('E', 'vi').format(date).toUpperCase(), 
                         style: TextStyle(
                           color: isSelected ? Colors.black : Colors.white54, 
                           fontSize: 11, 
                           fontWeight: FontWeight.bold
                         )
                       ),
                       const SizedBox(height: 4),
                       Text(
                         DateFormat('d').format(date), 
                         style: TextStyle(
                           color: isSelected ? Colors.black : Colors.white, 
                           fontWeight: FontWeight.w600, 
                           fontSize: 18
                         )
                       ),
                     ],
                   ),
                 ),
               );
             },
           ),
      );
  }

  Widget _buildComparisonCard(DailyWeather daily) {
      int prevIndex = _selectedDayIndex - 1;
      if (prevIndex < 0) return const SizedBox();
      
      double currMax = daily.uvIndexMax[_selectedDayIndex];
      double prevMax = daily.uvIndexMax[prevIndex];
      
      String diffText;
      if (currMax > prevMax) {
          diffText = "Chỉ số UV cao nhất hôm nay cao hơn hôm qua.";
      } else if (currMax < prevMax) {
          diffText = "Chỉ số UV cao nhất hôm nay thấp hơn hôm qua.";
      } else {
          diffText = "Chỉ số UV cao nhất hôm nay tương tự hôm qua.";
      }
      
      return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              const Text("So sánh hàng ngày", style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w600)),
              const SizedBox(height: 15),
              Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E), 
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05))
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(diffText, style: const TextStyle(color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 25),
                          _buildComparisonBar("Hôm nay", currMax, true),
                          const SizedBox(height: 20),
                          _buildComparisonBar("Hôm qua", prevMax, false),
                      ]
                  )
              )
          ]
      );
  }
  
  Widget _buildComparisonBar(String label, double val, bool highlight) {
      return Row(
          children: [
              SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16))),
              Expanded(
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                          widthFactor: (val / 12).clamp(0.0, 1.0),
                          child: Container(
                              decoration: BoxDecoration(
                                  // Gradient for active bar, Grey for comparison
                                  gradient: highlight 
                                      ? const LinearGradient(colors: [Colors.green, Colors.yellow, Colors.orange, Colors.red])
                                      : null,
                                  color: highlight ? null : Colors.grey[700],
                                  borderRadius: BorderRadius.circular(3)
                              )
                          )
                      ),
                    ),
                  )
              ),
              const SizedBox(width: 15),
              SizedBox(width: 30, child: Text("${val.round()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18), textAlign: TextAlign.right))
          ]
      );
  }
}

// --- Chart Painter (Smoothed) ---
// --- Chart Painter (Refined to match iOS) ---
class UVChartPainter extends CustomPainter {
    final List<double> uvData;
    final bool isToday;

    UVChartPainter({required this.uvData, required this.isToday});

    @override
    void paint(Canvas canvas, Size size) {
        // Dimensions
        final double topPadding = 20;
        final double bottomPadding = 20;
        final double leftPadding = 50;  // Room for text levels (Thấp, TB...)
        final double rightPadding = 30; // Room for numbers (0..11)
        final double w = size.width - leftPadding - rightPadding;
        final double h = size.height - topPadding - bottomPadding;
        final double maxY = 12.0;

        // Paints
        final paintGrid = Paint()
            ..color = Colors.grey.withOpacity(0.2)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;

        final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

        // 1. Horizontal Grid Lines & Labels
        // Levels corresponding to UV categories: 0..2 (Low), 3..5 (Mod), 6..7 (High), 8..10 (Very High), 11+ (Extreme)
        // We will draw grid lines at integer steps but label specific zones like image.
        // Image shows lines at roughly 0, 2.5, 5, 7.5, 10... or just evenly spaced.
        // Let's use evenly spaced integer lines? The image has specific labels "Cực đoan", "Rất cao"...
        // Let's map Y-axis to 0-11 range roughly.
        
        List<Map<String, dynamic>> zones = [
            {'val': 0.0, 'label': 'Thấp'},
            {'val': 3.0, 'label': 'Trung bình'},
            {'val': 6.0, 'label': 'Cao'},
            {'val': 8.0, 'label': 'Rất cao'},
            {'val': 11.0, 'label': 'Cực đoan'},
        ];

        // Draw horizontal dashed lines for these zones
        for (var z in zones) {
            double val = z['val'] as double;
            double y = topPadding + h - (val / maxY) * h;
            
            // Grid line
            _drawDashedLine(canvas, Offset(leftPadding, y), Offset(leftPadding + w, y), paintGrid);

            // Left Label (Text)
            textPainter.text = TextSpan(
                text: z['label'] as String,
                style: TextStyle(color: Colors.grey[400], fontSize: 13, fontWeight: FontWeight.bold)
            );
            textPainter.layout();
            textPainter.paint(canvas, Offset(0, y - textPainter.height - 2)); // Positioned above line

            // Right Label (Number)
            // We draw numbers 0, 1, 2... 11 on the right axis
        }
        
        // Right numeric axis (1, 2, 3... 11)
        for (int i = 0; i <= 11; i++) {
             double y = topPadding + h - (i / maxY) * h;
             textPainter.text = TextSpan(
                text: "$i",
                style: TextStyle(color: Colors.grey[500], fontSize: 12)
             );
             textPainter.layout();
             textPainter.paint(canvas, Offset(size.width - rightPadding + 8, y - textPainter.height/2));
        }

        // 2. Vertical Grid & Time Labels (00, 06, 12, 18)
        List<int> timeMarks = [0, 6, 12, 18];
        double stepX = w / 24.0;
        
        for (int hr in timeMarks) {
            double x = leftPadding + hr * stepX + stepX/2;
            
            // Vertical line
            _drawDashedLine(canvas, Offset(x, topPadding), Offset(x, topPadding + h), paintGrid);
            
            // X Label
            textPainter.text = TextSpan(
                text: "${hr.toString().padLeft(2, '0')} giờ",
                style: TextStyle(color: Colors.grey[500], fontSize: 12)
            );
            textPainter.layout();
            textPainter.paint(canvas, Offset(x - textPainter.width/2, size.height - 15));
        }
        
        // 3. Top Labels (Values at top)
        // Draw UV value at the top for every 2 hours or so? Image shows many.
        // Let's draw every 2 hours to avoid clutter, or aligned with grid if image has many 0 0 0.
        // Image seems to have one for every visible data point interval possibly?
        // Let's try every 3 hours: 0, 3, 6, 9, 12... to match clutter.
        // Code iterates data.
        for (int i=0; i<uvData.length; i++) {
             if (i % 3 != 0 && i != uvData.length-1) continue; // Skip some for readability? Or show all if dense?
             // Actually image shows 0 0 0 0 4 8 6 3 ... nicely spaced.
             // Let's show all but check overlap? 24 numbers might fit.
             
             if (i >= 24) break;
             double x = leftPadding + i * stepX + stepX/2;
             double val = uvData[i];
             
             // Only draw if significant or sparse intervals? 
             // Let's draw every 2nd or 3rd to match spacing in image which has about 10-12 numbers.
             // 24/2 = 12. Every 2 hours.
             if (i % 2 == 0) {
                 textPainter.text = TextSpan(
                    text: "${val.round()}",
                    style: TextStyle(color: Colors.grey[400], fontSize: 14) // Slightly larger
                 );
                 textPainter.layout();
                 textPainter.paint(canvas, Offset(x - textPainter.width/2, 0));
             }
        }

        if (uvData.isEmpty) return;

        // 4. Draw Curve
        Path path = Path();
        
        // We will simple cubic smoothing
        for (int i = 0; i < uvData.length; i++) {
            if (i >= 24) break;
            double val = uvData[i];
            double x = leftPadding + i * stepX + stepX/2;
            double y = topPadding + h - (val / maxY) * h;
            
            if (i == 0) {
                path.moveTo(x, y);
            } else {
                double prevX = leftPadding + (i - 1) * stepX + stepX/2;
                double prevY = topPadding + h - (uvData[i-1] / maxY) * h;
                double cpX = (prevX + x) / 2;
                path.cubicTo(cpX, prevY, cpX, y, x, y);
            }
        }

        // Fill Path
        Path fillPath = Path.from(path);
        fillPath.lineTo(leftPadding + (uvData.length > 24 ? 23 : uvData.length-1) * stepX + stepX/2, topPadding + h);
        fillPath.lineTo(leftPadding + stepX/2, topPadding + h);
        fillPath.close();

        // 5. Gradient Fill
        // UV Colors: Low(Green) -> Mod(Yellow) -> High(Orange) -> Very(Red) -> Ext(Purple)
        var gradientColors = [Colors.green, Colors.yellow, Colors.orange, Colors.red, Colors.deepPurple];
        var stops = [0.0, 3/12.0, 6/12.0, 8/12.0, 11/12.0];
        
        // Shader needs to map vertical axis 0->12
        final fillGradient = ui.Gradient.linear(
             Offset(0, topPadding + h), // Bottom (0 UV)
             Offset(0, topPadding),     // Top (12 UV)
             gradientColors,
             stops
        );

        canvas.drawPath(fillPath, Paint()..shader = fillGradient..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3)); // Slight blur for smooth look

        // 6. Dashed Stroke
        Paint strokePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round
            ..shader = fillGradient; // Use same gradient for stroke

        _drawDashedPath(canvas, path, strokePaint);
        
        // 7. Current Marker
        if (isToday) {
             DateTime now = DateTime.now();
             double fraction = (now.hour + now.minute/60.0) / 23.0; // 0..1
             // Map to pixels
             // Current hour index
             int hr = now.hour;
             if(hr < 24) {
                 double min = now.minute.toDouble();
                 // Interpolate Y
                 double u1 = (hr < uvData.length) ? uvData[hr] : 0;
                 double u2 = (hr+1 < uvData.length) ? uvData[hr+1] : u1;
                 double curVal = u1 + (u2 - u1)*(min/60.0);
                 
                 double cx = leftPadding + (hr * stepX + stepX/2) + (stepX * min/60.0);
                 // Center align correction? stepX represents 1 hour width. 
                 // Actually grid is centered on hr mark? 
                 // Code above: x = left + i*stepX + stepX/2. This means i=0 is at 0.5 stepX.
                 // So 00:00 is at 0.5 stepX. 01:00 is at 1.5 stepX.
                 // So formula: left + (timeInHours * stepX) + stepX/2
                 double timeInHours = hr + min/60.0;
                 cx = leftPadding + timeInHours * stepX + stepX/2;
                 
                 double cy = topPadding + h - (curVal / maxY) * h;
                 
                 // White dot with shadow black rim
                 canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = Colors.white);
                 canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = Colors.black.withOpacity(0.2)..style=PaintingStyle.stroke..strokeWidth=1);
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
  
    void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
        ui.PathMetrics pathMetrics = path.computeMetrics();
        for (ui.PathMetric pathMetric in pathMetrics) {
            double distance = 0.0;
            while (distance < pathMetric.length) {
                canvas.drawPath(
                    pathMetric.extractPath(distance, distance + 8),
                    paint,
                );
                distance += 12; 
            }
        }
    }

    @override
    bool shouldRepaint(UVChartPainter oldDelegate) => true;
}
