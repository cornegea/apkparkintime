// lib/screens/parking_lot_detail_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:parkintime/screens/reservation/ReservasionPage.dart'; // Sesuaikan dengan path halaman reservasi Anda

class ParkingLotDetailPage extends StatelessWidget {
  final Map<String, dynamic> lot;

  const ParkingLotDetailPage({Key? key, required this.lot}) : super(key: key);

  // Fungsi untuk membuka peta, kita pindahkan ke sini
  Future<void> _launchMap(BuildContext context) async {
    final String? latitude = lot['latitude']?.toString();
    final String? longitude = lot['longitude']?.toString();

    if (latitude == null ||
        longitude == null ||
        latitude.isEmpty ||
        longitude.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Koordinat lokasi tidak tersedia.')),
      );
      return;
    }

    final String googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final Uri mapUri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka aplikasi peta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ekstrak data dari 'lot' untuk kemudahan
    final String namaLokasi = lot['nama_lokasi'] ?? 'Lokasi Tidak Dikenal';
    final String alamat = lot['alamat'] ?? 'Alamat tidak tersedia';
    final String foto = lot['foto'] ?? '';
    final int kapasitas = lot['kapasitas'] ?? 0;
    final int terisi = lot['terisi'] ?? 0;
    final int tersedia = kapasitas - terisi;

    return Scaffold(
      // AppBar agar ada tombol kembali otomatis
      appBar: AppBar(
        backgroundColor: Color(0xFF629584),
         centerTitle: true, // ✅ Tengahin judul
        title: Text(
          'location details',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 28,
          ), // ✅ Icon back lebih tebal
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Gambar Lokasi
            Container(
              height: 250,
              child:
                  foto.isNotEmpty
                      ? Image.network(
                        'https://app.parkintime.web.id/foto/$foto',
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Icon(
                              Icons.business,
                              size: 100,
                              color: Colors.grey,
                            ),
                      )
                      : Image.asset(
                        "assets/spot.png", // Gambar default jika tidak ada foto
                        fit: BoxFit.cover,
                      ),
            ),

            // 2. Konten Detail (Nama, Alamat, Slot)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaLokasi,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alamat,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'slots available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$tersedia Slot',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              tersedia > 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Tombol Aksi
            Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
  child: Row(
    children: [
      // Tombol Rute/Directions
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () {
            _launchMap(context);
          },
          // --- PERUBAHAN UTAMA ADA DI SINI ---
          icon: Image.asset(
            'assets/map.jpg',
            width: 30,
            height: 30,
          ),
          label: Text('Rute'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Color(0xFF629584),
            side: BorderSide(color: Color(0xFF629584)),
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Membuat tombol lebih bulat
            ),
          ),
        ),
      ),
      SizedBox(width: 16),
      // Tombol Pesan/Book Now
      Expanded(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => Reservasionpage()),
            );
          },
          child: Text('Pesan Sekarang'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF629584),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30), // Membuat tombol lebih bulat
            ),
          ),
        ),
      ),
    ],
  ),
)
          ],
        ),
      ),
    );
  }
}
