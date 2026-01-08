import 'package:flutter/material.dart';
import 'package:flutter_1/logic/providers/weather_provider.dart';
import 'package:flutter_1/ui/screens/search_screen.dart';
import 'package:flutter_1/utils/weather_utils.dart';
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CityListScreen extends StatefulWidget {
  const CityListScreen({super.key});

  @override
  State<CityListScreen> createState() => _CityListScreenStateV2();
}

class _CityListScreenStateV2 extends State<CityListScreen> {
  @override
  Widget build(BuildContext context) {
    debugPrint("Building CityListScreen V2");
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Quản lý thành phố", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, provider, child) {
          final locations = provider.locations;
          
          if (locations.isEmpty) {
             return const Center(child: Text("Chưa có thành phố nào.", style: TextStyle(color: Colors.white54)));
          }

          return Column(
            children: [
              // Search Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: GestureDetector(
                  onTap: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Colors.white54),
                        SizedBox(width: 8),
                        Text("Tìm tên thành phố/sân bay", style: TextStyle(color: Colors.white54, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    return _buildCityCard(location, index == 0, index, provider); 
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _buildCityCard(LocationWeatherData location, bool isMyLocation, int index, WeatherProvider provider) {
    String temp = "--";
    String max = "--";
    String min = "--";
    String desc = "";
    int code = 0;
    
    if (location.data != null) {
       final current = location.data!.current;
       final daily = location.data!.daily;
       temp = "${current.temperature2m.round()}°";
       if (daily.temperature2mMax.isNotEmpty) max = "${daily.temperature2mMax[0].round()}°";
       if (daily.temperature2mMin.isNotEmpty) min = "${daily.temperature2mMin[0].round()}°";
       desc = WeatherUtils.getWeatherDescription(current.weatherCode);
       code = current.weatherCode;
    } else if (location.isLoading) {
       desc = "Đang tải...";
    } else if (location.error.isNotEmpty) {
       desc = "Lỗi";
    }

    // Determine background based on weather code or defaults
    LinearGradient bgGradient;
    if (code >= 71) { // Snow
       bgGradient = const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFFBDC3C7)]); 
    } else if (code >= 51) { // Rain
       bgGradient = const LinearGradient(colors: [Color(0xFF373B44), Color(0xFF4286f4)]);
    } else if (isMyLocation) { 
       bgGradient = const LinearGradient(colors: [Color(0xFF4B6CB7), Color(0xFF182848)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    } else {
       // Cloud/Sun generic
       bgGradient = const LinearGradient(colors: [Color(0xFF597FA3), Color(0xFF3B5574)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    }

    return GestureDetector(
      onTap: () {
        provider.setCurrentIndex(index);
        Navigator.pop(context);
      },
      child: Container(
        height: 110,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          gradient: bgGradient,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.city.name,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 2),
                    if (isMyLocation)
                      const Text("Vị trí của tôi", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))
                    else
                         Text(DateFormat('HH:mm').format(DateTime.now()), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
                Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Text(temp, style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w300)),
                 Text("C:$max T:$min", style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
