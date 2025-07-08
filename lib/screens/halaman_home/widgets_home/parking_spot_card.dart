import 'package:flutter/material.dart';
import 'package:parkintime/screens/reservation/select_spot_parkir.dart'; // Tambahkan ini

class ParkingSpotCard extends StatelessWidget {
  final String name;

  const ParkingSpotCard(this.name);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Saat diklik, buka halaman detail slot parkir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParkingLotDetailPage(id_lahan: name),
          ),
        );
      },
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: AssetImage("assets/spot.png"),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.8),
              BlendMode.lighten,
            ),
          ),
        ),
        child: Container(
          alignment: Alignment.bottomLeft,
          padding: EdgeInsets.all(12),
          child: Text(
            name,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}