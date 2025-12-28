import 'package:flutter/material.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/data/repositories/weather_repository.dart';

class LocationWeatherData {
  final City city;
  final WeatherData? data;
  final bool isLoading;
  final String error;

  LocationWeatherData({required this.city, this.data, this.isLoading = false, this.error = ''});
  
  LocationWeatherData copyWith({City? city, WeatherData? data, bool? isLoading, String? error}) {
    return LocationWeatherData(
      city: city ?? this.city,
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class WeatherProvider with ChangeNotifier {
  final WeatherRepository _repository = WeatherRepository();
  List<LocationWeatherData> _locations = [];
  int _currentIndex = 0;

  List<LocationWeatherData> get locations => _locations;
  int get currentIndex => _currentIndex;

  Future<void> init() async {
    // Load current location as first item
    City currentCity = await _repository.getCurrentLocation();
    _locations.add(LocationWeatherData(city: currentCity, isLoading: true));
    notifyListeners();
    
    await _fetchWeatherForIndex(0);
  }

  Future<void> addCity(City city) async {
    // Check if exists
    if (_locations.any((element) => element.city.name == city.name && element.city.latitude == city.latitude)) {
      return;
    }
    _locations.add(LocationWeatherData(city: city, isLoading: true));
    notifyListeners();
    await _fetchWeatherForIndex(_locations.length - 1);
  }

  Future<void> refreshAll() async {
    for (int i = 0; i < _locations.length; i++) {
        await _fetchWeatherForIndex(i);
    }
  }
  
  Future<void> _fetchWeatherForIndex(int index) async {
    if (index < 0 || index >= _locations.length) return;
    
    _locations[index] = _locations[index].copyWith(isLoading: true, error: '');
    notifyListeners();

    try {
      final data = await _repository.getWeather(_locations[index].city.latitude, _locations[index].city.longitude);
      if (data == null) {
        _locations[index] = _locations[index].copyWith(isLoading: false, error: "Unable to fetch data");
      } else {
        _locations[index] = _locations[index].copyWith(isLoading: false, data: data);
      }
    } catch (e) {
      _locations[index] = _locations[index].copyWith(isLoading: false, error: e.toString());
    }
    notifyListeners();
  }
  
  Future<List<City>> searchCities(String query) {
    return _repository.searchCities(query);
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
