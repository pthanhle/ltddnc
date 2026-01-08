import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/utils/enums.dart';

class DetailChart extends StatelessWidget {
  final MetricType type;
  final HourlyWeather hourly;
  final AirQuality? airQuality;
  final int dayIndex; // 0 = Yesterday, 1 = Today, etc.

  const DetailChart({
    super.key,
    required this.type,
    required this.hourly,
    this.airQuality,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Basic bounds check
    int start = dayIndex * 24;
    int end = start + 24;
    
    // Safety check for array lengths
    if (hourly.time.length < end) {
       return const Center(child: Text("Dữ liệu đang được cập nhật...", style: TextStyle(color: Colors.white54)));
    }

    // Chart Configuration
    List<double> data = [];
    double? maxY;
    double? minY;
    List<Color> gradientColors = [Colors.blueAccent, Colors.blueAccent.withOpacity(0.0)];

    // Data Extraction Strategy
    switch (type) {
      case MetricType.uvIndex:
        data = hourly.uvIndex.sublist(start, end);
        maxY = 12; // Standard UV Max
        gradientColors = [Colors.purpleAccent, Colors.purpleAccent.withOpacity(0.0)];
        break;
      
      case MetricType.wind:
        data = hourly.windSpeed10m.sublist(start, end);
        gradientColors = [Colors.blueAccent, Colors.blueAccent.withOpacity(0.0)];
        break;

      case MetricType.feelsLike:
        data = hourly.apparentTemperature.sublist(start, end);
        gradientColors = [Colors.orangeAccent, Colors.orangeAccent.withOpacity(0.0)];
        break;

      case MetricType.humidity:
        data = hourly.relativeHumidity2m.sublist(start, end);
        maxY = 100;
        gradientColors = [Colors.lightBlueAccent, Colors.lightBlueAccent.withOpacity(0.0)];
        break;
      
      case MetricType.pressure:
        data = hourly.surfacePressure.sublist(start, end);
        // Pressure varies less, so dynamic min/max is better, but chart library handles auto min/max well if not set.
        gradientColors = [Colors.tealAccent, Colors.tealAccent.withOpacity(0.0)];
        break;
        
      case MetricType.visibility:
        data = hourly.visibility.map((v) => v / 1000).toList().sublist(start, end);
        gradientColors = [Colors.grey, Colors.grey.withOpacity(0.0)];
        break;

      case MetricType.cloudCover:
        data = hourly.cloudCover.map((v) => v.toDouble()).toList().sublist(start, end);
        maxY = 100;
        gradientColors = [Colors.white70, Colors.white10];
        break;

      case MetricType.aqi:
        if (airQuality?.hourlyUsAqi != null && airQuality!.hourlyUsAqi!.length >= end) {
           data = airQuality!.hourlyUsAqi!.sublist(start, end);
           // Color based on avg usually, but here fixed
           gradientColors = [Colors.greenAccent, Colors.greenAccent.withOpacity(0.0)];
           if (data.any((v) => v > 100)) gradientColors = [Colors.orangeAccent, Colors.orangeAccent.withOpacity(0.0)];
           if (data.any((v) => v > 150)) gradientColors = [Colors.redAccent, Colors.redAccent.withOpacity(0.0)];
        } 
        break;

      case MetricType.rain:
         // Rain is special (Bar Chart), handled below if needed, or we treat it as line for consistency if requested, but Bar is better.
         data = hourly.precipitationProbability.map((v) => v.toDouble()).toList().sublist(start, end);
         maxY = 100;
         break;

      case MetricType.average:
         data = hourly.temperature2m.sublist(start, end);
         gradientColors = [Colors.orangeAccent, Colors.orangeAccent.withOpacity(0.0)];
         break;
    }

    if (data.isEmpty) {
        return const Center(child: Text("Không có dữ liệu biểu đồ", style: TextStyle(color: Colors.white54)));
    }

    if (type == MetricType.rain) {
       return _buildBarChart(data);
    }

    return _buildLineChart(data, gradientColors, maxY);
  }

  Widget _buildBarChart(List<double> data) {
      return BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF2C2C2E),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                 return BarTooltipItem(
                   "${rod.toY.round()}%", 
                   const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                 );
              }
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                   if (value % 6 == 0) { // Every 6 hours
                     return Text(
                       "${value.toInt()}h", 
                       style: const TextStyle(color: Colors.white54, fontSize: 10)
                     );
                   }
                   return const SizedBox();
                },
              )
            )
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: data.asMap().entries.map((e) {
             return BarChartGroupData(
               x: e.key,
               barRods: [
                 BarChartRodData(
                   toY: e.value,
                   color: Colors.blueAccent,
                   width: 4,
                   borderRadius: BorderRadius.circular(2),
                   backDrawRodData: BackgroundBarChartRodData(
                     show: true,
                     toY: 100,
                     color: Colors.white.withOpacity(0.05)
                   )
                 )
               ]
             );
          }).toList(),
        )
      );
  }

  Widget _buildLineChart(List<double> data, List<Color> colors, double? maxY) {
     return LineChart(
       LineChartData(
         minY: 0,
         maxY: maxY, // Auto if null
         gridData: FlGridData(
           show: true,
           drawVerticalLine: true,
           horizontalInterval: maxY != null ? maxY / 4 : null, // 4 lines
           getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1),
           getDrawingVerticalLine: (value) => FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1),
         ),
         titlesData: FlTitlesData(
           show: true,
           topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
           rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
           leftTitles: AxisTitles(
              sideTitles: SideTitles(
                 showTitles: true, 
                 reservedSize: 25,
                 getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(color: Colors.white30, fontSize: 10)),
              )
           ),
           bottomTitles: AxisTitles(
             sideTitles: SideTitles(
               showTitles: true,
               interval: 6,
               getTitlesWidget: (value, meta) {
                 return Padding(
                   padding: const EdgeInsets.only(top: 8.0),
                   child: Text("${value.toInt()} giờ", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                 );
               },
             )
           )
         ),
         borderData: FlBorderData(show: false),
         lineBarsData: [
           LineChartBarData(
             spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
             isCurved: true,
             color: colors[0],
             barWidth: 3,
             isStrokeCapRound: true,
             dotData: FlDotData(show: false),
             belowBarData: BarAreaData(
               show: true,
               gradient: LinearGradient(
                 colors: colors,
                 begin: Alignment.topCenter,
                 end: Alignment.bottomCenter,
               )
             )
           )
         ],
         // Marker for "Now" if today
         extraLinesData: (dayIndex == 1) ? ExtraLinesData(
            verticalLines: [
               VerticalLine(
                 x: DateTime.now().hour.toDouble(),
                 color: Colors.white,
                 strokeWidth: 1,
                 dashArray: [4, 4],
                 label: VerticalLineLabel(
                   show: true,
                   alignment: Alignment.topRight,
                   style: const TextStyle(color: Colors.white, fontSize: 10, fontStyle: FontStyle.italic),
                   labelResolver: (_) => "Bây giờ"
                 )
               )
            ]
         ) : null
       )
     );
  }
}
