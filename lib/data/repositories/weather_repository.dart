import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/data/services/weather_service.dart';
import 'package:geocoding/geocoding.dart' as geo;

class WeatherRepository {
  final WeatherService _weatherService = WeatherService();

  Future<WeatherData?> getWeather(double lat, double lon) async {
    return await _weatherService.fetchWeather(lat, lon);
  }

  Future<City> getCurrentLocation() async {
    return await _weatherService.getCurrentCity();
  }

  Future<List<City>> searchCities(String query) async {
    return await _weatherService.searchCity(query);
  }
}
