import 'package:flutter_1/data/models/weather_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:intl/intl.dart'; 
import 'package:flutter_1/ui/widgets/details/average_models.dart';
import 'package:flutter_1/ui/widgets/details/average_temp_view.dart';
import 'package:flutter_1/ui/widgets/details/average_rain_view.dart';
import 'package:flutter/material.dart';

class AverageTempDetailScreen extends StatefulWidget {
  final WeatherData weatherData;

  const AverageTempDetailScreen({super.key, required this.weatherData});

  @override
  State<AverageTempDetailScreen> createState() => _AverageTempDetailScreenState();
}

class _AverageTempDetailScreenState extends State<AverageTempDetailScreen> {
  bool _isCelsius = true;
  
  bool _isRainfall = false;
  bool _isLoading = true;

  // Real "Climate Normal" Data from Archive
  List<MonthlyAvg> _monthlyAvgs = [];
  List<double> _monthlyRain = []; 
  
  // Rainfall Detail Data
  List<double> _recent30DaysRain = [];
  List<double> _normal30DaysRain = [];
  String _rainUnit = "mm"; // mm, cm, in
  
  // 30 day sum
  double _sumRecent30 = 0;
  double _sumNormal30 = 0; 
  
  @override
  void initState() {
    super.initState();
    _fetchClimateData();
  }
  
  Future<void> _fetchClimateData() async {
    final lat = widget.weatherData.latitude;
    final lon = widget.weatherData.longitude;
    // Using 2023 as the full historical year
    // 1. Fetch Normals (using 2023)
    final urlNormal = Uri.parse("https://archive-api.open-meteo.com/v1/archive?latitude=$lat&longitude=$lon&start_date=2023-01-01&end_date=2023-12-31&daily=temperature_2m_max,temperature_2m_min,precipitation_sum&timezone=auto");
    
    // 2. Fetch Recent 30 Days History (Archive has ~1-2 day lag)
    DateTime now = DateTime.now();
    DateTime endDate = now.subtract(const Duration(days: 2)); 
    DateTime start30 = endDate.subtract(const Duration(days: 29)); // 30 days total
    String sDate = DateFormat('yyyy-MM-dd').format(start30);
    String eDate = DateFormat('yyyy-MM-dd').format(endDate);
    final urlRecent = Uri.parse("https://archive-api.open-meteo.com/v1/archive?latitude=$lat&longitude=$lon&start_date=$sDate&end_date=$eDate&daily=precipitation_sum&timezone=auto");

    try {
      final resNormal = await http.get(urlNormal);
      final resRecent = await http.get(urlRecent);

      if (resNormal.statusCode == 200 && resRecent.statusCode == 200) {
        final dataNormal = jsonDecode(resNormal.body);
        final dataRecent = jsonDecode(resRecent.body);
        
        _processClimateData(dataNormal);
        _processRainDetailData(dataNormal, dataRecent);
      } else {
        print("Error fetching climate data: ${resNormal.statusCode} | ${resRecent.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch(e) {
      print("Exception fetching climate data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _processClimateData(Map<String, dynamic> data) {
    if (data['daily'] == null) return;

    final daily = data['daily'];
    final time = List<String>.from(daily['time']);
    final maxT = List<double>.from(daily['temperature_2m_max'].map((x) => (x as num?)?.toDouble() ?? 0.0));
    final minT = List<double>.from(daily['temperature_2m_min'].map((x) => (x as num?)?.toDouble() ?? 0.0));
    final rain = List<double>.from(daily['precipitation_sum'].map((x) => (x as num?)?.toDouble() ?? 0.0));

    Map<int, List<double>> monthMax = {};
    Map<int, List<double>> monthMin = {};
    Map<int, double> monthRain = {};

    for(int i=0; i<time.length; i++) {
      DateTime date = DateTime.parse(time[i]);
      int m = date.month;
      
      monthMax.putIfAbsent(m, () => []).add(maxT[i]);
      monthMin.putIfAbsent(m, () => []).add(minT[i]);
      monthRain.update(m, (value) => value + rain[i], ifAbsent: () => rain[i]);
    }

    List<MonthlyAvg> avgs = [];
    List<double> rains = [];

    for(int m=1; m<=12; m++) {
       if (monthMax.containsKey(m)) {
         double avgMax = monthMax[m]!.reduce((a,b)=>a+b) / monthMax[m]!.length;
         double avgMin = monthMin[m]!.reduce((a,b)=>a+b) / monthMin[m]!.length;
         avgs.add(MonthlyAvg("Tháng $m", avgMin, avgMax));
         rains.add(monthRain[m] ?? 0.0);
       }
    }

    setState(() {
      _monthlyAvgs = avgs;
      _monthlyRain = rains;
      _isLoading = false;
    });
  }

  void _processRainDetailData(Map<String, dynamic> normalData, Map<String, dynamic> recentData) {
      if (recentData['daily'] == null) return;
      
      // Recent 30 days
      List<double> recent = List<double>.from(recentData['daily']['precipitation_sum'].map((x) => (x as num?)?.toDouble() ?? 0.0));
      
      // Normal 30 days (Calculate average cumulative from 'normalData' matching days)
      List<String> recentDates = List<String>.from(recentData['daily']['time']);
      List<String> normalDates = List<String>.from(normalData['daily']['time']);
      List<double> normalRain = List<double>.from(normalData['daily']['precipitation_sum'].map((x) => (x as num?)?.toDouble() ?? 0.0));
      
      List<double> matchedNormal = [];
      
      for(String dStr in recentDates) {
          DateTime d = DateTime.parse(dStr);
          // Match Month-Day
          int idx = normalDates.indexWhere((nd) {
              DateTime n = DateTime.parse(nd);
              return n.month == d.month && n.day == d.day;
          });
          if (idx != -1) {
              matchedNormal.add(normalRain[idx]);
          } else {
              matchedNormal.add(0.0);
          }
      }
      
      // Calculate Cumulative for Chart
      List<double> cumRecent = [];
      double rSum = 0;
      for(var r in recent) {
          rSum += r;
          cumRecent.add(rSum);
      }
      
      List<double> cumNormal = [];
      double nSum = 0;
      for(var r in matchedNormal) {
          nSum += r;
          cumNormal.add(nSum);
      }
      
      setState(() {
          _recent30DaysRain = cumRecent;
          _normal30DaysRain = cumNormal;
          _sumRecent30 = rSum;
          _sumNormal30 = nSum;
      });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading || _monthlyAvgs.isEmpty) {
        return const Scaffold(
            backgroundColor: Colors.black, 
            body: Center(child: CircularProgressIndicator(color: Colors.white))
        );
    }

    // Data preparation for sub-views
    double currentMax = widget.weatherData.daily.temperature2mMax[0];
    double normalMax = _monthlyAvgs[DateTime.now().month - 1].max;
    // Normal Range Calculation
    double dMin = _monthlyAvgs[DateTime.now().month - 1].min; 
    double dMax = _monthlyAvgs[DateTime.now().month - 1].max;
    
    // Hourly Data
    final now = DateTime.now();
    List<double> todayHourly = [];
    List<String> times = widget.weatherData.hourly.time;
    for(int i=0; i<times.length; i++) {
        DateTime t = DateTime.parse(times[i]);
        if (t.year == now.year && t.month == now.month && t.day == now.day) {
            todayHourly.add(widget.weatherData.hourly.temperature2m[i]);
        }
    }
    
    // Range Data (Example generation)
    List<RangeValue> normalRange = [];
    for(int i=0; i<24; i++) {
        double tMin = dMin - 2 + sin(i/24 * pi) * 2; 
        double tMax = dMax + 2 - cos(i/24 * pi) * 2;
        if (i < 6) { tMin -= 2; tMax -= 3; } 
        else if (i > 18) { tMin -= 1; tMax -= 2; }
        else { tMin += 1; tMax += 2; }
        
        normalRange.add(RangeValue(tMin, tMax));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                Icon(Icons.show_chart, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text("Trung bình", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
            ]
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
           // Toggle Header
           Container(
               margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
               padding: const EdgeInsets.all(2),
               decoration: BoxDecoration(
                   color: const Color(0xFF1C1C1E),
                   borderRadius: BorderRadius.circular(8),
               ),
               child: Row(
                   children: [
                       Expanded(
                           child: GestureDetector(
                               onTap: () => setState(() => _isRainfall = false),
                               child: Container(
                                   padding: const EdgeInsets.symmetric(vertical: 6),
                                   decoration: BoxDecoration(
                                       color: !_isRainfall ? const Color(0xFF48484A) : Colors.transparent,
                                       borderRadius: BorderRadius.circular(6),
                                   ),
                                   alignment: Alignment.center,
                                   child: const Text("Nhiệt độ", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                               ),
                           ),
                       ),
                       Expanded(
                           child: GestureDetector(
                               onTap: () => setState(() => _isRainfall = true),
                               child: Container(
                                   padding: const EdgeInsets.symmetric(vertical: 6),
                                   decoration: BoxDecoration(
                                       color: _isRainfall ? const Color(0xFF48484A) : Colors.transparent,
                                       borderRadius: BorderRadius.circular(6),
                                   ),
                                   alignment: Alignment.center,
                                   child: const Text("Lượng mưa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                               ),
                           ),
                       ),
                   ],
               ),
           ),
           
           Expanded(
               child: _isRainfall 
                 ? AverageRainView(
                     monthlyAvgs: _monthlyAvgs,
                     monthlyRain: _monthlyRain,
                     sumRecent30: _sumRecent30,
                     sumNormal30: _sumNormal30,
                     recent30DaysRain: _recent30DaysRain,
                     normal30DaysRain: _normal30DaysRain,
                     rainUnit: _rainUnit,
                     onUnitChanged: (val) => setState(() => _rainUnit = val),
                   ) 
                 : AverageTempView(
                     currentMax: currentMax,
                     normalMax: normalMax,
                     dMin: dMin,
                     dMax: dMax,
                     todayHourly: todayHourly,
                     normalRange: normalRange,
                     isCelsius: _isCelsius,
                     monthlyAvgs: _monthlyAvgs,
                     onUnitChanged: (isC) => setState(() => _isCelsius = isC),
                   )
           ),
        ],
      ),
    );
  }
}
