import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:flutter_1/ui/widgets/details/average_models.dart';
import 'package:flutter_1/ui/widgets/details/average_painters.dart';

class AverageTempView extends StatelessWidget {
  final double currentMax;
  final double normalMax;
  final double dMin;
  final double dMax;
  final List<double> todayHourly;
  final List<RangeValue> normalRange;
  final bool isCelsius;
  final List<MonthlyAvg> monthlyAvgs;
  final Function(bool) onUnitChanged;

  const AverageTempView({
    super.key,
    required this.currentMax,
    required this.normalMax,
    required this.dMin,
    required this.dMax,
    required this.todayHourly,
    required this.normalRange,
    required this.isCelsius,
    required this.monthlyAvgs,
    required this.onUnitChanged,
  });

  double _convertTemp(double val) {
    if (isCelsius) return val;
    return val * 9 / 5 + 32;
  }

  @override
  Widget build(BuildContext context) {
    double diff = currentMax - normalMax;
    String diffStr = diff > 0 ? "+${diff.round()}°" : "${diff.round()}°";
    if (diff == 0) diffStr = "0°";

    return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        // Main Title
                        Text("$diffStr trên trung bình", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        Text("Cao nhất trung bình: ${_convertTemp(normalMax).round()}°", style: const TextStyle(color: Colors.grey, fontSize: 16)),
                        
                        const SizedBox(height: 24),
                        
                        // CHART
                        Container(
                         height: 300,
                         padding: const EdgeInsets.fromLTRB(10, 20, 15, 10),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                                 Text("Cao hôm nay", style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold)),
                                 Text("${_convertTemp(currentMax).round()}°", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                                 Expanded(
                                     child: CustomPaint(
                                         size: const Size(double.infinity, double.infinity),
                                         painter: AverageChartPainter(
                                             todayData: todayHourly,
                                             normalRange: normalRange,
                                             isCelsius: isCelsius
                                         ),
                                     ),
                                 ),
                                 const SizedBox(height: 10),
                                 // Legend
                                 Row(
                                     children: [
                                         Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                                         const SizedBox(width: 6),
                                         const Text("Hôm nay", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                         const SizedBox(width: 16),
                                         Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.orange.withOpacity(0.3), shape: BoxShape.circle)),
                                         const SizedBox(width: 6),
                                         Text("Phạm vi bình thường (${_convertTemp(dMin - 2).round()}° đến ${_convertTemp(dMax + 2).round()}°)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                     ],
                                 )
                             ]
                         ),
                       ),
                       
                       const SizedBox(height: 32),
                       
                       // SUMMARY
                       const Text("Tóm tắt", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(16),
                         width: double.infinity,
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Text(
                           "Trong ${DateTime.now().day} tháng ${DateTime.now().month}, phạm vi nhiệt độ bình thường là ${_convertTemp(dMin-2).round()}° đến ${_convertTemp(dMax+2).round()}° và nhiệt độ cao nhất trung bình là ${_convertTemp(normalMax).round()}°. Nhiệt độ cao nhất của hôm nay là ${_convertTemp(currentMax).round()}°.",
                           style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                         ),
                       ),

                       const SizedBox(height: 32),
                       
                       // MONTHLY AVERAGES
                       const Text("Trung bình hàng tháng", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                            padding: const EdgeInsets.all(16),
                             decoration: BoxDecoration(
                               color: const Color(0xFF1C1C1E),
                               borderRadius: BorderRadius.circular(16),
                             ),
                           child: Column(
                               children: [
                                   Text("Trong tháng ${DateTime.now().month}, nhiệt độ thấp nhất hàng ngày trung bình là ${_convertTemp(dMin).round()}° và nhiệt độ cao nhất hàng ngày trung bình là ${_convertTemp(dMax).round()}°.",
                                        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)),
                                   const SizedBox(height: 16),
                                   
                                   // Calculate global min/max for scaling
                                   Builder(builder: (context) {
                                       double globalMin = monthlyAvgs.isEmpty ? 0 : monthlyAvgs.map((e) => e.min).reduce(min);
                                       double globalMax = monthlyAvgs.isEmpty ? 100 : monthlyAvgs.map((e) => e.max).reduce(max);
                                       
                                       return Column(
                                           children: monthlyAvgs.asMap().entries.map((e) {
                                               var idx = e.key;
                                               var val = e.value;
                                               bool isCurrent = idx + 1 == DateTime.now().month;
                                               bool isLast = idx == monthlyAvgs.length - 1;
                                               return _buildMonthlyBar(val, isCurrent, globalMin, globalMax, isLast);
                                           }).toList(),
                                       );
                                   }),
                               ]
                           ) 
                       ),
                       
                       const SizedBox(height: 32),
                       
                       // EXPLANATION
                       const Text("Giới thiệu về Phạm vi bình thường", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Text(
                           "Phạm vi bình thường cho biết các nhiệt độ phổ biến nhất trong ${DateTime.now().day} tháng ${DateTime.now().month} tính từ năm 1970 và biểu thị khoảng 80% các mức nhiệt độ. Nếu một phần của đường hôm nay nằm dưới phạm vi bình thường thì phần đó nằm trong 10% thấp nhất của các mức nhiệt độ cho khoảng thời gian đó trong ngày; nếu một phần của đường hôm nay nằm trên phạm vi bình thường thì phần đó nằm trong 10% cao nhất.",
                           style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                         ),
                       ),
                       
                        const SizedBox(height: 24),
                        const Text("Giới thiệu về Nhiệt độ trung bình", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Text(
                           "Giá trị cao nhất trung bình là nhiệt độ cao nhất trung bình trong ${DateTime.now().day} tháng ${DateTime.now().month} của mỗi năm tính từ năm 1970.\n\nCác giá trị trung bình hàng tháng phản ánh nhiệt độ cao nhất và thấp nhất mỗi ngày tính từ năm 1970. Ví dụ: trung bình hàng tháng của tháng 1 sử dụng các giá trị từ 1 tháng 1 đến hết 31 tháng 1 mỗi năm tính từ 1970.",
                           style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                         ),
                       ),
                       
                       const SizedBox(height: 32),
                       
                       // OPTIONS
                       const Text("Tùy chọn", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Column(
                           children: [
                             _buildOptionRow("Đơn vị", isCelsius ? "Sử dụng cài đặt hệ thống (°C)" : "Độ F", 
                                ["Sử dụng cài đặt hệ thống (°C)", "Độ F"], 
                                (val) => onUnitChanged(val.contains("C"))
                             ),
                           ],
                         ),
                       ),

                       const SizedBox(height: 40),
                    ],
                  ),
                ),
              );
  }

  Widget _buildMonthlyBar(MonthlyAvg data, bool isCurrent, double globalMin, double globalMax, bool isLast) {
      double cMin = _convertTemp(data.min);
      double cMax = _convertTemp(data.max);
      
      // Global scale converted
      double scaleMin = _convertTemp(globalMin) - 5; // Add padding
      double scaleMax = _convertTemp(globalMax) + 5;
      
      return Column(
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                  children: [
                      // Month Name
                      SizedBox(width: 80, child: Text(data.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                      
                      // Min Temp
                      SizedBox(width: 40, child: Text("${cMin.round()}°", style: TextStyle(color: Colors.grey[400], fontSize: 16))),
                      
                      // Bar
                      Expanded(
                        child: SizedBox(
                            height: 6, // Thin bar like iOS
                            child: CustomPaint(
                                painter: BarPainter(
                                    min: cMin, 
                                    max: cMax, 
                                    scaleMin: scaleMin, 
                                    scaleMax: scaleMax,
                                    isCurrent: isCurrent
                                ),
                            ),
                        ),
                      ),
                      
                      // Max Temp
                      SizedBox(width: 40, child: Text("${cMax.round()}°", textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontSize: 16))),
                  ]
              )
          ),
          if (!isLast)
             Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
        ],
      );
  }

  Widget _buildOptionRow(String label, String currentVal, List<String> items, Function(String) onChanged) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
                DropdownButton<String>(
                  value: items.contains(currentVal) ? currentVal : items[0],
                  underline: const SizedBox(),
                  dropdownColor: const Color(0xFF2C2C2E),
                  icon: const Icon(Icons.unfold_more, color: Colors.grey, size: 20),
                  style: const TextStyle(color: Colors.grey, fontSize: 12), 
                  items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) {
                      if (val != null) onChanged(val);
                  },
                )
            ],
        ),
      );
  }
}
