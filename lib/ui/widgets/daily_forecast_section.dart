import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// Đảm bảo import đúng đường dẫn model của bạn
import 'package:flutter_1/data/models/weather_model.dart';
import 'package:flutter_1/utils/weather_utils.dart';
import 'package:intl/intl.dart';

class DailyForecastSection extends StatelessWidget {
  final WeatherData weather;

  const DailyForecastSection({super.key, required this.weather});

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    // 1. LỌC NGÀY (Logic cũ của bạn)
    List<int> validIndices = [];
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < weather.daily.time.length; i++) {
      DateTime d = DateTime.parse(weather.daily.time[i]);
      if (!d.isBefore(today)) {
        validIndices.add(i);
      }
    }

    // 2. TÌM MIN/MAX TOÀN CỤC (Logic cũ của bạn)
    double globalMin = 100;
    double globalMax = -100;
    for (var i in validIndices) {
      double low = weather.daily.temperature2mMin[i];
      double high = weather.daily.temperature2mMax[i];
      if (low < globalMin) globalMin = low;
      if (high > globalMax) globalMax = high;
    }

    // 3. GIAO DIỆN
    return Container(
      padding: const EdgeInsets.all(16),
      // Thay GlassContainer bằng Container có màu mờ để tránh lỗi thiếu file
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
              const Icon(CupertinoIcons.calendar, color: Colors.white54, size: 16),
              const SizedBox(width: 5),
              Text(
                "DỰ BÁO 10 NGÀY",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12, height: 1),

          ListView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: validIndices.length,
            itemBuilder: (context, index) {
              int dataIndex = validIndices[index];
              final dt = DateTime.parse(weather.daily.time[dataIndex]);

              // Xử lý tên ngày
              String dayName;
              if (_isToday(dt)) {
                dayName = "Hôm nay";
              } else {
                // Format tiếng Việt: Th 2, Th 3...
                dayName = DateFormat('E', 'vi').format(dt);
                // Fix lỗi font chữ nếu thư viện trả về tiếng Anh
                if (dayName == 'Mon') dayName = 'Th 2';
                else if (dayName == 'Tue') dayName = 'Th 3';
                else if (dayName == 'Wed') dayName = 'Th 4';
                else if (dayName == 'Thu') dayName = 'Th 5';
                else if (dayName == 'Fri') dayName = 'Th 6';
                else if (dayName == 'Sat') dayName = 'Th 7';
                else if (dayName == 'Sun') dayName = 'CN';
              }

              final min = weather.daily.temperature2mMin[dataIndex].round();
              final max = weather.daily.temperature2mMax[dataIndex].round();
              // Lưu ý: Kiểm tra file model, thường là weathercode (chữ thường)
              final code = weather.daily.weatherCode[dataIndex];

              // Tính toán thanh nhiệt độ
              double range = globalMax - globalMin;
              if (range == 0) range = 1;
              double startPct = (weather.daily.temperature2mMin[dataIndex] - globalMin) / range;
              double lengthPct = (weather.daily.temperature2mMax[dataIndex] - weather.daily.temperature2mMin[dataIndex]) / range;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    // Cột 1: Thứ
                    Expanded(
                      flex: 3, // Giảm flex xuống chút cho cân đối
                      child: Text(dayName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16, // Font 18 hơi to, để 16 đẹp hơn
                              fontWeight: FontWeight.w500)),
                    ),

                    // Cột 2: Icon
                    Expanded(
                      flex: 3,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Icon(WeatherUtils.getWeatherIcon(code), color: Colors.white, size: 24),
                          ]
                      ),
                    ),

                    // Cột 3: Thanh nhiệt độ (PHẦN ĐÃ SỬA LỖI)
                    Expanded(
                      flex: 8,
                      child: Row(
                        children: [
                          SizedBox(
                            width: 35,
                            child: Text("$min°",
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 16)), // Font 16
                          ),
                          const SizedBox(width: 5),

                          // --- ĐOẠN CODE SỬA LỖI ---
                          // Đưa LayoutBuilder ra ngoài cùng để lấy kích thước
                          Expanded(
                            child: SizedBox(
                              height: 4,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  double w = constraints.maxWidth;
                                  // Stack phải nằm TRONG LayoutBuilder
                                  return Stack(
                                    children: [
                                      // Nền xám
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white12,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      // Thanh màu (Positioned nằm trực tiếp trong Stack -> OK)
                                      Positioned(
                                          left: w * startPct,
                                          width: (w * lengthPct) < 1 ? 1 : (w * lengthPct),
                                          top: 0,
                                          bottom: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                  colors: [Colors.greenAccent, Colors.orangeAccent]),
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          )
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                          // -------------------------

                          const SizedBox(width: 5),
                          SizedBox(
                            width: 35,
                            child: Text("$max°",
                                textAlign: TextAlign.end,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}