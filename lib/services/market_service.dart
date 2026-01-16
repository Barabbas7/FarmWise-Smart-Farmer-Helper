import 'package:cloud_firestore/cloud_firestore.dart';

class MarketItem {
  final String id;
  final String crop;
  final double price;
  final String currency;
  final String location;
  final bool isUp;
  final String category; // Grains, Vegetables, Fruits

  MarketItem({
    required this.id,
    required this.crop,
    required this.price,
    required this.currency,
    required this.location,
    required this.isUp,
    required this.category,
  });

  factory MarketItem.fromFirestore(DocumentSnapshot doc) {
    // Handle typical Firestore data issues safely
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return MarketItem(
      id: doc.id,
      crop: data['crop'] as String? ?? 'Unknown',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'ETB',
      location: data['location'] as String? ?? 'market',
      isUp: data['isUp'] as bool? ?? true,
      category: data['category'] as String? ?? 'Other',
    );
  }
}

class MarketService {
  final CollectionReference _pricesRef =
      FirebaseFirestore.instance.collection('market_prices');

  // Stream of prices for real-time updates
  Stream<List<MarketItem>> getPrices() {
    return _pricesRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => MarketItem.fromFirestore(doc)).toList();
    });
  }

  // One-time initialization to ensure the screen isn't empty on first run
  Future<void> seedDataIfEmpty() async {
    try {
      final snapshot = await _pricesRef.limit(1).get();
      if (snapshot.docs.isEmpty) {
        // Seed realistic data for the region (Ethiopia context/Nigeria context mixed for demo)
        List<Map<String, dynamic>> initialData = [
          {
            'crop': 'Maize (White)',
            'price': 2200.0, // per Quintal roughly or unit
            'currency': 'ETB',
            'location': 'Addis Ababa',
            'isUp': true,
            'category': 'Grains'
          },
          {
            'crop': 'Teff (Magna)',
            'price': 5200.0,
            'currency': 'ETB',
            'location': 'Debre Zeit',
            'isUp': true,
            'category': 'Grains'
          },
          {
            'crop': 'Red Onions',
            'price': 45.0, // per KG
            'currency': 'ETB',
            'location': 'Adama Market',
            'isUp': false,
            'category': 'Vegetables'
          },
          {
            'crop': 'Tomatoes',
            'price': 35.0,
            'currency': 'ETB',
            'location': 'Meki',
            'isUp': false,
            'category': 'Vegetables'
          },
          {
            'crop': 'Coffee',
            'price': 280.0,
            'currency': 'ETB',
            'location': 'Jimma',
            'isUp': true,
            'category': 'Cash Crops'
          },
          {
            'crop': 'Wheat',
            'price': 3100.0,
            'currency': 'ETB',
            'location': 'Bale Robe',
            'isUp': true,
            'category': 'Grains'
          },
        ];
        
        for (var item in initialData) {
          await _pricesRef.add(item);
        }
      }
    } catch (e) {
      print("Error seeding market data: $e");
    }
  }
}
