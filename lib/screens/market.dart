import 'package:flutter/material.dart';
import '../ui/components/reusable_card.dart';
import '../ui/components/market_price_row.dart';
import '../ui/theme.dart';
import '../services/market_service.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final MarketService _marketService = MarketService();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    // Seed data if needed
    _marketService.seedDataIfEmpty();
  }

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
                        _filterChip('All'),
                        const SizedBox(width: 8),
                        _filterChip('Grains'),
                         const SizedBox(width: 8),
                        _filterChip('Vegetables'),
                         const SizedBox(width: 8),
                        _filterChip('Fruits'),
                        const SizedBox(width: 8),
                        _filterChip('Cash Crops'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Live List
                  StreamBuilder<List<MarketItem>>(
                    stream: _marketService.getPrices(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error loading prices: ${snapshot.error}"));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                         return const Center(child: Text("No prices available yet."));
                      }
                      
                      final allItems = snapshot.data!;
                      final filteredItems = _selectedFilter == 'All' 
                          ? allItems 
                          : allItems.where((i) => i.category == _selectedFilter).toList();
                          
                      if (filteredItems.isEmpty) {
                         return SizedBox(
                           height: 100,
                           child: Center(
                             child: Text("No items found for $_selectedFilter", style: TextStyle(color: Colors.grey))
                           )
                          );
                      }

                      return Column(
                        children: filteredItems.map((item) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ReusableCard(
                              child: MarketPriceRow(
                                crop: item.crop,
                                price: '${item.price.toStringAsFixed(0)} ${item.currency}',
                                location: item.location,
                                up: item.isUp,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
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
      ),
    );
  }
}
