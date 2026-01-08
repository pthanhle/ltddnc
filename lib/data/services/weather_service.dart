import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  static const String baseUrl = "https://api.open-meteo.com/v1/forecast";
  static const String airQualityUrl = "https://air-quality-api.open-meteo.com/v1/air-quality";
  static const String geocodingUrl = "https://geocoding-api.open-meteo.com/v1/search";

  Future<WeatherData?> fetchWeather(double lat, double lon) async {
    final cacheKey = "weather_cache_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}";
    final prefs = await SharedPreferences.getInstance();

    try {
      final weatherUrl = Uri.parse(
          '$baseUrl?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,surface_pressure,visibility,wind_direction_10m,cloud_cover,wind_gusts_10m,uv_index&hourly=temperature_2m,weather_code,precipitation_probability,uv_index,wind_speed_10m,relative_humidity_2m,visibility,surface_pressure,apparent_temperature,precipitation,cloud_cover,wind_gusts_10m,wind_direction_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max,precipitation_sum,daylight_duration&timezone=auto&forecast_days=10&past_days=1');
      
      final weatherResponse = await http.get(weatherUrl);
      
      // Fetch Air Quality separately
      final aqUrl = Uri.parse('$airQualityUrl?latitude=$lat&longitude=$lon&current=us_aqi,pm10,pm2_5&hourly=us_aqi');
      http.Response? aqResponse;
      try {
        aqResponse = await http.get(aqUrl);
      } catch (e) {
          print("AQI fetch failed: $e");
      }

      if (weatherResponse.statusCode == 200) {
        final weatherJson = jsonDecode(weatherResponse.body);
        
        if (aqResponse != null && aqResponse.statusCode == 200) {
           final aqJson = jsonDecode(aqResponse.body);
           weatherJson['air_quality'] = aqJson;
        }

        // Add Timestamp and Cache
        weatherJson['local_last_updated'] = DateTime.now().toIso8601String();
        await prefs.setString(cacheKey, jsonEncode(weatherJson));
        
        return WeatherData.fromJson(weatherJson);
      } else {
        print("Failed to load weather data: ${weatherResponse.statusCode}");
        throw Exception("Server error");
      }
    } catch (e) {
      print("Error fetching weather: $e. Using cache.");
      // Fallback to cache
      final cachedString = prefs.getString(cacheKey);
      if (cachedString != null) {
          return WeatherData.fromJson(jsonDecode(cachedString));
      }
      return null;
    }
  }

  Future<List<City>> searchCity(String query) async {
    try {
      final url = Uri.parse('$geocodingUrl?name=$query&count=10&language=en&format=json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null) {
           return (data['results'] as List).map((e) => City.fromJson(e)).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      print("Error searching city: $e");
      return [];
    }
  }
  
  // _determinePosition and _getDefaultPosition methods (copying previous logic)
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled. Using default location (Hanoi).');
      return _getDefaultPosition();
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied. Using default location (Hanoi).');
        return _getDefaultPosition();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied. Using default location (Hanoi).');
      return _getDefaultPosition();
    }

    return await Geolocator.getCurrentPosition();
  }

  Position _getDefaultPosition() {
    return Position(
      longitude: 105.8542,
      latitude: 21.0285,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0
    );
  }

  Future<City> getCurrentCity() async {
     Position pos;
     try {
       pos = await _determinePosition();
     } catch (e) {
       return City(name: "Hà Nội", latitude: 21.0285, longitude: 105.8542, country: "Vietnam");
     }

     String name = "";
     String country = "";

     // 1. Try Geocoding Package (Platform specific)
     try {
       List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
       if (placemarks.isNotEmpty) {
         Placemark place = placemarks[0];
         name = place.subAdministrativeArea ?? place.locality ?? place.administrativeArea ?? "";
         country = place.country ?? "";
       }
     } catch (e) {
       // Ignore
     }

     // 2. Fallback to Nominatim (OpenStreetMap) if empty
     if (name.isEmpty || name == "Vị trí của tôi") {
        try {
           final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=10&addressdetails=1');
           final response = await http.get(url, headers: {'User-Agent': 'FlutterWeatherClone/1.0'});
           if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final address = data['address'];
              if (address != null) {
                 name = address['city'] ?? address['town'] ?? address['village'] ?? address['county'] ?? "";
                 country = address['country'] ?? "";
              }
           }
        } catch (e) {
           print("Nominatim error: $e");
        }
     }

     if (name.isEmpty) {
        name = "${pos.latitude.toStringAsFixed(2)}, ${pos.longitude.toStringAsFixed(2)}";
     }

     return City(name: name, latitude: pos.latitude, longitude: pos.longitude, country: country);
  }
}
