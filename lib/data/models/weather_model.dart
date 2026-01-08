
class WeatherData {
  final double latitude;
  final double longitude;
  final CurrentWeather current;
  final HourlyWeather hourly;
  final DailyWeather daily;
  final AirQuality? airQuality;
  final DateTime? lastUpdated;

  WeatherData({
    required this.latitude,
    required this.longitude,
    required this.current,
    required this.hourly,
    required this.daily,
    this.airQuality,
    this.lastUpdated,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      current: CurrentWeather.fromJson(json['current'] ?? {}),
      hourly: HourlyWeather.fromJson(json['hourly'] ?? {}),
      daily: DailyWeather.fromJson(json['daily'] ?? {}),
      airQuality: json.containsKey('air_quality') && json['air_quality'] != null ? AirQuality.fromJson(json['air_quality']) : null,
      lastUpdated: json['local_last_updated'] != null ? DateTime.parse(json['local_last_updated']) : null,
    );
  }
}

class AirQuality {
  final double usAqi;
  final double pm2_5;
  final double pm10;
  final List<double>? hourlyUsAqi; // Added for charts

  AirQuality({required this.usAqi, required this.pm2_5, required this.pm10, this.hourlyUsAqi});

  factory AirQuality.fromJson(Map<String, dynamic> json) {
     final current = json['current'] ?? {};
     List<double>? hourly;
     if (json['hourly'] != null && json['hourly']['us_aqi'] != null) {
       hourly = List<double>.from((json['hourly']['us_aqi'] as List).map((x) => (x as num?)?.toDouble() ?? 0.0));
     }
     
     return AirQuality(
       usAqi: (current['us_aqi'] as num?)?.toDouble() ?? 0.0,
       pm2_5: (current['pm2_5'] as num?)?.toDouble() ?? 0.0,
       pm10: (current['pm10'] as num?)?.toDouble() ?? 0.0,
       hourlyUsAqi: hourly,
     );
  }
}

// CurrentWeather, HourlyWeather, DailyWeather, City classes remain the same
class CurrentWeather {
  final double temperature2m;
  final double relativeHumidity2m;
  final double apparentTemperature;
  final int isDay;
  final double precipitation;
  final int weatherCode;
  final double windSpeed10m;
  final double surfacePressure;
  final double visibility;
  final int windDirection10m;
  final int cloudCover;
  final double windGusts10m;
  final double uvIndex;

  CurrentWeather({
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.apparentTemperature,
    required this.isDay,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed10m,
    required this.surfacePressure,
    required this.visibility,
    required this.windDirection10m,
    required this.cloudCover,
    required this.windGusts10m,
    required this.uvIndex,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature2m: (json['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      relativeHumidity2m: (json['relative_humidity_2m'] as num?)?.toDouble() ?? 0.0,
      apparentTemperature: (json['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      isDay: (json['is_day'] as int?) ?? 1,
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (json['weather_code'] as int?) ?? 0,
      windSpeed10m: (json['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      surfacePressure: (json['surface_pressure'] as num?)?.toDouble() ?? 0.0,
      visibility: (json['visibility'] as num?)?.toDouble() ?? 0.0,
      windDirection10m: (json['wind_direction_10m'] as int?) ?? 0,
      cloudCover: (json['cloud_cover'] as num?)?.toInt() ?? 0,
      windGusts10m: (json['wind_gusts_10m'] as num?)?.toDouble() ?? 0.0,
      uvIndex: (json['uv_index'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class HourlyWeather {
  final List<String> time;
  final List<double> temperature2m;
  final List<int> weatherCode;
  final List<int> precipitationProbability;
  final List<double> uvIndex;
  final List<double> windSpeed10m;
  final List<double> relativeHumidity2m;
  final List<double> visibility;
  final List<double> surfacePressure;
  final List<double> apparentTemperature;
  final List<double> precipitation;
  final List<int> cloudCover;
  final List<double> windGusts10m;
  final List<int> windDirection10m;

  HourlyWeather({
    required this.time,
    required this.temperature2m,
    required this.weatherCode,
    required this.precipitationProbability,
    required this.uvIndex,
    required this.windSpeed10m,
    required this.relativeHumidity2m,
    required this.visibility,
    required this.surfacePressure,
    required this.apparentTemperature,
    required this.precipitation,
    required this.cloudCover,
    required this.windGusts10m,
    required this.windDirection10m,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    return HourlyWeather(
      time: List<String>.from(json['time'] ?? []),
      temperature2m: List<double>.from((json['temperature_2m'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
      weatherCode: List<int>.from((json['weather_code'] as List? ?? []).map((x) => (x as num?)?.toInt() ?? 0)),
      precipitationProbability: List<int>.from((json['precipitation_probability'] as List? ?? []).map((x) => (x as num?)?.toInt() ?? 0)),
      uvIndex: List<double>.from((json['uv_index'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
      windSpeed10m: List<double>.from((json['wind_speed_10m'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
      relativeHumidity2m: List<double>.from((json['relative_humidity_2m'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
      visibility: List<double>.from((json['visibility'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
      surfacePressure: List<double>.from((json['surface_pressure'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
      apparentTemperature: List<double>.from((json['apparent_temperature'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
      precipitation: List<double>.from((json['precipitation'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
      cloudCover: List<int>.from((json['cloud_cover'] as List? ?? []).map((x) => (x as num?)?.toInt() ?? 0)),
      windGusts10m: json['wind_gusts_10m'] != null 
          ? List<double>.from((json['wind_gusts_10m'] as List).map((x) => (x as num?)?.toDouble() ?? 0.0))
          : List.filled((json['time'] as List? ?? []).length, 0.0),
      windDirection10m: json['wind_direction_10m'] != null
          ? List<int>.from((json['wind_direction_10m'] as List).map((x) => (x as num?)?.toInt() ?? 0))
          : List.filled((json['time'] as List? ?? []).length, 0),
    );
  }
}

class DailyWeather {
  final List<String> time;
  final List<int> weatherCode;
  final List<double> temperature2mMax;
  final List<double> temperature2mMin;
  final List<String> sunrise;
  final List<String> sunset;
  final List<double> uvIndexMax;
  final List<int> precipitationProbabilityMax;
  final List<double> precipitationSum;
  final List<double> daylightDuration;

  DailyWeather({
    required this.time,
    required this.weatherCode,
    required this.temperature2mMax,
    required this.temperature2mMin,
    required this.sunrise,
    required this.sunset,
    required this.uvIndexMax,
    required this.precipitationProbabilityMax,
    required this.precipitationSum,
    required this.daylightDuration,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    return DailyWeather(
      time: List<String>.from(json['time'] ?? []),
      weatherCode: List<int>.from((json['weather_code'] as List? ?? []).map((x) => (x as num?)?.toInt() ?? 0)),
      temperature2mMax: List<double>.from((json['temperature_2m_max'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
      temperature2mMin: List<double>.from((json['temperature_2m_min'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
      sunrise: List<String>.from(json['sunrise'] ?? []),
      sunset: List<String>.from(json['sunset'] ?? []),
      uvIndexMax: List<double>.from((json['uv_index_max'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
      precipitationProbabilityMax: json['precipitation_probability_max'] != null 
          ? List<int>.from((json['precipitation_probability_max'] as List).map((x) => (x as num?)?.toInt() ?? 0))
          : List.filled((json['time'] as List? ?? []).length, 0),
      precipitationSum: json['precipitation_sum'] != null
          ? List<double>.from((json['precipitation_sum'] as List).map((x) => (x as num?)?.toDouble() ?? 0.0))
          : List.filled((json['time'] as List? ?? []).length, 0.0),
      daylightDuration: json['daylight_duration'] != null
          ? List<double>.from((json['daylight_duration'] as List).map((x) => (x as num?)?.toDouble() ?? 0.0))
          : List.filled((json['time'] as List? ?? []).length, 0.0),
    );
  }
}

class City {
  final String name;
  final double latitude;
  final double longitude;
  final String country;

  City({required this.name, required this.latitude, required this.longitude, required this.country});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      country: json['country'] ?? '',
    );
  }
}
