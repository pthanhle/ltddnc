import 'package:flutter/material.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/ui/widgets/detail_day_selector.dart';
import 'package:flutter_1/ui/widgets/details/detail_chart.dart';
import 'package:flutter_1/ui/widgets/glass_container.dart';
import 'package:flutter_1/utils/enums.dart';
import 'package:intl/intl.dart';

class WeatherDetailScreen extends StatefulWidget {
  final WeatherData weather;
  final MetricType type;

  const WeatherDetailScreen({super.key, required this.weather, required this.type});

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  int _selectedDayIndex = 1; // Default to Today

  int get _currentHourIndex => 24 + DateTime.now().hour;

  @override
  Widget build(BuildContext context) {
    bool isToday = _selectedDayIndex == 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_getTitle(widget.type), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white), 
          onPressed: () => Navigator.pop(context)
        ),
      ),
      body: Column(
        children: [
          // 1. Day Selector
          DetailDaySelector(
            times: widget.weather.daily.time, 
            selectedIndex: _selectedDayIndex, 
            onDaySelected: (idx) => setState(() => _selectedDayIndex = idx)
          ),
          
          const Divider(color: Colors.white12, height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // 2. Main Value Display
                   Text(
                     isToday ? "Bây giờ, ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2,'0')}" : _getDateTitle(_selectedDayIndex),
                     style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600),
                   ),
                   const SizedBox(height: 5),
                   Row(
                     crossAxisAlignment: CrossAxisAlignment.baseline,
                     textBaseline: TextBaseline.alphabetic,
                     children: [
                       Text(
                         _getDisplayValue(widget.type, _selectedDayIndex),
                         style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w500),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: Text(
                           _getAdviceShort(widget.type, _selectedDayIndex),
                           style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500),
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 10),
                   Text(
                     _getDateAdvice(widget.type, _selectedDayIndex),
                     style: const TextStyle(color: Colors.white70, fontSize: 16),
                   ),
                   
                   const SizedBox(height: 40),

                   // 3. Chart
                   Container(
                     height: 300,
                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                     decoration: BoxDecoration(
                       color: const Color(0xFF1C1C1E),
                       borderRadius: BorderRadius.circular(25),
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          Padding(
                             padding: const EdgeInsets.only(bottom: 20, left: 10),
                             child: Row(
                               children: [
                                 Icon(_getIconForType(widget.type), color: Colors.white54, size: 16),
                                 const SizedBox(width: 8),
                                 Text(_getTitle(widget.type).toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                               ],
                             ),
                           ),
                           Expanded(
                             child: DetailChart(
                               type: widget.type, 
                               hourly: widget.weather.hourly,
                               airQuality: widget.weather.airQuality,
                               dayIndex: _selectedDayIndex
                             ),
                           ),
                       ],
                     ),
                   ),

                   const SizedBox(height: 30),
                   
                   // 4. Comparison
                   if (isToday) 
                     _buildComparisonSection(),

                   const SizedBox(height: 30),

                   // 5. About
                   Container(
                     padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                       color: const Color(0xFF1C1C1E),
                       borderRadius: BorderRadius.circular(25),
                     ),
                     child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Row(
                             children: [
                               const Icon(Icons.info, color: Colors.white54, size: 18),
                               const SizedBox(width: 10),
                               Text("GIỚI THIỆU VỀ ${_getTitle(widget.type).toUpperCase()}", style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)),
                             ],
                           ),
                           const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Colors.white24)),
                           Text(_getDescription(widget.type), style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 16)),
                        ],
                     )
                   ),
                   const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getDateTitle(int index) {
      final dt = DateTime.parse(widget.weather.daily.time[index]);
      return DateFormat('EEEE, d MMMM', 'vi').format(dt);
  }

  IconData _getIconForType(MetricType type) {
     switch (type) {
       case MetricType.uvIndex: return Icons.wb_sunny;
       case MetricType.wind: return Icons.air;
       case MetricType.rain: return Icons.water_drop;
       case MetricType.humidity: return Icons.opacity;
       case MetricType.visibility: return Icons.visibility;
       case MetricType.pressure: return Icons.speed;
       case MetricType.feelsLike: return Icons.thermostat;
       case MetricType.aqi: return Icons.scatter_plot; // or Icons.air
       case MetricType.cloudCover: return Icons.cloud;
       case MetricType.average: return Icons.show_chart;
     }
  }
  
  // Re-use logic from previous step but cleaned up
  Widget _buildComparisonSection() {
     // Prepare data
     double todayVal = _getDailyAggregate(widget.type, 1);
     double yestVal = _getDailyAggregate(widget.type, 0);

     double max = todayVal > yestVal ? todayVal : yestVal;
     if (max == 0) max = 1;

     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
          const Text("So sánh hàng ngày", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: const Color(0xFF1C1C1E),
               borderRadius: BorderRadius.circular(25),
             ),
             child: Column(
               children: [
                  Text(
                    _getComparisonText(todayVal, yestVal),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 25),
                  _buildComparisonBar("Hôm nay", todayVal, max, true),
                  const SizedBox(height: 15),
                  _buildComparisonBar("Hôm qua", yestVal, max, false),
               ],
             ),
          )
       ],
     );
  }
  
  Widget _buildComparisonBar(String label, double val, double max, bool highlight) {
      return Row(
        children: [
           SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15))),
           Expanded(
             child: LayoutBuilder(
               builder: (context, constraints) {
                 double width = (val / max) * constraints.maxWidth;
                 // Ensure min width
                 if (width < 2 && val > 0) width = 2;
                 return Align(
                   alignment: Alignment.centerLeft,
                   child: Container(
                     width: width,
                     height: 8,
                     decoration: BoxDecoration(
                       color: highlight ? Colors.blueAccent : Colors.white24,
                       borderRadius: BorderRadius.circular(4),
                       gradient: highlight ? const LinearGradient(colors: [Colors.blue, Colors.cyan]) : null,
                     ),
                   ),
                 );
               }
             ),
           ),
           const SizedBox(width: 15),
           SizedBox(
             width: 40,
             child: Text(val.toStringAsFixed(0), textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontWeight: highlight ? FontWeight.bold : FontWeight.normal, fontSize: 16))
           ),
        ],
      );
  }

  double _getDailyAggregate(MetricType type, int dayIndex) {
      switch(type) {
          case MetricType.uvIndex: return widget.weather.daily.uvIndexMax[dayIndex];
          case MetricType.feelsLike: return widget.weather.daily.temperature2mMax[dayIndex]; 
          case MetricType.rain: return widget.weather.daily.precipitationSum[dayIndex];
          case MetricType.wind: return widget.weather.hourly.windSpeed10m[dayIndex*24 + 12]; 
          case MetricType.humidity: return widget.weather.hourly.relativeHumidity2m[dayIndex*24 + 12];
          default: return 0; 
      }
  }

  String _getComparisonText(double today, double yest) {
      if ((today - yest).abs() < 1) return "${_getTitle(widget.type)} hôm nay tương tự như hôm qua.";
      if (today > yest) return "${_getTitle(widget.type)} hôm nay cao hơn hôm qua.";
      return "${_getTitle(widget.type)} hôm nay thấp hơn hôm qua.";
  }

  String _getDisplayValue(MetricType type, int dayIndex) {
      if (dayIndex == 1) { // Today
         int hourIdx = _currentHourIndex;
         if (hourIdx >= widget.weather.hourly.time.length) hourIdx = widget.weather.hourly.time.length - 1;
         
         switch(type) {
            case MetricType.uvIndex: return "${widget.weather.hourly.uvIndex[hourIdx].round()}";
            case MetricType.feelsLike: return "${widget.weather.hourly.apparentTemperature[hourIdx].round()}°";
            case MetricType.wind: return "${widget.weather.hourly.windSpeed10m[hourIdx].round()}";
            case MetricType.humidity: return "${widget.weather.hourly.relativeHumidity2m[hourIdx].round()}%";
            case MetricType.pressure: return "${widget.weather.hourly.surfacePressure[hourIdx].round()}";
            case MetricType.visibility: return "${(widget.weather.hourly.visibility[hourIdx]/1000).toStringAsFixed(0)} km";
            case MetricType.aqi: 
               if (widget.weather.airQuality?.hourlyUsAqi != null && hourIdx < widget.weather.airQuality!.hourlyUsAqi!.length) {
                  return "${widget.weather.airQuality!.hourlyUsAqi![hourIdx].round()}";
               }
               return widget.weather.airQuality != null ? "${widget.weather.airQuality!.usAqi.round()}" : "--";
            case MetricType.rain: return "${widget.weather.hourly.precipitation[hourIdx]} mm";
            case MetricType.cloudCover: return "${widget.weather.hourly.cloudCover[hourIdx]}%";
            default: return "";
         }
      } else {
         // Daily
          switch(type) {
            case MetricType.uvIndex: return "${widget.weather.daily.uvIndexMax[dayIndex].round()}";
            case MetricType.feelsLike: return "${widget.weather.daily.temperature2mMax[dayIndex].round()}°";
            case MetricType.rain: return "${widget.weather.daily.precipitationSum[dayIndex]} mm";
            case MetricType.wind: return "${widget.weather.hourly.windSpeed10m[dayIndex*24+12].round()}"; // Noon
            case MetricType.humidity: return "${widget.weather.hourly.relativeHumidity2m[dayIndex*24+12].round()}%";
            case MetricType.cloudCover: return "${widget.weather.hourly.cloudCover[dayIndex*24+12]}%"; // Noon
            default: return "--";
         }
      }
  }

  String _getAdviceShort(MetricType type, int dayIndex) {
      double val = 0;
      if (dayIndex == 1) {
          int h = _currentHourIndex;
          if (h < widget.weather.hourly.uvIndex.length) {
             if (type == MetricType.uvIndex) val = widget.weather.hourly.uvIndex[h];
             if (type == MetricType.wind) val = widget.weather.hourly.windSpeed10m[h];
          }
      } else {
          if (type == MetricType.uvIndex) val = widget.weather.daily.uvIndexMax[dayIndex];
      }

      switch(type) {
         case MetricType.uvIndex:
            if (val <= 2) return "Thấp";
            if (val <= 5) return "Trung bình";
            if (val <= 7) return "Cao";
            if (val <= 10) return "Rất cao";
            return "Cực độ";
         case MetricType.wind:
             return "km/h"; 
         default: return "";
      }
  }
  
  String _getDateAdvice(MetricType type, int dayIndex) {
       switch(type) {
         case MetricType.uvIndex: return "Nên bôi kem chống nắng và đeo kính râm khi ra ngoài vào buổi trưa.";
         case MetricType.rain: return "Mang theo dù nếu có khả năng mưa cao.";
         default: return "Cập nhật lúc ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2,'0')}";
       }
  }

  String _getTitle(MetricType type) {
    switch (type) {
      case MetricType.uvIndex: return "Chỉ số UV";
      case MetricType.wind: return "Gió";
      case MetricType.rain: return "Lượng mưa";
      case MetricType.humidity: return "Độ ẩm";
      case MetricType.visibility: return "Tầm nhìn";
      case MetricType.pressure: return "Áp suất";
      case MetricType.feelsLike: return "Cảm nhận";
      case MetricType.aqi: return "Chất lượng KK";
      case MetricType.cloudCover: return "Độ che phủ mây";
      case MetricType.average: return "Trung bình";
    }
  }

  String _getDescription(MetricType type) {
     switch (type) {
      case MetricType.uvIndex:
        return "Chỉ số UV (UVI) của Tổ chức Y tế Thế giới đo mức bức xạ cực tím. UVI càng cao thì khả năng gây hại càng lớn và tốc độ xảy ra tổn thương có thể càng nhanh. UVI có thể giúp bạn quyết định khi nào cần tự bảo vệ khỏi ánh nắng mặt trời và khi nào cần tránh ra ngoài trời.";
      case MetricType.rain:
        return "Lượng mưa đo lường lượng nước tích tụ trong khoảng thời gian nhất định. Dự báo này giúp bạn chuẩn bị ô dù hoặc áo mưa khi cần thiết.";
      case MetricType.feelsLike:
        return "Nhiệt độ cảm nhận (Feels Like) tính đến độ ẩm và gió để cho biết cơ thể thực sự cảm thấy nóng hay lạnh như thế nào so với nhiệt độ đo được.";
      case MetricType.aqi:
        return "Chỉ số chất lượng không khí (AQI) cho biết mức độ sạch hay ô nhiễm của không khí. AQI trên 100 có thể ảnh hưởng xấu đến sức khỏe của nhóm nhạy cảm.";
      case MetricType.visibility:
         return "Tầm nhìn là khoảng cách xa nhất mà một vật thể có thể được nhìn thấy rõ ràng. Tầm nhìn có thể bị giảm do sương mù, mưa hoặc ô nhiễm.";
      case MetricType.average:
         return "Xem sự thay đổi của nhiệt độ so với mức trung bình lịch sử.";
      default:
        return "Thông tin chi tiết được cung cấp bởi Open-Meteo nhằm giúp bạn có kế hoạch tốt nhất cho các hoạt động của mình.";
    }
  }
}
