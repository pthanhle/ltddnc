import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/ui/screens/weather_detail_screen.dart';
import 'package:flutter_1/ui/widgets/glass_container.dart';
import 'package:flutter_1/ui/widgets/grid_visuals.dart';
import 'package:flutter_1/utils/enums.dart';
import 'package:flutter_1/ui/widgets/sunrise_sunset_card.dart';
import 'package:flutter_1/ui/widgets/details/rainfall_detail_screen.dart';
import 'package:flutter_1/ui/widgets/details/wind_detail_screen.dart';
import 'package:flutter_1/ui/widgets/details/uv_detail_screen.dart';
import 'package:flutter_1/ui/widgets/details/feels_like_detail_screen.dart';
import 'package:flutter_1/ui/widgets/details/humidity_detail_screen.dart';
import 'package:flutter_1/ui/widgets/details/visibility_detail_screen.dart';
import 'package:flutter_1/ui/widgets/details/pressure_detail_screen.dart';
import 'package:flutter_1/ui/widgets/details/average_temp_detail_screen.dart';
import 'package:flutter_1/ui/widgets/wind_card.dart';

class WeatherDetailsGrid extends StatelessWidget {
  final WeatherData weather;
  final double latitude;
  final double longitude;

  const WeatherDetailsGrid({
    super.key, 
    required this.weather,
    required this.latitude,
    required this.longitude,
  });

  void _openDetail(BuildContext context, MetricType type) {
    if (type == MetricType.rain) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => RainfallDetailScreen(weatherData: weather)));
    } else if (type == MetricType.wind) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WindDetailScreen(weatherData: weather, latitude: latitude, longitude: longitude)));
    } else if (type == MetricType.uvIndex) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => UVDetailScreen(weatherData: weather)));
    } else if (type == MetricType.feelsLike) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => FeelsLikeDetailScreen(weatherData: weather)));
    } else if (type == MetricType.humidity) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => HumidityDetailScreen(weatherData: weather)));
    } else if (type == MetricType.visibility) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => VisibilityDetailScreen(weatherData: weather)));
    } else if (type == MetricType.pressure) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PressureDetailScreen(weatherData: weather)));
    } else if (type == MetricType.average) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AverageTempDetailScreen(weatherData: weather)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WeatherDetailScreen(weather: weather, type: type)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPastData = weather.daily.time.length >= 2;
    String tempDiff = "";
    if (hasPastData) {
       final todayMax = weather.daily.temperature2mMax[0]; // Wait, daily lists starts from today? Yes.
       // Comparing "current" to "average" for card?
       // Let's use the same logic as detail screen for consistency
       // Simulate normalMax as 30 for now
       double normalMax = 30; // Hardcoded baseline from detail screen
       double diff = todayMax - normalMax;
       if (diff > 0) tempDiff = "+${diff.round()}°";
       else tempDiff = "${diff.round()}°";
    }

    return Column(
      children: [
        // Grid Section 1: UV and Sunrise
        GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0, 
          children: [
             // UV
            _buildGridItem(
              context,
              type: MetricType.uvIndex,
              icon: CupertinoIcons.sun_max_fill,
              title: "CHỈ SỐ UV",
              value: "${weather.current.uvIndex.round()}", 
              desc: "Thấp đến hết ngày.", // Simplified for now, can be sophisticated later
              contentIsVisual: true,
              visual: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text("${weather.current.uvIndex.round()}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    Text(weather.current.uvIndex < 3 ? "Thấp" : (weather.current.uvIndex < 6 ? "Trung bình" : "Cao"), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    // UV Bar
                    Stack(
                        children: [
                             Container(
                                height: 4,
                                decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Colors.green, Colors.yellow, Colors.orange, Colors.red, Colors.purple]),
                                    borderRadius: BorderRadius.circular(2)
                                ),
                             ),
                             LayoutBuilder(
                               builder: (context, constraints) {
                                   double cur = weather.current.uvIndex;
                                   if (cur > 11) cur = 11;
                                   double maxW = constraints.maxWidth;
                                   if (maxW == 0) maxW = 100; // fallback
                                   double pos = (cur / 11.0) * maxW;
                                   // Clamp
                                   if (pos > maxW - 4) pos = maxW - 4;
                                   
                                   return Transform.translate(
                                       offset: Offset(pos, 0),
                                       child: Container(
                                           width: 4, height: 4, 
                                           decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black, blurRadius: 2)])
                                       )
                                   );
                               }
                             )
                        ]
                    )
                ],
              )
            ),
            
            // Sunrise/Sunset Card
            SunriseSunsetCard(
              daily: weather.daily,
              latitude: latitude,
              longitude: longitude,
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Wind Card (Full Width)
        WindCard(
          weatherData: weather,
          latitude: latitude,
          longitude: longitude,
        ),

        const SizedBox(height: 10),

        // Grid Section 2: Remaining Items
        GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.0, 
          children: [
             // Rain
            _buildGridItem(
              context,
              type: MetricType.rain,
              icon: CupertinoIcons.drop_fill,
              title: "LƯỢNG MƯA",
              value: "${weather.current.precipitation}",
              unit: "mm",
              desc: "Trong 24h qua",
              visual: const RainBarWidget(),
            ),
            
            // AQI
             _buildGridItem(
              context,
              type: MetricType.aqi,
              icon: Icons.air,
              title: "CHẤT LƯỢNG KK",
              value: weather.airQuality != null ? "${weather.airQuality!.usAqi.round()}" : "--",
              desc: _getAqiDesc(weather.airQuality?.usAqi),
              visual: Container(
                height: 4, 
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: const LinearGradient(colors: [Colors.green, Colors.yellow, Colors.orange, Colors.red, Colors.purple])
                ),
              )
            ),

            // Feels Like
             // Feels Like - Custom Layout matching iOS
            _buildGridItem(
              context,
              type: MetricType.feelsLike,
              icon: CupertinoIcons.thermometer,
              title: "CẢM NHẬN",
              value: "${weather.current.apparentTemperature.round()}°",
              desc: "", // We manage content inside visual
              contentIsVisual: true,
              visual: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text("${weather.current.apparentTemperature.round()}°", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(
                      weather.current.apparentTemperature > weather.current.temperature2m 
                        ? "Nhiệt độ cảm nhận ấm hơn nhiệt độ thực tế."
                        : (weather.current.apparentTemperature < weather.current.temperature2m 
                            ? "Nhiệt độ cảm nhận lạnh hơn nhiệt độ thực tế."
                            : "Nhiệt độ cảm nhận phù hợp với nhiệt độ thực tế."),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis
                    )
                ],
              ) 
            ),
            
            // Humidity
            // Humidity
            _buildGridItem(
              context,
              type: MetricType.humidity,
              icon: CupertinoIcons.drop_fill,
              title: "ĐỘ ẨM",
              value: "${weather.current.relativeHumidity2m.round()}%",
              desc: "", 
              contentIsVisual: true,
              visual: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("${weather.current.relativeHumidity2m.round()}%", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                   const Spacer(),
                   Text("Điểm sương là ${_calculateDewPoint(weather.current.temperature2m, weather.current.relativeHumidity2m).round()}° ngay lúc này.", style: const TextStyle(color: Colors.white, fontSize: 13))
                ],
              )
            ),
            
            // Visibility
            // Visibility
            _buildGridItem(
              context,
              type: MetricType.visibility,
              icon: CupertinoIcons.eye_fill,
              title: "TẦM NHÌN",
              value: "${(weather.current.visibility / 1000).round()} km",
              desc: "",
              contentIsVisual: true,
              visual: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                            Text("${(weather.current.visibility / 1000).round()}", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                            const Text(" km", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ]
                    ),
                    const Spacer(),
                    Text(
                      (weather.current.visibility / 1000) >= 10 
                        ? "Tầm nhìn hoàn toàn rõ." 
                        : "Tầm nhìn ${(weather.current.visibility / 1000) >=5 ? "rõ" : "kém"}.",
                      style: const TextStyle(color: Colors.white, fontSize: 13)
                    )
                ],
              )
            ),
            
            // Pressure
            _buildGridItem(
              context,
              type: MetricType.pressure,
              icon: CupertinoIcons.gauge,
              title: "ÁP SUẤT",
              value: "${weather.current.surfacePressure.round()}",
              desc: "",
              contentIsVisual: true,
              visual: Stack(
                alignment: Alignment.center,
                children: [
                    CustomPaint(
                        size: const Size(140, 140),
                        painter: PressureGaugePainter(pressure: weather.current.surfacePressure),
                    ),
                    Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            const SizedBox(height: 10), 
                            Text("${weather.current.surfacePressure.round()}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            const Text("hPa", style: TextStyle(color: Colors.white, fontSize: 14)),
                        ]
                    ),
                    Positioned(
                        bottom: 25,
                        right: 10,
                        child: Text("Cao", style: TextStyle(color: Colors.grey[400], fontSize: 10, fontWeight: FontWeight.bold))
                    ),
                ],
              )
            ),
            
            // Average Temp
            LayoutBuilder(
               builder: (context, constraints) {
                   double todayMax = weather.daily.temperature2mMax[0];
                   double todayMin = weather.daily.temperature2mMin[0];
                   double avgMax = 30; // Hardcoded as in Detail
                   double avgMin = 22;
                   
                   double diff = todayMax - avgMax;
                   String sign = diff > 0 ? "+" : ""; // If diff is 0, no sign? Image shows +2.
                   if (diff == 0) sign = "";

                   return _buildGridItem(
                      context,
                      type: MetricType.average,
                      icon: Icons.show_chart,
                      title: "TRUNG BÌNH",
                      value: "$sign${diff.round()}°",
                      desc: "", // Visual handles it
                      contentIsVisual: true,
                      visual: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text("$sign${diff.round()}°", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text("trên nhiệt độ cao nhất hàng ngày trung bình", style: TextStyle(color: Colors.white, fontSize: 13, height: 1.3), maxLines: 3),
                            const Spacer(),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                    const Text("Hôm nay", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text("C:${todayMax.round()}°", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ]
                            ),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                    const Text("Trung bình", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    Text("C:${avgMax.round()}°", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ]
                            ),
                        ],
                      )
                   );
               }
            ),
            // Cloud Cover
            _buildGridItem(
              context,
              type: MetricType.cloudCover,
              icon: CupertinoIcons.cloud_fill,
              title: "MÂY CHE PHỦ",
              value: "${weather.current.cloudCover}%",
              desc: "",
            ),
          ],
        ),
      ],
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return "$h:$minute";
    } catch (e) {
      return iso;
    }
  }
  
  String _getWindDirection(int degree) {
    const directions = ["B", "BĐB", "ĐB", "ĐĐB", "Đ", "ĐĐN", "ĐN", "NĐN", "N", "NTN", "TN", "TTN", "T", "TTB", "TB", "BTB"];
    int index = ((degree + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  String _getAqiDesc(double? aqi) {
     if (aqi == null) return "Không có dữ liệu";
     if (aqi <= 50) return "Tốt";
     if (aqi <= 100) return "Trung bình";
     if (aqi <= 150) return "Kém cho người nhạy cảm";
     if (aqi <= 200) return "Kém";
     return "Rất kém";
  }
  
  double _calculateDewPoint(double t, double rh) {
    return t - ((100 - rh) / 5);
  }

  Widget _buildGridItem(BuildContext context, {
      required IconData icon, 
      required String title, 
      required String value, 
      String unit = "",
      required String desc,
      MetricType? type,
      bool isLink = true,
      Widget? visual,
      bool contentIsVisual = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isLink && type != null) {
          _openDetail(context, type);
        }
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.white54, size: 14),
                const SizedBox(width: 5),
                Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            
            if (contentIsVisual && visual != null)
               Expanded(child: visual)
            else
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                     Text.rich(
                       TextSpan(
                         children: [
                           TextSpan(text: value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w400)),
                           if (unit.isNotEmpty)
                              TextSpan(text: " $unit", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                         ]
                       )
                     ),
                     if (visual != null) ...[
                        const SizedBox(height: 10),
                        visual,
                     ]
                 ],
               ),
               
            if (!contentIsVisual) const Spacer(),
            Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class PressureGaugePainter extends CustomPainter {
  final double pressure;
  PressureGaugePainter({required this.pressure});

  @override
  void paint(Canvas canvas, Size size) {
    // Center point
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 10;
    
    // Bounds for Pressure (e.g. 960 to 1060 hPa)
    const minP = 960.0;
    const maxP = 1060.0;
    double normalized = (pressure - minP) / (maxP - minP);
    if (normalized < 0) normalized = 0;
    if (normalized > 1) normalized = 1;
    
    // Angles: -220 to 40 degrees? (Start at bottom-left, go clockwise to bottom-right)
    // 0 is right (3 o'clock). 
    // We want 8 o'clock to 4 o'clock.
    // 8 o'clock is 120 + 90? No. 
    // 6 o'clock is 90 deg (pi/2).
    // Let's use radians.
    // Start: 135 deg (bottom right?) -> 405 deg?
    // Let's use standard arc: Start 150 deg (5 pi / 6) to 390 deg (13 pi / 6)?
    // Start angle (radians) = pi - pi/4?
    // Let's say arc spans 240 degrees. Gap at bottom 120 degrees.
    final double startAngle = 150 * pi / 180; // Bottom leftish
    final double sweepAngle = 240 * pi / 180;
    
    final paintTick = Paint()
       ..color = Colors.grey.withOpacity(0.3)
       ..style = PaintingStyle.stroke
       ..strokeWidth = 2;

    final paintActive = Paint()
       ..color = Colors.white
       ..style = PaintingStyle.stroke
       ..strokeWidth = 2;
       
    // Draw Ticks
    int totalTicks = 40;
    for (int i = 0; i <= totalTicks; i++) {
        double angle = startAngle + (sweepAngle * i / totalTicks);
        double r1 = radius;
        double r2 = radius - 8;
        if (i % 5 == 0) r2 = radius - 12; // Major ticks
        
        double x1 = center.dx + r1 * cos(angle);
        double y1 = center.dy + r1 * sin(angle);
        double x2 = center.dx + r2 * cos(angle);
        double y2 = center.dy + r2 * sin(angle);
        
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paintTick);
    }
    
    // Indicator
    double markerAngle = startAngle + (sweepAngle * normalized);
    double mx = center.dx + (radius - 5) * cos(markerAngle);
    double my = center.dy + (radius - 5) * sin(markerAngle);
    
    // Draw a nice marker shape (line or triangle) from inside
    paintActive.strokeWidth = 4;
    paintActive.color = Colors.white;
    canvas.drawLine(Offset(mx, my), Offset(center.dx + (radius - 20) * cos(markerAngle), center.dy + (radius - 20) * sin(markerAngle)), paintActive);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
