
class WeatherData {
  final CurrentWeather current;
  final HourlyWeather hourly;
  final DailyWeather daily;

  WeatherData({required this.current, required this.hourly, required this.daily});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      current: CurrentWeather.fromJson(json['current_weather'] ?? {}),
      hourly: HourlyWeather.fromJson(json['hourly'] ?? {}),
      daily: DailyWeather.fromJson(json['daily'] ?? {}),
    );
  }
}

class CurrentWeather {
  final double temperature;
  final double windspeed;
  final int weathercode;
  final int isDay;
  final String time;

  CurrentWeather({
    required this.temperature,
    required this.windspeed,
    required this.weathercode,
    required this.isDay,
    required this.time,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
      windspeed: (json['windspeed'] as num?)?.toDouble() ?? 0.0,
      weathercode: (json['weathercode'] as int?) ?? 0,
      isDay: (json['is_day'] as int?) ?? 1,
      time: json['time'] ?? '',
    );
  }
}

class HourlyWeather {
  final List<String> time;
  final List<double> temperature2m;
  final List<int> weathercode;

  HourlyWeather({
    required this.time,
    required this.temperature2m,
    required this.weathercode,
  });

  factory HourlyWeather.fromJson(Map<String, dynamic> json) {
    return HourlyWeather(
      time: List<String>.from(json['time'] ?? []),
      temperature2m: List<double>.from((json['temperature_2m'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
      weathercode: List<int>.from((json['weathercode'] as List? ?? []).map((x) => (x as num?)?.toInt() ?? 0)),
    );
  }
}

class DailyWeather {
  final List<String> time;
  final List<int> weathercode;
  final List<double> temperature2mMax;
  final List<double> temperature2mMin;

  DailyWeather({
    required this.time,
    required this.weathercode,
    required this.temperature2mMax,
    required this.temperature2mMin,
  });

  factory DailyWeather.fromJson(Map<String, dynamic> json) {
    return DailyWeather(
      time: List<String>.from(json['time'] ?? []),
      weathercode: List<int>.from((json['weathercode'] as List? ?? []).map((x) => (x as num?)?.toInt() ?? 0)),
      temperature2mMax: List<double>.from((json['temperature_2m_max'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
      temperature2mMin: List<double>.from((json['temperature_2m_min'] as List? ?? []).map((x) => (x as num?)?.toDouble() ?? 0.0)),
    );
  }
}
