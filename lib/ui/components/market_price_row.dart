import 'package:flutter/material.dart';

class MarketPriceRow extends StatelessWidget {
  final String crop;
  final String price;
  final String location;
  final bool up;

  const MarketPriceRow(
      {super.key,
      required this.crop,
      required this.price,
      required this.location,
      this.up = true});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Icon(Icons.grass)),
      title: Text(crop),
      subtitle: Text('$price • $location'),
      trailing: Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
          color: up ? Colors.green : Colors.red),
    );
  }
}
