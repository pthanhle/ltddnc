import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
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

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  Future<void> init() async {
    // Load current location as first item
    City currentCity = await _repository.getCurrentLocation();
    _locations.add(LocationWeatherData(city: currentCity, isLoading: true));
    notifyListeners();
    
    await _fetchWeatherForIndex(0);

    // Monitor connectivity
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
       if (results.contains(ConnectivityResult.none)) {
          // Offline: Set error state for active locations to show banner immediately
          for(int i=0; i<_locations.length; i++) {
             if (_locations[i].data != null) {
                _locations[i] = _locations[i].copyWith(error: "No Internet");
             }
          }
          notifyListeners();
       } else {
          // Online: Clear errors immediately for instant UI feedback
          for(int i=0; i<_locations.length; i++) {
             if (_locations[i].error == "No Internet") {
                _locations[i] = _locations[i].copyWith(error: '');
             }
          }
          notifyListeners();
          
          // Then refresh data
          refreshAll();
       }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> addCity(City city) async {
    // Check if existing logic...
    int existingIndex = _locations.indexWhere((element) => element.city.name == city.name && (element.city.latitude - city.latitude).abs() < 0.0001);
    if (existingIndex != -1) {
        _currentIndex = existingIndex;
        notifyListeners();
        return;
    }
    _locations.add(LocationWeatherData(city: city, isLoading: true));
    _currentIndex = _locations.length - 1; 
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
    
    // Only show loader if we have NO data yet
    if (_locations[index].data == null) {
      _locations[index] = _locations[index].copyWith(isLoading: true, error: '');
      notifyListeners();
    }

    try {
      final data = await _repository.getWeather(_locations[index].city.latitude, _locations[index].city.longitude);
      
      if (data == null) {
        if (_locations[index].data != null) {
           _locations[index] = _locations[index].copyWith(isLoading: false, error: "Connection failed"); 
        } else {
           _locations[index] = _locations[index].copyWith(isLoading: false, error: "Unable to fetch data");
        }
      } else {
        // Success: Explicitly clear error
        _locations[index] = _locations[index].copyWith(isLoading: false, data: data, error: '');
      }
    } catch (e) {
        if (_locations[index].data != null) {
           _locations[index] = _locations[index].copyWith(isLoading: false, error: "Connection failed");
        } else {
           _locations[index] = _locations[index].copyWith(isLoading: false, error: e.toString());
        }
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
