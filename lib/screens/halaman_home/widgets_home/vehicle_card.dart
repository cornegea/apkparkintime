import 'package:flutter/material.dart';

class VehicleCard extends StatelessWidget {
  final String plate;
  final String brand;
  final String type;
  final String color;

  const VehicleCard({
    super.key,
    required this.plate,
    required this.brand,
    required this.type,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Menggunakan IntrinsicHeight agar VerticalDivider bisa menyesuaikan tinggi
    return IntrinsicHeight(
      child: Container(
        width: 320, // Lebar kartu bisa disesuaikan jika perlu
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gambar mobil
            Image.asset(
              'assets/car.png',
              width: 50,
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),

            // Garis vertikal pemisah (lebih baik menggunakan VerticalDivider)
            const VerticalDivider(
              color: Color(0xFFE0E0E0), // Warna abu-abu yang lebih lembut
              thickness: 1,
            ),
            const SizedBox(width: 12),

            // Informasi kendaraan
            Expanded(
              child: Column(
                // --- PERBAIKAN UTAMA: Teks dibuat rata tengah vertikal ---
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$brand $type".toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1, // Pastikan tidak lebih dari 1 baris
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plate.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF629584), // Warna hijau branding
                      fontWeight: FontWeight.w600,
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
