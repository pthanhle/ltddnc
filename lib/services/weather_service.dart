import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_1/models/weather_model.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static const String baseUrl = "https://api.open-meteo.com/v1/forecast";

  Future<WeatherData?> fetchWeather() async {
    try {
      Position position = await _determinePosition();
      final url = Uri.parse(
          '$baseUrl?latitude=${position.latitude}&longitude=${position.longitude}&current_weather=true&hourly=temperature_2m,weathercode&daily=weathercode,temperature_2m_max,temperature_2m_min&timezone=auto');

      final response = await http.get(url);

      // THÔNG BÁO TỰ ĐỘNG (NOTIFICATION)
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
