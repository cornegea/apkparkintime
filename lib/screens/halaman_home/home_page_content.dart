import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// --- IMPORT UNTUK HALAMAN BARU ---
import 'package:parkintime/screens/parking_lot_detail_page.dart'; // Sesuaikan path jika perlu

import 'package:parkintime/screens/my_car/mycar_page.dart';
import 'package:parkintime/screens/reservation/ReservasionPage.dart';
import 'widgets_home/vehicle_card.dart';

class HomePageContent extends StatefulWidget {
  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> parkingLots = [];
  String _userName = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) {
      _loadAllData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUserNameFromAPI(),
      _loadVehiclesFromAPI(),
      _loadParkingLotsFromAPI(),
    ]);
  }

  Future<void> _handleRefresh() async {
    await _loadAllData();
  }

  Future<void> _loadUserNameFromAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idAkun = prefs.getInt('id_akun') ?? 0;
      final response = await http.get(
        Uri.parse(
          'https://app.parkintime.web.id/flutter/profile.php?id_akun=$idAkun',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && mounted) {
          final fullName = data['nama_lengkap'] ?? 'User';
          final trimmedName = _limitWords(_capitalizeEachWord(fullName), 3);
          setState(() {
            _userName = trimmedName;
          });
        }
      }
    } catch (e) {
      print("Error fetching user name: $e");
      if (mounted) setState(() => _userName = 'User');
    }
  }

  Future<void> _loadVehiclesFromAPI() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idAkun = prefs.getInt('id_akun') ?? 0;
      final response = await http.get(
        Uri.parse(
          'https://app.parkintime.web.id/flutter/get_car.php?id_akun=$idAkun',
        ),
      );
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == true && mounted) {
          setState(() {
            vehicles.clear();
            vehicles.addAll(List<Map<String, dynamic>>.from(result['data']));
          });
        }
      }
    } catch (e) {
      print("Error loading vehicles: $e");
    }
  }

  Future<void> _loadParkingLotsFromAPI() async {
    try {
      final response = await http.get(
        Uri.parse('https://app.parkintime.web.id/flutter/get_lahan.php'),
      );
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success'] == true && mounted) {
          setState(() {
            parkingLots = List<Map<String, dynamic>>.from(result['data']);
          });
        }
      }
    } catch (e) {
      print("Error loading parking lots: $e");
    }
  }

  String _capitalizeEachWord(String input) {
    return input
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _limitWords(String text, int maxWords) {
    final words = text.split(' ');
    if (words.length <= maxWords) return text;
    return words.sublist(0, maxWords).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    const double cardOverlap = 80.0;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: Container(
          height: double.infinity,
          color: const Color.fromARGB(255, 225, 223, 223),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: cardOverlap),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      left: 20,
                      right: 20,
                      child: _buildReservationCard(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildMyCarSection(context),
                const SizedBox(height: 30),
                _buildParkingSpotSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: Color(0xFF629584),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 246, 250, 251),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Image.asset('assets/log.png', height: 30),
                ),
                const SizedBox(height: 30),
                Text(
                  "Hi, $_userName",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Make a Reservation",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2d3436),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Book your parking spot now",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.calendar_today_outlined,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => Reservasionpage()),
                    );
                  },
                  child: Text("Reserve Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF629584),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyCarSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "My Car",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Container(height: 2, width: 40, color: Color(0xFF2ECC40)),
                ],
              ),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManageVehiclePage()),
                  );
                  if (result == true) {
                    _loadVehiclesFromAPI();
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color.fromARGB(255, 236, 63, 43),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(
                      color: Color.fromARGB(255, 240, 101, 82),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  "Manage Vehicle",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child:
              vehicles.isEmpty
                  ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/car.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 12),
                          const VerticalDivider(
                            color: Colors.black26,
                            thickness: 1,
                            indent: 10,
                            endIndent: 10,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              "No cars added yet",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: Color.fromRGBO(160, 142, 142, 0.4),
                            borderRadius: BorderRadius.circular(30),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(30),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ManageVehiclePage(),
                                  ),
                                );
                                if (result == true) {
                                  _loadVehiclesFromAPI();
                                }
                              },
                              splashColor: Colors.white.withOpacity(0.4),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.add,
                                  color: Color(0xFF629584),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: vehicles.length,
                    separatorBuilder: (_, __) => SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final vehicle = vehicles[index];
                      return VehicleCard(
                        plate: vehicle['no_kendaraan'] ?? '-',
                        brand: vehicle['merek'] ?? '-',
                        type: vehicle['tipe'] ?? '-',
                        color: vehicle['warna'] ?? '-',
                      );
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildParkingSpotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Parking Spot",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Container(height: 2, width: 40, color: Color(0xFF2ECC40)),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 180,
          child:
              parkingLots.isEmpty
                  ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            color: Colors.grey[400],
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "No Spots Available",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: parkingLots.length,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    itemBuilder: (context, index) {
                      final lot = parkingLots[index];
                      return _buildParkingCard(context, lot);
                    },
                  ),
        ),
      ],
    );
  }

  // --- KODE YANG DIPERBARUI (KARTU PARKIR DENGAN NAVIGASI KE HALAMAN DETAIL) ---
  // In HomePageContent.dart

  Widget _buildParkingCard(BuildContext context, Map<String, dynamic> lot) {
    // Ekstrak data untuk ditampilkan di kartu kecil
    final String title = lot['nama_lokasi'] ?? 'Unknown';
    final String foto = lot['foto'] ?? '';
    final int kapasitas = lot['kapasitas'] ?? 0;
    final int terisi = lot['terisi'] ?? 0;
    final int tersedia = kapasitas - terisi;

    return GestureDetector(
      onTap: () {
        // Aksi sekarang adalah membuka halaman detail dan mengirim data 'lot'
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParkingLotDetailPage(lot: lot),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image(
                  image:
                      (foto.isNotEmpty)
                          ? NetworkImage(
                            'https://app.parkintime.web.id/foto/$foto',
                          )
                          : AssetImage("assets/spot.png") as ImageProvider,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Icon(Icons.business, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PERUBAHAN ADA DI ROW BERIKUT INI ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Menjadi kode ini:
                      Image.asset(
                        'assets/maps.png', // Panggil gambar dari folder assets
                        width: 20, // Atur ukuran gambar dengan width dan height
                        height: 20,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          tersedia > 0
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$tersedia Slots Available",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color:
                            tersedia > 0
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                      ),
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
