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
import 'package:flutter_1/utils/weather_utils.dart';
import 'package:flutter_1/utils/weather_advice.dart';
import 'package:home_widget/home_widget.dart';

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

  String _getEmoji(int code) {
    if (code <= 3) return "☀️";
    if (code <= 48) return "☁️";
    if (code <= 67) return "🌧️";
    return "⛈️";
  }

  // Hàm helper chuyển đổi thứ trong tuần sang tiếng Việt
  String _getDayName(DateTime date) {
    final now = DateTime.now();
    // So sánh ngày/tháng/năm để xác định "Hôm nay" chuẩn xác
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Hôm nay";
    }
    switch (date.weekday) {
      case 1: return "Thứ 2";
      case 2: return "Thứ 3";
      case 3: return "Thứ 4";
      case 4: return "Thứ 5";
      case 5: return "Thứ 6";
      case 6: return "Thứ 7";
      case 7: return "CN";
      default: return "";
    }
  }

  void _updateHomeWidget(dynamic data, dynamic locData) {
    HomeWidget.saveWidgetData('city_name', locData.city.name);
    HomeWidget.saveWidgetData('temperature', data.current.temperature2m.round().toString());
    HomeWidget.saveWidgetData('description', WeatherUtils.getWeatherDescription(data.current.weatherCode));
    HomeWidget.saveWidgetData('weather_emoji', _getEmoji(data.current.weatherCode));


    int todayIndex = 0;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    String high = data.daily.temperature2mMax[todayIndex].round().toString();
    String low = data.daily.temperature2mMin[todayIndex].round().toString();
    HomeWidget.saveWidgetData('high_low', "C:$high° T:$low°");

    // Quét danh sách Hourly để tìm giờ trùng với giờ hiện tại
    int startIndex = 0;
    for (int i = 0; i < data.hourly.time.length; i++) {
      final time = DateTime.parse(data.hourly.time[i]);
      // So sánh khớp cả Ngày và Giờ
      if (time.year == now.year && time.month == now.month && time.day == now.day && time.hour == now.hour) {
        startIndex = i;
        break;
      }
    }

    // Dự báo 6 Giờ tới (HOURLY)
    for (int i = 0; i < 6; i++) {
      int currentIndex = startIndex + i;

      // Kiểm tra để không bị lỗi nếu hết dữ liệu (cuối ngày)
      if (currentIndex >= data.hourly.time.length) break;

      final time = DateTime.parse(data.hourly.time[currentIndex]);

      // Xử lý hiển thị giờ: Cái đầu tiên là "Bây giờ", các cái sau là giờ
      String timeDisplay;
      if (i == 0) {
        timeDisplay = "Bây giờ"; // Hoặc để "${time.hour}h" nếu muốn giống Widget cũ
      } else {
        timeDisplay = "${time.hour}h";
      }

      HomeWidget.saveWidgetData('hourly_time_$i', timeDisplay);
      HomeWidget.saveWidgetData('hourly_temp_$i', "${data.hourly.temperature2m[currentIndex].round()}"); // Chỉ lưu số
      HomeWidget.saveWidgetData('hourly_emoji_$i', _getEmoji(data.hourly.weatherCode[currentIndex]));
    }

    for (int i = 0; i < data.daily.time.length; i++) {
      DateTime d = DateTime.parse(data.daily.time[i]);
      if (DateTime(d.year, d.month, d.day).isAtSameMomentAs(todayDate)) {
        todayIndex = i;
        break;
      }
    }

    // Dự báo 5 Ngày tới (DAILY)
    int count = 0;
    for (int i = todayIndex; i < data.daily.time.length; i++) {
      if (count >= 5) break;

      final date = DateTime.parse(data.daily.time[i]);

      HomeWidget.saveWidgetData('daily_day_$count', _getDayName(date));
      HomeWidget.saveWidgetData('daily_min_$count', "${data.daily.temperature2mMin[i].round()}");
      HomeWidget.saveWidgetData('daily_max_$count', "${data.daily.temperature2mMax[i].round()}");
      HomeWidget.saveWidgetData('daily_icon_$count', _getEmoji(data.daily.weatherCode[i]));

      count++;
    }

    // Cập nhật Widget
    HomeWidget.updateWidget(name: 'WeatherWidget', androidName: 'WeatherWidget');
    HomeWidget.updateWidget(name: 'WeatherWidgetMedium', androidName: 'WeatherWidgetMedium');
    HomeWidget.updateWidget(name: 'WeatherWidgetLarge', androidName: 'WeatherWidgetLarge');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          leading: IconButton(
            onPressed: () { },
            icon: const Icon(CupertinoIcons.list_bullet, color: Colors.white),
          ),
          actions: [
            IconButton(
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

                  _updateHomeWidget(data, locData);

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

                            const SizedBox(height: 20),

                            // TRỢ LÝ THỜI TIẾT
                            Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Column(
                                children: [
                                  const Row(
                                    children: [
                                      Icon(CupertinoIcons.sparkles, color: Colors.white54, size: 16),
                                      SizedBox(width: 5),
                                      Text("TRỢ LÝ THỜI TIẾT", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const Divider(color: Colors.white24),

                                  // Gợi ý trang phục
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.checkroom, color: Colors.white, size: 24),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Text(
                                            WeatherAdvice.getOutfitAdvice(data.current.temperature2m),
                                            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Gợi ý hoạt động
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(CupertinoIcons.sportscourt, color: Colors.white, size: 24),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Text(
                                            WeatherAdvice.getActivityAdvice(
                                                WeatherUtils.getWeatherDescription(data.current.weatherCode)
                                            ),
                                            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

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
                            const Text("Weather App", style: TextStyle(color: Colors.white54)),
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
    } else if (code >= 45 && code <= 90) {
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