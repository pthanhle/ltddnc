import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/ui/widgets/glass_container.dart';
import 'package:flutter_1/utils/weather_utils.dart';
import 'package:intl/intl.dart';

class HourlyForecastSection extends StatelessWidget {
  final WeatherData weather;

  const HourlyForecastSection({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Expanded(
                 child: Text(
                  _generateSummary(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
               ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: _buildHourlyItems(),
            ),
          ),
        ],
      ),
    );
  }

  String _generateSummary() {
      // Simple logic: Find first condition change or rain
      DateTime now = DateTime.now();
      int currentHour = now.hour;
      
      // Find index for now
      int startIndex = 0;
      for(int i=0; i<weather.hourly.time.length; i++) {
          if (DateTime.parse(weather.hourly.time[i]).hour == currentHour) {
              startIndex = i;
              break;
          }
      }
      
      // Check next 6 hours
      for(int i=startIndex; i<startIndex+6 && i<weather.hourly.time.length; i++) {
           int code = weather.hourly.weatherCode[i];
           int prob = weather.hourly.precipitationProbability[i];
           
           // Only warn if code is rain-related AND probability is meaningful (>25%)
           if (code >= 51 && prob > 25) { 
               String time = DateFormat('HH:mm').format(DateTime.parse(weather.hourly.time[i]));
               return "Dự báo khả năng có mưa vào khoảng $time. Gió giật lên đến ${weather.current.windGusts10m.round()} km/h.";
           }
      }
      
      // If no rain, check for clear/cloudy transition or just generic
      return "Dự báo trời ${weather.current.cloudCover > 50 ? 'nhiều mây' : 'quang đãng'} trong vài giờ tới. Gió giật lên đến ${weather.current.windGusts10m.round()} km/h.";
  }

  List<Widget> _buildHourlyItems() {
      List<Widget> items = [];
      DateTime now = DateTime.now();
      
      // Find starting index based on current time
      int startIndex = 0;
       // API often returns past days, so finding the correct "Now" is crucial
      // We look for the first timestamp that is strictly AFTER (now - 1 hour) ?
      // Or simply matching the hour.
      for(int i=0; i<weather.hourly.time.length; i++) {
          DateTime t = DateTime.parse(weather.hourly.time[i]);
          if (t.year == now.year && t.month == now.month && t.day == now.day && t.hour == now.hour) {
              startIndex = i;
              break;
          }
      }

      // Add "Now" item
      items.add(_buildItem(
          "Bây giờ", 
          weather.hourly.weatherCode[startIndex], 
          weather.hourly.temperature2m[startIndex].round(),
          highlight: true
      ));

      // Loop for next 24 hours
      for (int i = 1; i <= 24; i++) {
          int index = startIndex + i;
          if (index >= weather.hourly.time.length) break;
          
          DateTime time = DateTime.parse(weather.hourly.time[index]);
          String hourLabel = "${time.hour.toString().padLeft(2, '0')} giờ";
          
          // Check for Sunrise/Sunset insertion
          // Need sunrise/sunset time for THIS day (or next day if we crossed midnight)
          // Simplified: extracting directly from daily data if available
          String? sunEventLabel;
          String? sunEventTime;
          bool isSunrise = false;
          
          // Helper to check if a specific event happens between prev hour and this hour? 
          // Or roughly at this hour?
          // iPhone displays it INSTEAD of the hour slot if it's close? Or BETWEEN slots?
          // iPhone shows it AS a slot. "05:43 Sunrise".
          // Let's check if any sunrise/sunset falls within [time - 30min, time + 30min]
          
          // Actually, let's just use the hour. If sunrise is 06:05, and we are showing 06:00, 
          // we show 06:00 THEN 06:05? No, the list is strictly ordered by time.
          // So we should interleave them.
          
          items.add(_buildItem(
            hourLabel,
            weather.hourly.weatherCode[index],
            weather.hourly.temperature2m[index].round()
          ));
          
          // Check for sun event after this item before next?
          // Implementing strictly interleaved list is complex with standard ListView builder.
          // That's why I switched to `children: _buildHourlyItems()`.
      }
      
      // CORRECT APPROACH:
      // Create a list of objects {time, type, data}. Sort by time. Render.
      List<HourlyItem> mixedList = [];
      
      DateTime end = now.add(const Duration(hours: 24));

      // 1. Add Hourly Data
      for (int i = startIndex; i < startIndex + 25 && i < weather.hourly.time.length; i++) {
         DateTime t = DateTime.parse(weather.hourly.time[i]);
         mixedList.add(HourlyItem(
             time: t, 
             type: 'weather', 
             temp: weather.hourly.temperature2m[i].round(),
             code: weather.hourly.weatherCode[i]
         ));
      }
      
      // 2. Add Sun Events (for today and tomorrow)
      // Iterate daily data to find sunrise/sunset times
      for(int d=0; d<weather.daily.time.length; d++) {
          DateTime dayDate = DateTime.parse(weather.daily.time[d]);
          // Sunrise
          if (d < weather.daily.sunrise.length) {
              DateTime sunrise = DateTime.parse(weather.daily.sunrise[d]); 
              if (sunrise.isAfter(now) && sunrise.isBefore(end)) {
                 mixedList.add(HourlyItem(time: sunrise, type: 'sunrise'));
              }
          }
          // Sunset
          if (d < weather.daily.sunset.length) {
              DateTime sunset = DateTime.parse(weather.daily.sunset[d]);
              if (sunset.isAfter(now) && sunset.isBefore(end)) {
                 mixedList.add(HourlyItem(time: sunset, type: 'sunset'));
              }
          }
      }
      
      // 3. Sort
      mixedList.sort((a, b) => a.time.compareTo(b.time));
      
      // 4. Build Widgets
      // Filter out duplicate hours if sunrise is very close? (Optional polish)
      return mixedList.map((item) {
           if (item.type == 'weather') {
               bool isNow = item.time.hour == now.hour && item.time.day == now.day && (item.time.difference(now).abs().inMinutes < 60);
               // Actually "Now" is the VERY first item usually.
               String label = isNow && mixedList.indexOf(item) == 0 ? "Bây giờ" : "${item.time.hour.toString().padLeft(2, '0')} giờ";
               return _buildItem(label, item.code!, item.temp!);
           } else {
               String label = DateFormat('HH:mm').format(item.time);
               return _buildSunItem(label, item.type == 'sunrise');
           }
      }).toList();
  }
  
  Widget _buildItem(String time, int code, int temp, {bool highlight = false}) {
      return Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(time, style: TextStyle(color: Colors.white, fontWeight: highlight ? FontWeight.bold : FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            Icon(
              WeatherUtils.getWeatherIcon(code),
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text("$temp°", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
          ],
        ),
      );
  }
  
  Widget _buildSunItem(String time, bool isSunrise) {
      return Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
            const SizedBox(height: 8),
            Icon(
               isSunrise ? CupertinoIcons.sunrise_fill : CupertinoIcons.sunset_fill,
               color: Colors.yellow,
               size: 28
            ),
            const SizedBox(height: 8),
            Text(isSunrise ? "Mặt trời mọc" : "Mặt trời lặn", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      );
  }
}

class HourlyItem {
    final DateTime time;
    final String type; // 'weather', 'sunrise', 'sunset'
    final int? temp;
    final int? code;
    
    HourlyItem({required this.time, required this.type, this.temp, this.code});
}
