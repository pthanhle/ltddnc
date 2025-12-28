import 'package:flutter/material.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/utils/constants.dart';
import 'package:flutter_1/utils/weather_utils.dart';

class CurrentWeatherHeader extends StatelessWidget {
  final WeatherData weather;
  final City city;
  final bool isMyLocation;

  const CurrentWeatherHeader({super.key, required this.weather, required this.city, this.isMyLocation = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
             Text(city.name, style: AppTheme.city.copyWith(fontSize: 32)), // Reduced size slightly for longer names
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
