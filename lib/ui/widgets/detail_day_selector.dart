import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailDaySelector extends StatelessWidget {
  final List<String> times;
  final int selectedIndex;
  final Function(int) onDaySelected;

  const DetailDaySelector({
    super.key,
    required this.times,
    required this.selectedIndex,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: times.length,
        itemBuilder: (context, index) {
          final dt = DateTime.parse(times[index]);
          final dayName = DateFormat('EEE', 'vi').format(dt).toUpperCase();
          final dayNum = dt.day;
          final isSelected = index == selectedIndex;
          
          String label = dayName;
          if (index == 1) label = "HÔM NAY"; // Assuming index 1 is always Today due to past_days=1

          return GestureDetector(
            onTap: () => onDaySelected(index),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(15), // Rounded rect like iOS
                border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                     label,
                     style: TextStyle(
                       color: isSelected ? Colors.white : Colors.white54,
                       fontWeight: FontWeight.bold,
                       fontSize: 10
                     )
                   ),
                   const SizedBox(height: 4),
                   Text(
                     "$dayNum",
                     style: TextStyle(
                       color: isSelected ? Colors.white : Colors.white,
                       fontSize: 18,
                       fontWeight: FontWeight.w600
                     )
                   ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
