import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_1/models/weather_model.dart';
import 'package:flutter_1/services/weather_service.dart';
import 'package:flutter_1/utils/constants.dart';
import 'package:flutter_1/utils/weather_utils.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<WeatherData?> _weatherFuture;
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _weatherFuture = _weatherService.fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: FutureBuilder<WeatherData?>(
        future: _weatherFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator(color: Colors.white));
          } else if (snapshot.hasError) {
             // Basic error handling
            return _buildBackground(child: Center(child: Text("Error: ${snapshot.error}", style: AppTheme.desc)));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return _buildBackground(child: Center(child: Text("Unavailable", style: AppTheme.desc)));
          }

          final data = snapshot.data!;
          return _buildBackground(
            code: data.current.weathercode,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 100),
                  // Header
                  Text("My Location", style: AppTheme.city), 
                  Text(
                    "${data.current.temperature.round()}°",
                    style: AppTheme.bigTemp,
                  ),
                  Text(
                    WeatherUtils.getWeatherDescription(data.current.weathercode),
                    style: AppTheme.desc,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "H:${data.daily.temperature2mMax[0].round()}°  L:${data.daily.temperature2mMin[0].round()}°",
                    style: AppTheme.hl,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Hourly Forecast
                  _buildGlassSection(
                    title: "HOURLY FORECAST",
                    icon: CupertinoIcons.clock,
                    child: SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 24, // Show next 24 hours
                        itemBuilder: (context, index) {
                           // Logic to get next hours from current time could be added here
                           // For now, listing straight from the array assuming it starts from now or close to it
                           // Real app needs mapping 'time' string to DateTime
                           final timeStr = data.hourly.time[index];
                           final dt = DateTime.parse(timeStr);
                           final hour = DateFormat('j').format(dt); // 5 PM
                           
                           return Padding(
                             padding: const EdgeInsets.only(right: 20),
                             child: Column(
                               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                               children: [
                                 Text(hour, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                 Icon(
                                    WeatherUtils.getWeatherIcon(data.hourly.weathercode[index]), 
                                    color: Colors.white, size: 24
                                 ),
                                 Text("${data.hourly.temperature2m[index].round()}°", style: const TextStyle(color: Colors.white, fontSize: 16)),
                               ],
                             ),
                           );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Daily Forecast
                  _buildGlassSection(
                    title: "10-DAY FORECAST",
                    icon: CupertinoIcons.calendar,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: data.daily.time.length,
                      itemBuilder: (context, index) {
                        final dt = DateTime.parse(data.daily.time[index]);
                        final dayName = index == 0 ? "Today" : DateFormat('EEEE').format(dt);
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(dayName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500))),
                              Expanded(flex: 1, child: Icon(WeatherUtils.getWeatherIcon(data.daily.weathercode[index]), color: Colors.white)),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text("${data.daily.temperature2mMin[index].round()}°", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18)),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 80,
                                      height: 4,
                                      child: Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                                          ),
                                          // Bar logic complexity omitted for brevity, usually shows range
                                          FractionallySizedBox(
                                            widthFactor: 0.6, // placeholder
                                            child: Container(color: Colors.yellow, height: 4),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text("${data.daily.temperature2mMax[index].round()}°", style: const TextStyle(color: Colors.white, fontSize: 18)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  // Grid Details could go here (UV, Humidity, etc)
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackground({required Widget child, int code = 0}) {
    // Determine gradient based on code
    LinearGradient gradient = AppTheme.sunnyGradient;
    if (code >= 45) gradient = AppTheme.rainyGradient; // Simplified
    // More mapping could be done
    
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(child: child),
    );
  }

  Widget _buildGlassSection({required String title, required IconData icon, required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white54, size: 16),
                  const SizedBox(width: 5),
                  Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(color: Colors.white24),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
