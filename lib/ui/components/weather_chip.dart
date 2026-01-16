import 'package:flutter/material.dart';

class WeatherChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const WeatherChip({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    // Determine if we are in dark mode to adjust the chip color
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200;
    final iconColor = isDark ? Colors.white70 : Colors.black87;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor), 
          const SizedBox(width: 6), 
          Text(label, style: TextStyle(color: textColor))
        ],
      ),
    );
  }
}
