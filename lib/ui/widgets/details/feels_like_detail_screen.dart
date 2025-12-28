import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/utils/enums.dart'; // Ensure MetricType/etc if needed
import 'package:flutter_1/ui/widgets/details/rainfall_detail_screen.dart'; // Reuse painters if needed

class FeelsLikeDetailScreen extends StatefulWidget {
  final WeatherData weatherData;
  final int initialDayIndex; // 0 for today

  const FeelsLikeDetailScreen({
    super.key,
    required this.weatherData,
    this.initialDayIndex = 0,
  });

  @override
  State<FeelsLikeDetailScreen> createState() => _FeelsLikeDetailScreenState();
}

class _FeelsLikeDetailScreenState extends State<FeelsLikeDetailScreen> {
  int _selectedDayIndex = 0;
  late List<DateTime> _days;
  
  // Options
  String _tempUnit = "°C"; // °C, °F
  String _precipUnit = "mm"; // mm, inch
  
  // Chart Toggle
  int _chartMode = 1; // 0: Thực tế, 1: Cảm nhận (Default as per title)

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
    _days = widget.weatherData.daily.time.map((d) => DateTime.parse(d)).toList();
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Helper getters
  List<double> _getHourlyTempForDay(DateTime date, bool feelsLike) {
    List<double> result = [];
    List<String> hours = widget.weatherData.hourly.time;
    List<double> values = feelsLike 
        ? widget.weatherData.hourly.apparentTemperature
        : widget.weatherData.hourly.temperature2m;

    for (int i = 0; i < hours.length; i++) {
        DateTime t = DateTime.parse(hours[i]);
        if (t.year == date.year && t.month == date.month && t.day == date.day) {
            result.add(values[i]);
        }
    }
    return result;
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

  double _getPast24hRainfall() {
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

  @override
  Widget build(BuildContext context) {
    DateTime selectedDate = _days[_selectedDayIndex];
    
    // 1. Restore Variable Definitions
    // Data for charts
    List<double> actualHourly = _getHourlyTempForDay(selectedDate, false);
    List<double> feelsLikeHourly = _getHourlyTempForDay(selectedDate, true);
    
    // We also need probChartData for the Rain Probability section which was broken
    List<int> probChartData = _getHourlyProbForDay(selectedDate);
    
    // Get Weather Codes for Icons
    List<int> weatherCodes = [];
    List<String> hours = widget.weatherData.hourly.time;
    List<int> wCodes = widget.weatherData.hourly.weatherCode;
    for (int i=0; i<hours.length; i++) {
        DateTime t = DateTime.parse(hours[i]);
        if (t.year == selectedDate.year && t.month == selectedDate.month && t.day == selectedDate.day) {
            weatherCodes.add(wCodes[i]);
        }
    }
    
    // Values for comparisons (Restored)
    double todayMax = widget.weatherData.daily.temperature2mMax[_selectedDayIndex];
    double todayMin = widget.weatherData.daily.temperature2mMin[_selectedDayIndex];
    // Yesterday for comparison
    double? yestMax, yestMin;
    bool hasYest = false;
    if (_selectedDayIndex > 0) {
        yestMax = widget.weatherData.daily.temperature2mMax[_selectedDayIndex - 1];
        yestMin = widget.weatherData.daily.temperature2mMin[_selectedDayIndex - 1];
        hasYest = true;
    }

    // Finding Display Temp (Current Hour if Today, else Max)
    double mainDisplayTemp = 0;
    
    if (_isToday(selectedDate)) {
       // Find current hour index
       int currentHour = DateTime.now().hour;
       // API hours are usually full list. We need to match hour.
       // Or simpler: access current weather from 'widget.weatherData.current' directly?
       // But wait, the chart toggle switches between Actual/FeelsLike. 
       // 'current' model has both.
       if (_chartMode == 1) {
           mainDisplayTemp = widget.weatherData.current.apparentTemperature;
       } else {
           mainDisplayTemp = widget.weatherData.current.temperature2m;
       }
    } else {
       // Future/Past days: Show Max or Mid-day?
       // Usually Max is a good summary for a whole day view.
       List<double> activeData = _chartMode == 1 ? feelsLikeHourly : actualHourly;
       if (activeData.isNotEmpty) mainDisplayTemp = activeData.reduce(max);
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
                       Icon(Icons.thermostat, color: Colors.white, size: 16), 
                       SizedBox(width: 8),
                       Text("Nhiệt độ cảm nhận", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
             // Date Selector (Reuse logic, duplicate code for speed)
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
                       // MAIN TEMP DISPLAY
                       Row(
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                           Text(_formatTemp(mainDisplayTemp), style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w400)),
                           const SizedBox(width: 8),
                           Padding(
                             padding: const EdgeInsets.only(bottom: 12),
                             child: Icon(_getWeatherIcon(widget.weatherData.current.weatherCode), color: Colors.white, size: 32),
                           ),
                         ],
                       ),
                       // Subtext 
                       Text(
                         _chartMode == 1 
                           ? "Thực tế: ${_formatTemp(_isToday(selectedDate) ? widget.weatherData.current.temperature2m : (actualHourly.isNotEmpty ? actualHourly.reduce(max) : 0))}"
                           : "Cảm nhận: ${_formatTemp(_isToday(selectedDate) ? widget.weatherData.current.apparentTemperature : (feelsLikeHourly.isNotEmpty ? feelsLikeHourly.reduce(max) : 0))}",
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                       ),
                       
                       const SizedBox(height: 24),
                       
                       // CHART & TOGGLE
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Column(
                           children: [
                             // Custom Paint Chart
                             SizedBox(
                               height: 250, 
                               width: double.infinity,
                               child: CustomPaint(
                                 painter: TempChartPainter(
                                   actualData: actualHourly,
                                   feelsLikeData: feelsLikeHourly,
                                   weatherCodes: weatherCodes,
                                   isFansLikeMode: _chartMode == 1,
                                   unit: _tempUnit
                                 ),
                               ),
                             ),
                             const SizedBox(height: 16),
                             // Segmented Control
                             Container(
                               width: double.infinity,
                               padding: const EdgeInsets.all(2),
                               decoration: BoxDecoration(
                                 color: Colors.grey[800],
                                 borderRadius: BorderRadius.circular(8),
                               ),
                               child: Row(
                                 children: [
                                   Expanded(child: _buildSegmentBtn("Thực tế", 0)),
                                   Expanded(child: _buildSegmentBtn("Cảm nhận", 1)),
                                 ],
                               ),
                             ),
                             const SizedBox(height: 12),
                             Text(
                               "Cảm nhận về nhiệt độ, do độ ẩm, ánh nắng hoặc gió gây ra.",
                               textAlign: TextAlign.center,
                               style: TextStyle(color: Colors.grey[500], fontSize: 12),
                             )
                           ],
                         ),
                       ),
                       
                       const SizedBox(height: 32),
                       
                       // RAIN CHANCE CHART
                       const Text("Khả năng có mưa", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 4),
                        Text(
                        "Khả năng có mưa vào ${_isToday(selectedDate) ? "hôm nay" : DateFormat('EEEE', 'vi').format(selectedDate)}: ${probChartData.isNotEmpty ? probChartData.reduce(max) : 0}%",
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
                          painter: ProbabilityChartPainter(data: probChartData), // Reused!
                        ),
                      ),
                       const SizedBox(height: 8),
                       Text("Khả năng có mưa hàng ngày có xu hướng cao hơn khả năng cho mỗi giờ.", style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                       
                       const SizedBox(height: 32),
                       
                       // TOTAL RAINFALL
                       const Text("Tổng lượng mưa", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                        Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                              children: [
                                _buildStatRow("24 GIỜ QUA", "Lượng mưa", _getPast24hRainfall()),
                                const Divider(color: Colors.white12, height: 24),
                                _buildStatRow("24 GIỜ TỚI", "Lượng mưa", _getNext24hRainfall()),
                              ],
                            ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // FORECAST SUMMARY
                       const Text("Dự báo", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(16),
                         width: double.infinity,
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Text(
                           _buildForecastText(),
                           style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                         ),
                       ),
                       
                       const SizedBox(height: 32),
                       
                       // DAILY COMPARISON (Improved UI)
                       const Text("So sánh hàng ngày", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             if (hasYest)
                                Text("Nhiệt độ cao nhất hôm nay ${todayMax > yestMax! ? "cao hơn" : (todayMax < yestMax ? "thấp hơn" : "tương tự như")} hôm qua.", 
                                    style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4)),
                             
                             if (hasYest) ...[
                                const SizedBox(height: 16),
                                const Divider(color: Colors.white12, height: 1),
                                const SizedBox(height: 16),
                                
                                Builder(
                                  builder: (context) {
                                      // Calculate Global Range
                                      double gMin = min(todayMin, yestMin!);
                                      double gMax = max(todayMax, yestMax!);
                                      double span = gMax - gMin;
                                      if (span < 10) span = 10;
                                      double visibleMin = gMin - (span * 0.1);
                                      double visibleMax = gMax + (span * 0.1);
                                      
                                      return Column(
                                          children: [
                                              _buildComparisonRow(
                                                  "Hôm nay", 
                                                  todayMin, 
                                                  todayMax, 
                                                  visibleMin, 
                                                  visibleMax, 
                                                  true,
                                                  currentVal: _isToday(selectedDate) ? widget.weatherData.current.temperature2m : null
                                              ),
                                              const SizedBox(height: 12),
                                              _buildComparisonRow(
                                                  "Hôm qua", 
                                                  yestMin!, 
                                                  yestMax!, 
                                                  visibleMin, 
                                                  visibleMax, 
                                                  false
                                              ),
                                          ],
                                      );
                                  }
                                )
                             ],
                             if (!hasYest)
                               const Text("Không có dữ liệu hôm qua để so sánh.", style: TextStyle(color: Colors.grey)),
                           ],
                         ),
                       ),
                       
                       const SizedBox(height: 32),
                       
                       // INTRO
                       const Text("Giới thiệu về Nhiệt độ cảm nhận", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(16),
                         width: double.infinity,
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: const Text(
                           "Nhiệt độ cảm nhận biểu thị độ ấm hoặc độ lạnh mà bạn cảm thấy và có thể khác với nhiệt độ thực tế. Nhiệt độ cảm nhận bị ảnh hưởng bởi độ ẩm, ánh nắng và gió.",
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
                             _buildOptionRow("Nhiệt độ", _tempUnit, ["°C", "°F"], (val) => setState(() => _tempUnit = val)),
                             const Divider(color: Colors.white12, height: 1),
                             _buildOptionRow("Lượng mưa", _precipUnit, ["mm", "inch"], (val) => setState(() => _precipUnit = val)),
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

  Widget _buildSegmentBtn(String title, int value) {
    bool isSelected = _chartMode == value;
    return GestureDetector(
      onTap: () => setState(() => _chartMode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[600] : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
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
        Text(_formatPrecip(value), style: TextStyle(color: Colors.grey[400], fontSize: 16)),
      ],
    );
  }
  
  Widget _buildComparisonRow(String label, double min, double max, double visibleMin, double visibleMax, bool isToday, {double? currentVal}) {
      double totalRange = visibleMax - visibleMin;
      if (totalRange <= 0) totalRange = 1;
      
      // Calculate Percentages
      double startPct = (min - visibleMin) / totalRange;
      double lengthPct = (max - min) / totalRange;
      
      // Clamping
      if (startPct < 0) startPct = 0;
      if ((startPct + lengthPct) > 1) lengthPct = 1 - startPct;
      
      return Row(
          children: [
              SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))),
              SizedBox(
                  width: 35, 
                  child: Text("${min.round()}°", textAlign: TextAlign.right, style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w500))
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                        double w = constraints.maxWidth;
                        double left = w * startPct;
                        double barW = w * lengthPct;
                        if (barW < 4) barW = 4;
                        
                        // Dot position
                        double? dotLeft;
                        if (currentVal != null) {
                            double dotPct = (currentVal - visibleMin) / totalRange;
                            if (dotPct >= startPct && dotPct <= (startPct + lengthPct)) { 
                                dotLeft = w * dotPct;
                            } else {
                                if (dotPct < 0) dotLeft = 0;
                                else if (dotPct > 1) dotLeft = w;
                                else dotLeft = w * dotPct;
                            }
                        }

                        return SizedBox(
                            height: 6, // Slightly taller
                            child: Stack(
                                alignment: Alignment.centerLeft,
                                clipBehavior: Clip.none,
                                children: [
                                    // Track Background
                                    Container(
                                        decoration: BoxDecoration(
                                            color: Colors.grey[850], // Darker track
                                            borderRadius: BorderRadius.circular(3)
                                        )
                                    ),
                                    // Colored Bar
                                    Positioned(
                                        left: left,
                                        width: barW,
                                        height: 6,
                                        child: Container(
                                            decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(3),
                                                gradient: LinearGradient(
                                                    colors: [
                                                        const Color(0xFFDCA94D), 
                                                        isToday ? const Color(0xFFFF9F0A) : const Color(0xFFFF9F0A).withOpacity(0.8),
                                                    ]
                                                )
                                            )
                                        )
                                    ),
                                    // Current Dot
                                    if (dotLeft != null)
                                        Positioned(
                                            left: dotLeft - 4,
                                            top: -1, 
                                            child: Container(
                                                width: 8, height: 8,
                                                decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(color: Colors.black, width: 1.5),
                                                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))]
                                                ),
                                            )
                                        )
                                ]
                            )
                        );
                    }
                  )
              ),
              const SizedBox(width: 12),
              SizedBox(
                  width: 35, 
                  child: Text("${max.round()}°", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500))
              ),
          ],
      );
  }

  Widget _buildOptionRow(String label, String currentVal, List<String> items, Function(String) onChanged) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
                DropdownButton<String>(
                  value: items.contains(currentVal) ? currentVal : items[0], // Safety
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
  
  String _buildForecastText() {
      // Dynamic logic
      double currentT = widget.weatherData.current.temperature2m;
      double currentFL = widget.weatherData.current.apparentTemperature;
      String comparison = "";
      if (currentFL > currentT) comparison = "ấm hơn";
      else if (currentFL < currentT) comparison = "lạnh hơn";
      else comparison = "giống như";
      
      return "Bây giờ: ${_formatTemp(currentT)} và ${_getWeatherDesc(widget.weatherData.current.weatherCode)}. Cảm giác $comparison, khoảng ${_formatTemp(currentFL)}. Dự báo trong ngày có mây vài nơi.";
  }

  IconData _getWeatherIcon(int code) {
     if (code < 3) return CupertinoIcons.sun_max_fill;
     if (code < 50) return CupertinoIcons.cloud_fill;
     if (code < 70) return CupertinoIcons.cloud_rain_fill;
     return CupertinoIcons.cloud_bolt_fill;
  }
  
   String _getWeatherDesc(int code) {
     if (code == 0) return "nắng";
     if (code < 3) return "có mây";
     if (code < 50) return "sương mù";
     if (code < 60) return "mưa phùn";
     if (code < 80) return "mưa";
     return "bão";
  }
}

class TempChartPainter extends CustomPainter {
  final List<double> actualData;
  final List<double> feelsLikeData;
  final List<int> weatherCodes;
  final bool isFansLikeMode; // true = Cảm nhận selected
  final String unit;

  TempChartPainter({
    required this.actualData, 
    required this.feelsLikeData, 
    required this.weatherCodes,
    required this.isFansLikeMode, 
    required this.unit
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (actualData.isEmpty || feelsLikeData.isEmpty) return;
    
    final paintGrid = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    final paintText = TextPainter(textDirection: ui.TextDirection.ltr);

    // Prepare data
    List<double> mainData = isFansLikeMode ? feelsLikeData : actualData;
    List<double> secondaryData = isFansLikeMode ? actualData : feelsLikeData;
    
    // Bounds (global for both to align)
    double minV = [actualData.reduce(min), feelsLikeData.reduce(min)].reduce(min) - 2;
    double maxV = [actualData.reduce(max), feelsLikeData.reduce(max)].reduce(max) + 2;
    double range = maxV - minV;
    if (range < 5) range = 5;

    double bottomH = 20;
    double topH = 30; // space for icons
    double chartH = size.height - bottomH - topH;
    double w = size.width;
    double stepX = w / 24.0;
    
    // Draw Weather Icons
    for (int i=0; i<weatherCodes.length; i+=3) { // every 3 hours
       if (i >= 24) break;
       double x = i * stepX + (stepX/2);
       IconData icon = _getIcon(weatherCodes[i]);
       paintText.text = TextSpan(
         text: String.fromCharCode(icon.codePoint),
         style: TextStyle(fontSize: 14, fontFamily: icon.fontFamily, package: icon.fontPackage, color: Colors.white)
       );
       paintText.layout();
       paintText.paint(canvas, Offset(x - paintText.width/2, 0));
    }
    
    // Draw Grid (Horizontal)
    // We want nice steps? Just 3-4 lines
    for (int i=0; i<4; i++) {
        double y = topH + (i/3)*chartH;
        _drawDashedLine(canvas, Offset(0, y), Offset(w, y), paintGrid);
    }

    // Function to get Y
    double getY(double val) => topH + chartH - ((val - minV) / range * chartH);

    // Draw Secondary Line (Dashed)
    Paint secPaint = Paint()
      ..color = Colors.grey.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
      
    Path secPath = _buildPath(secondaryData, stepX, getY);
    _drawDashedPath(canvas, secPath, secPaint);
    
    // Draw Main Line (Solid + Fill)
    Paint mainPaint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    
    Path mainPath = _buildPath(mainData, stepX, getY);
    
    // Fill
    Path fillPath = Path.from(mainPath);
    fillPath.lineTo((mainData.length-1 < 24 ? mainData.length-1 : 23) * stepX + stepX/2, topH + chartH);
    fillPath.lineTo(stepX/2, topH + chartH);
    fillPath.close();
    
    Paint fillPaint = Paint()
      ..shader = LinearGradient(
         colors: [Colors.orange.withOpacity(0.4), Colors.orange.withOpacity(0.0)],
         begin: Alignment.topCenter,
         end: Alignment.bottomCenter
      ).createShader(Rect.fromLTWH(0, topH, w, chartH));
      
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(mainPath, mainPaint);
    
    // Draw Dot labels on peaks (Approx logic)
    // Label "C" on FeelsLike, "T" on Actual
    // We place them at a clearly distinct point, e.g., the max value point?
    int maxIdxMain = _findMaxIndex(mainData);
    int maxIdxSec = _findMaxIndex(secondaryData);
    
    _drawLabelOnPoint(canvas, isFansLikeMode ? "C" : "T", maxIdxMain, mainData[maxIdxMain], stepX, getY, true);
    // Draw sec label only if indices are far enough to not overlap, or just shifted?
    if ((maxIdxMain - maxIdxSec).abs() > 3) {
         _drawLabelOnPoint(canvas, isFansLikeMode ? "T" : "C", maxIdxSec, secondaryData[maxIdxSec], stepX, getY, false);
    } else {
        // Shift index for visibility if colliding? 
        // fallback: 12h mark
         _drawLabelOnPoint(canvas, isFansLikeMode ? "T" : "C", 12, secondaryData[12], stepX, getY, false);
    }
    
    // Draw Bottom Labels (00 giờ...)
    TextStyle labelStyle = TextStyle(color: Colors.grey[500], fontSize: 10);
    List<int> hours = [0, 6, 12, 18];
    for (int h in hours) {
        double x = h * stepX + stepX/2;
         _drawDashedLine(canvas, Offset(x, topH), Offset(x, topH + chartH), paintGrid);
         paintText.text = TextSpan(text: "${h}h", style: labelStyle);
         paintText.layout();
         paintText.paint(canvas, Offset(x - paintText.width/2, topH + chartH + 5));
    }
  }
  
  void _drawLabelOnPoint(Canvas canvas, String text, int index, double value, double stepX, Function(double) getY, bool bold) {
      double x = index * stepX + stepX/2;
      double y = getY(value);
      
      final textPainter = TextPainter(
        text: TextSpan(
           text: text, 
           style: TextStyle(
               color: bold ? Colors.white : Colors.grey[400], 
               fontSize: 12, 
               fontWeight: bold ? FontWeight.bold : FontWeight.normal
           )
        ),
        textDirection: ui.TextDirection.ltr
      );
      textPainter.layout();
      canvas.drawCircle(Offset(x, y - 10), 8, Paint()..color = Colors.black45);
      textPainter.paint(canvas, Offset(x - textPainter.width/2, y - 10 - textPainter.height/2));
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = bold ? Colors.white : Colors.grey);
  }
  
  Path _buildPath(List<double> data, double stepX, Function(double) getY) {
      Path path = Path();
      for (int i=0; i<data.length; i++) {
          if (i>=24) break;
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
  
  int _findMaxIndex(List<double> data) {
      double maxV = -999;
      int idx = 0;
      for(int i=0; i<data.length && i<24; i++) {
          if(data[i] > maxV) { maxV = data[i]; idx = i; }
      }
      return idx;
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
          pathMetric.extractPath(distance, distance + 4),
          paint,
        );
        distance += 8; // 4 dash + 4 space
      }
    }
  }
  
  IconData _getIcon(int code) {
      if (code < 3) return CupertinoIcons.sun_max_fill;
      if (code < 50) return CupertinoIcons.cloud_fill;
      if (code < 70) return CupertinoIcons.cloud_rain_fill;
      return CupertinoIcons.cloud_bolt_fill;
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
