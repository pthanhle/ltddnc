import 'package:flutter/material.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/utils/constants.dart';
import 'package:flutter_1/utils/weather_utils.dart';
import 'package:intl/intl.dart';

class CurrentWeatherHeader extends StatelessWidget {
  final WeatherData weather;
  final City city;
  final bool isMyLocation;
  final bool hasConnectionError;

  const CurrentWeatherHeader({
     super.key, 
     required this.weather, 
     required this.city, 
     this.isMyLocation = false,
     this.hasConnectionError = false
  });

  @override
  Widget build(BuildContext context) {
    // Check if data is older than 2 minutes
    bool isStale = false;
    if (weather.lastUpdated != null) {
      final diff = DateTime.now().difference(weather.lastUpdated!);
      if (diff.inMinutes >= 2) {
        isStale = true;
      }
    }
    
    // Show if stale OR explicitly failed connection
    bool showBanner = isStale || hasConnectionError;

    return Column(
      children: [
        if (showBanner)
          Container(
            margin: const EdgeInsets.only(top: 80, bottom: 10),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Không có kết nối internet",
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Cập nhật lần cuối: ${DateFormat('HH:mm').format(weather.lastUpdated!)}",
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          const SizedBox(height: 80),

        Column( 
           children: [
             if (isMyLocation)
               Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.near_me, size: 14, color: Colors.white),
                   const SizedBox(width: 4),
                   const Text("Vị trí của tôi", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                 ],
               ),
             const SizedBox(height: 5),
             Text(city.name, style: AppTheme.city.copyWith(fontSize: 32)),
             if (city.country.isNotEmpty)
                Text(city.country, style: const TextStyle(color: Colors.white70, fontSize: 16)),
           ]
        ),
        Text(
          "${weather.current.temperature2m.round()}°",
          style: AppTheme.bigTemp,
        ),
        Text(
          WeatherUtils.getWeatherDescription(weather.current.weatherCode),
          style: AppTheme.desc,
        ),
        const SizedBox(height: 5),
        Text(
          "Cao: ${weather.daily.temperature2mMax[0].round()}°  Thấp: ${weather.daily.temperature2mMin[0].round()}°",
          style: AppTheme.hl,
        ),
      ],
    );
  }
}
