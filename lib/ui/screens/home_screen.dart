import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_1/logic/providers/weather_provider.dart';
import 'package:flutter_1/ui/screens/search_screen.dart';
import 'package:flutter_1/ui/widgets/current_weather_header.dart';
import 'package:flutter_1/ui/widgets/daily_forecast_section.dart';
import 'package:flutter_1/ui/widgets/hourly_forecast_section.dart';
import 'package:flutter_1/ui/widgets/precipitation_map_card.dart';
import 'package:flutter_1/ui/widgets/weather_details_grid.dart';
import 'package:flutter_1/utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton( // Nút Menu/List
          onPressed: () {
             // In real iOS app this opens the list of cities
          },
          icon: const Icon(CupertinoIcons.list_bullet, color: Colors.white),
        ),
        actions: [
          IconButton( // Nút Thêm
             onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
             },
             icon: const Icon(CupertinoIcons.add, color: Colors.white),
          )
        ]
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, provider, child) {
          if (provider.locations.isEmpty) {
             return _buildBackground(child: const Center(child: CupertinoActivityIndicator(color: Colors.white)));
          }

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: provider.locations.length,
                onPageChanged: (index) {
                   provider.setCurrentIndex(index);
                },
                itemBuilder: (context, index) {
                  final locData = provider.locations[index];
                  
                  if (locData.isLoading) {
                     return _buildBackground(child: const Center(child: CupertinoActivityIndicator(color: Colors.white, radius: 20)));
                  }
                  
                  if (locData.error.isNotEmpty) {
                     return _buildBackground(child: Center(child: Text("Error: ${locData.error}", style: AppTheme.desc)));
                  }
                  
                  if (locData.data == null) return _buildBackground(child: const SizedBox());

                  final data = locData.data!;
                  final isDay = data.current.isDay == 1;
                  
                  return _buildBackground(
                    isDay: isDay,
                    code: data.current.weatherCode,
                    child: RefreshIndicator(
                      onRefresh: () => provider.refreshAll(),
                      color: Colors.white,
                      backgroundColor: Colors.transparent,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            CurrentWeatherHeader(weather: data, city: locData.city, isMyLocation: index == 0),
                            
                            const SizedBox(height: 40),
                            
                            HourlyForecastSection(weather: data),
          
                            const SizedBox(height: 20),
          
                            DailyForecastSection(weather: data),
                            
                            const SizedBox(height: 20),

                            PrecipitationMapCard(latitude: locData.city.latitude, longitude: locData.city.longitude),
                            
                            const SizedBox(height: 20),
                            
                            WeatherDetailsGrid(
                              weather: data,
                              latitude: locData.city.latitude,
                              longitude: locData.city.longitude,
                            ),
                            
                            const SizedBox(height: 40),
                            Text("Weather App", style: TextStyle(color: Colors.white54)),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SmoothPageIndicator(
                    controller: _pageController,
                    count: provider.locations.length,
                    effect: const WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      activeDotColor: Colors.white,
                      dotColor: Colors.white24,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground({required Widget child, int code = 0, bool isDay = true}) {
    LinearGradient gradient;
    if (!isDay) {
        gradient = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF081831), Color(0xFF16253D)],
        );
    } else if (code >= 45 && code <= 90) { // Cloudy/Rainy
        gradient = AppTheme.rainyGradient;
    } else {
        gradient = AppTheme.sunnyGradient;
    }
    
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      constraints: const BoxConstraints.expand(),
      child: SafeArea(child: child),
    );
  }
}
