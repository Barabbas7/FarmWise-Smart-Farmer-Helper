import 'package:flutter/material.dart';
import '../ui/components/reusable_card.dart';
import '../ui/components/market_price_row.dart';
import '../ui/theme.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        child: const Icon(Icons.store, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Market',
                              style: textTheme.titleMedium?.copyWith(color: Colors.white)),
                          Text('Track Prices',
                              style: textTheme.bodySmall?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Current Prices',
                      style: textTheme.headlineSmall?.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    'Live updates from major regional markets.',
                    style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9)),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                   // Search
                  ReusableCard(
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: AppTheme.darkGray),
                        SizedBox(width: 12),
                        Expanded(child: Text('Search crop (e.g., maize)', style: TextStyle(color: Colors.grey))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(label: 'All', isSelected: true),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Grains', isSelected: false),
                         const SizedBox(width: 8),
                        _FilterChip(label: 'Vegetables', isSelected: false),
                         const SizedBox(width: 8),
                        _FilterChip(label: 'Fruits', isSelected: false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // List
                  const ReusableCard(
                      child: MarketPriceRow(
                          crop: 'Maize',
                          price: '210',
                          location: 'Kano Market',
                          up: true)),
                  const SizedBox(height: 12),
                  const ReusableCard(
                      child: MarketPriceRow(
                          crop: 'Tomato',
                          price: '330',
                          location: 'Lagos Market',
                          up: false)),
                  const SizedBox(height: 12),
                  const ReusableCard(
                      child: MarketPriceRow(
                          crop: 'Cassava',
                          price: '180',
                          location: 'Abuja Market',
                          up: true)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({required this.label, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryGreen : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
