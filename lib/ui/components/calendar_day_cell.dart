import 'package:flutter/material.dart';

class CalendarDayCell extends StatelessWidget {
  final String day;
  final Color? dotColor;

  const CalendarDayCell({super.key, required this.day, this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(day, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        if (dotColor != null)
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle)),
      ],
    );
  }
}
