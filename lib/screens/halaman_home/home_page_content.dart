import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parkintime/screens/reservation/select_spot_parkir.dart'; // <-- LANGKAH 1: Impor halaman tujuan
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
        if (data['success'] == true) {
          final fullName = data['nama_lengkap'] ?? 'User';
          final trimmedName = _limitWords(_capitalizeEachWord(fullName), 3);
          if (mounted) {
            setState(() {
              _userName = trimmedName;
            });
          }
        } else {
          if (mounted) setState(() => _userName = 'User');
        }
      } else {
        if (mounted) setState(() => _userName = 'User');
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
        if (result['status']) {
          if (mounted) {
            setState(() {
              vehicles.clear();
              vehicles.addAll(List<Map<String, dynamic>>.from(result['data']));
            });
          }
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
        if (result['success'] == true) {
          if (mounted) {
            setState(() {
              parkingLots = List<Map<String, dynamic>>.from(result['data']);
            });
          }
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
          color: const Color.fromARGB(255, 238, 232, 232),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
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
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        25,
        100,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
    );
  }

  Widget _buildReservationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0XFFB5D0ED),
        borderRadius: BorderRadius.circular(16),
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
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Book your parking spot now",
                      style: TextStyle(fontSize: 14, color: Colors.black),
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
                  Container(
                    height: 2,
                    width: 40,
                    color: Color(0xFF2ECC40),
                  ),
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
                    side: const BorderSide(color: Color.fromARGB(255, 240, 101, 82)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  "Manage Vehicle",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: vehicles.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SizedBox(
                  height: 100,
                  child: ListView.separated(
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
              Container(
                height: 2,
                width: 40,
                color: Color(0xFF2ECC40),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        Container(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: parkingLots.length,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemBuilder: (context, index) {
              final lot = parkingLots[index];
              final availableSlots = lot['slot_tersedia'] ?? 0;
              
              // --- LANGKAH 2: Mengirim ID Lahan ke _buildParkingCard ---
              final String lahanId = lot['id']?.toString() ?? '';

              return _buildParkingCard(
                lahanId, // Kirim ID
                lot['nama_lokasi'] ?? 'Unknown',
                lot['foto'] ?? '',
                availableSlots,
              );
            },
          ),
        ),
      ],
    );
  }

  // --- LANGKAH 2 (Lanjutan): Update signature dan bungkus dengan GestureDetector ---
  Widget _buildParkingCard(String id, String title, String foto, int availableSlots) {
    return GestureDetector( // <-- LANGKAH 3: Bungkus dengan GestureDetector
      onTap: () {
        // --- LANGKAH 4: Lakukan Navigasi ---
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParkingLotDetailPage(
              id_lahan: id, // Kirim ID yang sudah diterima
            ),
          ),
        );
      },
      child: Container(
        width: 140,
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
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image(
                  image: (foto.isNotEmpty)
                      ? NetworkImage('https://app.parkintime.web.id/foto/$foto')
                      : AssetImage("assets/spot.png") as ImageProvider,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.business, size: 40, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          "Available",
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                        const Spacer(),
                        Text(
                          availableSlots.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: availableSlots > 0 ? Colors.green.shade600 : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
