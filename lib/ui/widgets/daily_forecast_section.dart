import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/ui/widgets/glass_container.dart';
import 'package:flutter_1/utils/weather_utils.dart';
import 'package:intl/intl.dart';

class DailyForecastSection extends StatelessWidget {
  final WeatherData weather;

  const DailyForecastSection({super.key, required this.weather});

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    // Filter to show from Today onwards
    List<int> validIndices = [];
    DateTime now = DateTime.now();
    // Normalize now to start of day for comparison
    DateTime today = DateTime(now.year, now.month, now.day);
    
    for (int i = 0; i < weather.daily.time.length; i++) {
         DateTime d = DateTime.parse(weather.daily.time[i]);
         // Include if date is today or future
         if (!d.isBefore(today)) {
             validIndices.add(i);
         }
    }

    // Determine global min and max for range bars
    double globalMin = 100;
    double globalMax = -100;
    for (var i in validIndices) {
       double low = weather.daily.temperature2mMin[i];
       double high = weather.daily.temperature2mMax[i];
       if (low < globalMin) globalMin = low;
       if (high > globalMax) globalMax = high;
    }

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.calendar, color: Colors.white54, size: 16),
              const SizedBox(width: 5),
              Text(
                "DỰ BÁO 10 NGÀY",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12, height: 1),
          ListView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: validIndices.length,
            itemBuilder: (context, index) {
              int dataIndex = validIndices[index];
              final dt = DateTime.parse(weather.daily.time[dataIndex]);
              String dayName;
              if (_isToday(dt)) {
                dayName = "Hôm nay";
              } else {
                 dayName = DateFormat('E', 'vi').format(dt).replaceAll("Th ", "Th ");
                 // Ensure formatting matches user expectations e.g. Th 5, Th 6
              }
              
              final min = weather.daily.temperature2mMin[dataIndex].round();
              final max = weather.daily.temperature2mMax[dataIndex].round();
              final code = weather.daily.weatherCode[dataIndex];
              final precip = weather.daily.precipitationProbabilityMax[dataIndex];
              
              // Bar calculations
              double range = globalMax - globalMin;
              if (range == 0) range = 1;
              double startPct = (weather.daily.temperature2mMin[dataIndex] - globalMin) / range;
              double lengthPct = (weather.daily.temperature2mMax[dataIndex] - weather.daily.temperature2mMin[dataIndex]) / range;
              
              // Colors based on temp? or standardized orange/yellow?
              // iPhone uses a gradient that shifts based on temp usually.
              // Cold (Blue) -> Hot (Red/Orange).
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(dayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500)),
                    ),
                    Expanded(
                      flex: 4, // More space for icon + precip
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start, // Align left? Standard is center or left.
                        // iPhone aligns icons in a column.
                        children: [
                          Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                  Icon(WeatherUtils.getWeatherIcon(code), color: Colors.white, size: 24),
                                  const SizedBox(width: 4),
                              ]
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 8, // Temp bars
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SizedBox(
                            width: 35,
                            child: Text("$min°",
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 18)),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: SizedBox(
                              height: 4,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      double w = constraints.maxWidth;
                                      return Positioned(
                                          left: w * startPct,
                                          width: w * lengthPct < 1 ? 1 : w * lengthPct,
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                  colors: [Colors.greenAccent, Colors.orangeAccent]),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          )
                                      );
                                    },
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          SizedBox(
                            width: 35,
                            child: Text("$max°",
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
