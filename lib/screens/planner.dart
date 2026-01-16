import 'package:flutter/material.dart';
import '../ui/components/reusable_card.dart';
import '../ui/components/calendar_day_cell.dart';
import '../ui/theme.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
             // Header
             Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 20, right: 20, top: 60, bottom: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.calendar_month, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Planner',
                              style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                          Text('Manage Tasks',
                              style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('My Farm Schedule',
                      style: textTheme.headlineSmall?.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    'Track planting, harvesting, and activities.',
                    style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Calendar
                  ReusableCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('October 2023',
                                style: Theme.of(context).textTheme.titleMedium),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Su', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Mo', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Tu', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('We', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Th', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Fr', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Sa', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8),
                          itemCount: 31,
                          itemBuilder: (context, index) {
                            Color? dot;
                            // Dummy data for visual
                            if (index == 2 || index == 16) dot = AppTheme.lightGreen; // Planting
                            if (index == 10 || index == 24) dot = AppTheme.accentYellow; // Care
                            if (index == 8 || index == 22) dot = Colors.orange; // Harvest
                            
                            return CalendarDayCell(day: '${index + 1}', dotColor: dot);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tasks
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Today's Tasks", style: textTheme.titleMedium),
                  ),
                  const SizedBox(height: 12),
                  
                  ReusableCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        CheckboxListTile(
                            value: false,
                            onChanged: (_) {},
                            activeColor: AppTheme.primaryGreen,
                            title: const Text('Water the maize field'),
                            subtitle: const Text('8:00 AM'),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Icon(Icons.water_drop, size: 20, color: AppTheme.primaryGreen),
                            ),
                        ),
                        Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                        CheckboxListTile(
                            value: true,
                            onChanged: (_) {},
                            activeColor: AppTheme.primaryGreen,
                            title: const Text('Buy fertilizer'),
                            subtitle: const Text('Completed'),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)
                              ),
                              child: const Icon(Icons.shopping_bag, size: 20, color: Colors.orange),
                            ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
