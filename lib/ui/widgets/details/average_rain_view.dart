import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:flutter_1/ui/widgets/details/average_models.dart';
import 'package:flutter_1/ui/widgets/details/average_painters.dart';

class AverageRainView extends StatelessWidget {
    final List<MonthlyAvg> monthlyAvgs;
    final List<double> monthlyRain;
    final double sumRecent30;
    final double sumNormal30;
    final List<double> recent30DaysRain;
    final List<double> normal30DaysRain;
    final String rainUnit;
    final Function(String) onUnitChanged;

    const AverageRainView({
        super.key,
        required this.monthlyAvgs,
        required this.monthlyRain,
        required this.sumRecent30,
        required this.sumNormal30,
        required this.recent30DaysRain,
        required this.normal30DaysRain,
        required this.rainUnit,
        required this.onUnitChanged,
    });

  double _convertRain(double mm) {
      if (rainUnit == "cm") return mm / 10.0;
      if (rainUnit == "in") return mm / 25.4;
      return mm;
  }
  String _getRainUnitSymbol() {
      if (rainUnit == "in") return "\""; // inch symbol? or "in"
      return rainUnit;
  }

  @override
  Widget build(BuildContext context) {
      // Annual total
      // double annual = monthlyRain.isEmpty ? 0 : monthlyRain.reduce((a, b) => a + b);
      // Removed annual per new design, uses comparison
      
      double diff = sumRecent30 - sumNormal30;
      String diffSign = diff > 0 ? "+" : "";
      String diffStr = "$diffSign${_convertRain(diff).toStringAsFixed(1)} ${_getRainUnitSymbol()}";
      
      DateTime now = DateTime.now();
      DateTime start30 = now.subtract(const Duration(days: 30));
      
      return SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text("$diffStr so với trung bình", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      Text("Trung bình 30 ngày: ${_convertRain(sumNormal30).toStringAsFixed(0)} ${_getRainUnitSymbol()}", style: const TextStyle(color: Colors.grey, fontSize: 16)),
                      
                      const SizedBox(height: 24),
                      
                      // CHART
                      Container(
                         height: 320,
                         padding: const EdgeInsets.all(16),
                         decoration: BoxDecoration(
                           color: const Color(0xFF1C1C1E),
                           borderRadius: BorderRadius.circular(16),
                         ),
                         child: Column(
                             children: [
                                 // Legend / Header values
                                 Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                         Text("${_convertRain(sumNormal30).toStringAsFixed(0)} ${_getRainUnitSymbol()}", style: const TextStyle(color: Colors.grey, fontSize: 28, fontWeight: FontWeight.bold)),
                                         Text("${_convertRain(sumRecent30).toStringAsFixed(0)} ${_getRainUnitSymbol()}", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                                     ],
                                 ),
                                 const SizedBox(height: 10),
                                 Expanded(
                                     child: CustomPaint(
                                         size: const Size(double.infinity, double.infinity),
                                         painter: RainChartPainter(
                                             recentData: recent30DaysRain,
                                             normalData: normal30DaysRain,
                                             unit: rainUnit
                                         ),
                                     ),
                                 ),
                                 const SizedBox(height: 10),
                                 Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                        const Text("30 ngày trước", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        const Text("Hôm nay", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                    ]
                                 ),
                                 const SizedBox(height: 10),
                                 Row(
                                      children: [
                                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                                          const SizedBox(width: 6),
                                          const Text("30 ngày qua", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                          const SizedBox(width: 16),
                                          Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                                          const SizedBox(width: 6),
                                          const Text("Trung bình", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                  )
                             ]
                         )
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // SUMMARY
                      const Text("Tóm tắt", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                               color: const Color(0xFF1C1C1E),
                               borderRadius: BorderRadius.circular(16),
                           ),
                           child: Text(
                               "Trước đây, tổng lượng mưa trung bình cho khoảng thời gian từ ${start30.day} tháng ${start30.month} đến ${now.day} tháng ${now.month} là ${_convertRain(sumNormal30).toStringAsFixed(1)} ${_getRainUnitSymbol()}. Tính đến hôm nay, tổng lượng mưa cho 30 ngày qua là ${_convertRain(sumRecent30).toStringAsFixed(1)} ${_getRainUnitSymbol()}.",
                               style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)
                           )
                      ),

                      const SizedBox(height: 32),
                      
                      // Monthly breakdown
                      const Text("Trung bình hàng tháng", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      
                      // Header for monthly section
                       Container(
                           width: double.infinity,
                           padding: const EdgeInsets.all(16),
                           decoration: const BoxDecoration(
                               color: Color(0xFF1C1C1E),
                               borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                           ),
                           child: Text(
                               "Trong tháng ${now.month}, tổng lượng mưa trung bình là ${_convertRain(monthlyRain.isNotEmpty ? monthlyRain[now.month-1] : 0).toStringAsFixed(1)} ${_getRainUnitSymbol()}.",
                               style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5)
                           )
                       ),
                      Container(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          decoration: const BoxDecoration(
                              color: Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                          ),
                          child: Builder(builder: (context) {
                               double globalMax = monthlyRain.isEmpty ? 100 : monthlyRain.reduce(max);
                               return Column(
                                  children: monthlyRain.asMap().entries.map((e) {
                                      return _buildRainMonthlyBar(e.key, e.value, globalMax, e.key == monthlyRain.length - 1);
                                  }).toList()
                               );
                          })
                      ),
                       
                       const SizedBox(height: 32),
                       
                       // About Rain
                       const Text("Giới thiệu về Lượng mưa trung bình", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                       const SizedBox(height: 12),
                       Container(
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                               color: const Color(0xFF1C1C1E),
                               borderRadius: BorderRadius.circular(16),
                           ),
                           child: const Text(
                               "Các giá trị lượng mưa trung bình được dựa trên lượng mưa tính từ năm 1970. Khi có tuyết rơi, giá trị lượng mưa trung bình sử dụng độ ẩm dạng chất lỏng tương đương, là lượng nước nếu tuyết tan chứ không phải là độ dày của tuyết.\n\nCác giá trị trung bình hàng tháng phản ánh tổng lượng mưa trung bình tính từ năm 1970. Ví dụ: trung bình hàng tháng của tháng 1 sử dụng các giá trị từ 1 tháng 1 đến hết 31 tháng 1 mỗi năm tính từ năm 1970.",
                               style: TextStyle(color: Colors.white, fontSize: 15, height: 1.5)
                           )
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
                              _buildOptionRow("Đơn vị", rainUnit == "in" ? "inch" : (rainUnit == "cm" ? "cm" : "mm"), 
                                 ["mm", "cm", "inch"], 
                                 (val) => onUnitChanged(val == "inch" ? "in" : val)
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                  ]
              )
          )
      );
  }

  Widget _buildRainMonthlyBar(int idx, double val, double globalMax, bool isLast) {
      double cVal = _convertRain(val);
      double cMax = _convertRain(globalMax);
      bool isCurrent = idx + 1 == DateTime.now().month;
      
      return Column(
          children: [
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                      children: [
                          SizedBox(width: 80, child: Text(monthlyAvgs[idx].name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                          Expanded(
                              child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: LayoutBuilder(
                                      builder: (context, constraints) {
                                          double w = (cVal / (cMax == 0 ? 1 : cMax)) * constraints.maxWidth;
                                          if (w < 4) w = 4;
                                          return Container(
                                              width: w,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius: BorderRadius.circular(3)
                                              ),
                                          );
                                      }
                                  ),
                              )
                          ),
                          const SizedBox(width: 10),
                          SizedBox(width: 60, child: Text("${cVal.toStringAsFixed(1)} ${_getRainUnitSymbol()}", textAlign: TextAlign.right, style: TextStyle(color: isCurrent ? Colors.blue : Colors.blue.shade200, fontSize: 16))),
                      ]
                  )
              ),
              if (!isLast)
                   Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          ]
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
