import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WeatherUtils {
  static String getWeatherDescription(int code) {
    switch (code) {
      case 0:
        return 'Quang đãng';
      case 1:
      case 2:
      case 3:
        return 'Có mây vài nơi';
      case 45:
      case 48:
        return 'Sương mù';
      case 51:
      case 53:
      case 55:
        return 'Mưa phùn';
      case 61:
      case 63:
      case 65:
        return 'Mưa';
      case 71:
      case 73:
      case 75:
        return 'Tuyết';
      case 80:
      case 81:
      case 82:
        return 'Mưa to';
      case 95:
      case 96:
      case 99:
        return 'Dông';
      default:
        return 'Không rõ';
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
