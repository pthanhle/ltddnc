import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static const String baseUrl = "https://api.open-meteo.com/v1/forecast";

  Future<WeatherData?> fetchWeather({double? lat, double? lon}) async {
    try {
      double latitude;
      double longitude;

      if (lat != null && lon != null) {
        latitude = lat;
        longitude = lon;
      } else {
        Position position = await _determinePosition();
        latitude = position.latitude;
        longitude = position.longitude;
      }

      final url = Uri.parse(
          '$baseUrl?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,surface_pressure,visibility,wind_direction_10m,cloud_cover,wind_gusts_10m,uv_index&hourly=temperature_2m,weather_code,precipitation_probability,uv_index,wind_speed_10m,relative_humidity_2m,visibility,surface_pressure,apparent_temperature,precipitation,cloud_cover,wind_gusts_10m,wind_direction_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max,precipitation_sum,daylight_duration&timezone=auto');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        return WeatherData.fromJson(jsonDecode(response.body));
      } else {
        print("Failed to load weather data: ${response.statusCode}");
        return null;
      }
    } catch (e, stackTrace) {
      print("Error fetching weather: $e");
      print(stackTrace);
      return null;
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }
}
