import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WeatherUtils {
  static String getWeatherDescription(int code) {
    switch (code) {
      case 0:
        return 'Clear Sky';
      case 1:
      case 2:
      case 3:
        return 'Partly Cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 80:
      case 81:
      case 82:
        return 'Heavy Rain';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }

  static IconData getWeatherIcon(int code) {
    switch (code) {
      case 0:
        return CupertinoIcons.sun_max_fill;
      case 1:
      case 2:
      case 3:
        return CupertinoIcons.cloud_sun_fill;
      case 45:
      case 48:
        return CupertinoIcons.cloud_fog_fill;
      case 51:
      case 53:
      case 55:
        return CupertinoIcons.cloud_drizzle_fill;
      case 61:
      case 63:
      case 65:
        return CupertinoIcons.cloud_rain_fill;
      case 71:
      case 73:
      case 75:
        return CupertinoIcons.snow;
      case 80:
      case 81:
      case 82:
        return CupertinoIcons.cloud_heavyrain_fill;
      case 95:
      case 96:
      case 99:
        return CupertinoIcons.cloud_bolt_fill;
      default:
        return CupertinoIcons.question;
    }
  }
}
