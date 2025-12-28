import 'dart:math';

class SunCalculator {
  static const double _deg2rad = pi / 180.0;
  static const double _rad2deg = 180.0 / pi;

  /// Calculates sunrise and sunset (and other solar events) for a given date and location.
  /// Returns a map with DateTime objects for 'sunrise', 'sunset', 'civil_dawn', 'civil_dusk'.
  static Map<String, DateTime?> calculateSunTimes(DateTime date, double lat, double lon) {
    // Julian Day
    int n = date.difference(DateTime.utc(2000, 1, 1, 12)).inDays;
    double jStar = n - lon / 360.0;
    
    // Solar Noon
    double M = (357.5291 + 0.98560028 * jStar) % 360;
    double C = 1.9148 * sin(M * _deg2rad) + 0.0200 * sin(2 * M * _deg2rad) + 0.0003 * sin(3 * M * _deg2rad);
    double lambda = (M + C + 102.9372 + 180) % 360;
    double Jtransit = 2451545.0 + jStar + 0.0053 * sin(M * _deg2rad) - 0.0069 * sin(2 * lambda * _deg2rad);
    
    // Declination of Sun
    double delta = asin(sin(lambda * _deg2rad) * sin(23.44 * _deg2rad)) * _rad2deg;
    
    // Hour Angle
    double cosOmega = (sin(-0.83 * _deg2rad) - sin(lat * _deg2rad) * sin(delta * _deg2rad)) / (cos(lat * _deg2rad) * cos(delta * _deg2rad));
    
    DateTime? sunrise;
    DateTime? sunset;
    
    if (cosOmega >= -1 && cosOmega <= 1) {
      double omega = acos(cosOmega) * _rad2deg;
      double Jrise = Jtransit - omega / 360.0;
      double Jset = Jtransit + omega / 360.0;
      
      sunrise = _julianToDateTime(Jrise);
      sunset = _julianToDateTime(Jset);
    }

    // Civil Dawn/Dusk (6 degrees below horizon)
    double cosOmegaCivil = (sin(-6.0 * _deg2rad) - sin(lat * _deg2rad) * sin(delta * _deg2rad)) / (cos(lat * _deg2rad) * cos(delta * _deg2rad));
    
    DateTime? civilDawn;
    DateTime? civilDusk;

    if (cosOmegaCivil >= -1 && cosOmegaCivil <= 1) {
      double omegaCivil = acos(cosOmegaCivil) * _rad2deg;
      double JcivilRise = Jtransit - omegaCivil / 360.0;
      double JcivilSet = Jtransit + omegaCivil / 360.0;
      
      civilDawn = _julianToDateTime(JcivilRise);
      civilDusk = _julianToDateTime(JcivilSet);
    }

    return {
      'sunrise': sunrise?.toLocal(),
      'sunset': sunset?.toLocal(),
      'first_light': civilDawn?.toLocal(),
      'last_light': civilDusk?.toLocal(),
    };
  }
  
  static DateTime _julianToDateTime(double J) {
    double z = J + 0.5;
    double f = z - z.floor();
    int a = z.floor(); // Integer part
    
    int alpha = ((a - 1867216.25) / 36524.25).floor();
    a = a + 1 + alpha - (alpha / 4.0).floor();
    
    int b = a + 1524;
    int c = ((b - 122.1) / 365.25).floor();
    int d = (365.25 * c).floor();
    int e = ((b - d) / 30.6001).floor();
    
    int day = b - d - (30.6001 * e).floor();
    int month = (e < 14) ? e - 1 : e - 13;
    int year = (month > 2) ? c - 4716 : c - 4715;
    
    // Time from fraction f
    double hours = f * 24.0;
    int h = hours.floor();
    double minutes = (hours - h) * 60;
    int m = minutes.floor();
    double seconds = (minutes - m) * 60;
    int s = seconds.floor();
    
    return DateTime.utc(year, month, day, h, m, s);
  }

  /// Calculates Monthly Average Sunrise/Sunset for the given year and location.
  /// Returns List of Maps for each month.
  static List<Map<String, dynamic>> getMonthlyAverages(int year, double lat, double lon) {
    List<Map<String, dynamic>> results = [];
    for (int i = 1; i <= 12; i++) {
      // Calculate for the 15th of each month to approximate average
      DateTime date = DateTime.utc(year, i, 15);
      Map<String, DateTime?> times = calculateSunTimes(date, lat, lon);
      
      if (times['sunrise'] != null && times['sunset'] != null) {
        Duration dayLength = times['sunset']!.difference(times['sunrise']!);
        results.add({
          'month': i,
          'sunrise': times['sunrise'],
          'sunset': times['sunset'],
          'day_length': dayLength,
        });
      }
    }
    return results;
  }
  
  /// Get sun elevation at a specific time
  static double getSunElevation(DateTime time, double lat, double lon) {
     DateTime utcTime = time.toUtc();
     // Julian date
     double jd = _toJulian(utcTime);
     
     double d = jd - 2451545.0;  // Days since J2000
    
     // Keplerian elements
     double L = (280.460 + 0.9856474 * d) % 360;
     double g = (357.528 + 0.9856003 * d) % 360;
     
     double lambda = L + 1.915 * sin(g * _deg2rad) + 0.020 * sin(2 * g * _deg2rad);
     double epsilon = 23.439 - 0.0000004 * d;
     
     double alpha = atan2(cos(epsilon * _deg2rad) * sin(lambda * _deg2rad), cos(lambda * _deg2rad)) * _rad2deg;
     double delta = asin(sin(epsilon * _deg2rad) * sin(lambda * _deg2rad)) * _rad2deg;
     
     // Greenwich Mean Sidereal Time
     double gmst = 6.697375 + 0.0657098242 * d + utcTime.hour + utcTime.minute / 60.0 + utcTime.second / 3600.0;
     // Local Mean Sidereal Time
     double lmst = (gmst * 15 + lon) % 360;
     
     double H = (lmst - alpha + 360) % 360; // Hour angle
     if (H > 180) H -= 360;

     double elevation = asin(sin(lat * _deg2rad) * sin(delta * _deg2rad) + cos(lat * _deg2rad) * cos(delta * _deg2rad) * cos(H * _deg2rad)) * _rad2deg;
     return elevation;
  }
  
  static double _toJulian(DateTime date) {
    return date.millisecondsSinceEpoch / 86400000.0 + 2440587.5;
  }

  /// Calculates the longest day of the year (Summer Solstice)
  static Map<String, dynamic> getLongestDayOfYear(int year, double lat, double lon) {
    // Solstices are approx Dec 21 and June 21.
    // Check both to be safe (latitude dependency handled)
    DateTime june = DateTime.utc(year, 6, 21);
    DateTime dec = DateTime.utc(year, 12, 21);
    
    Map<String, DateTime?> t1 = calculateSunTimes(june, lat, lon);
    Map<String, DateTime?> t2 = calculateSunTimes(dec, lat, lon);
    
    Duration d1 = Duration.zero;
    Duration d2 = Duration.zero;
    
    if (t1['sunrise'] != null && t1['sunset'] != null) {
      d1 = t1['sunset']!.difference(t1['sunrise']!);
    }
    
    if (t2['sunrise'] != null && t2['sunset'] != null) {
      d2 = t2['sunset']!.difference(t2['sunrise']!);
    }
    
    if (d1 > d2) {
      return {'date': june, 'duration': d1};
    } else {
      return {'date': dec, 'duration': d2}; // Handling Southern hemisphere automatically results in longer dec day
    }
  }
}
