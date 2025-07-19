import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkintime/screens/my_car/view_detail_car.dart';
import 'package:parkintime/screens/my_car/add_car.dart';

class ManageVehiclePage extends StatefulWidget {
  @override
  _ManageVehiclePageState createState() => _ManageVehiclePageState();
}

class _ManageVehiclePageState extends State<ManageVehiclePage> {
  final ScrollController scrollController = ScrollController();
  List<Map<String, String>> vehicleList = [];
  bool isLoading = true;
  int? idAkun;

  @override
  void initState() {
    super.initState();
    loadUserDataAndFetchVehicles();
  }

  Future<void> loadUserDataAndFetchVehicles() async {
    final prefs = await SharedPreferences.getInstance();
    idAkun = prefs.getInt('id_akun');

    if (idAkun == null) {
      setState(() => isLoading = false);
      return;
    }
    await fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    if (vehicleList.isEmpty) {
      setState(() => isLoading = true);
    }
    try {
      final response = await http.get(
        Uri.parse('https://app.parkintime.web.id/flutter/get_car.php?id_akun=$idAkun'),
      );
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status']) {
          setState(() {
            vehicleList = List<Map<String, String>>.from(
              result['data'].map((item) => {
                    "carId": (item["id"]?.toString() ?? "-"),
                    "plate": (item["no_kendaraan"]?.toString() ?? "-"),
                    "brand": (item["merek"]?.toString() ?? "-"),
                    "type": (item["tipe"]?.toString() ?? "-"),
                    "category": (item["kategori"]?.toString() ?? "-"),
                    "color": (item["warna"]?.toString() ?? "-"),
                    "year": (item["tahun"]?.toString() ?? "-"),
                    "plateColor": (item["warna_plat"]?.toString() ?? "-"),
                    "owner": (item["pemilik"]?.toString() ?? "-"),
                    "capacity": (item["kapasitas"]?.toString() ?? "-"),
                    "energy": (item["energi"]?.toString() ?? "-"),
                  }),
            );
          });
        } else {
          setState(() => vehicleList = []);
        }
      }
    } catch (e) {
      print("Error saat fetch kendaraan: $e");
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchVehicles,
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vehicleList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: vehicleList.length,
                          itemBuilder: (context, index) {
                            final vehicle = vehicleList[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildSuperCompactVehicleCard(
                                carData: vehicle,
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
      decoration: const BoxDecoration(color: Color(0xFF629584)),
      height: 110,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text("My Car", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddCarScreen()));
              if (result == true) {
                await fetchVehicles();
              }
            },
          ),
        ],
      ),
    );
  }
  
  // --- KARTU DENGAN UKURAN SUPER RINGKAS ---

  Widget _buildSuperCompactVehicleCard({required Map<String, String> carData}) {
    Widget getVehicleIcon(String category) {
      bool isMotorcycle = category.toLowerCase().contains("mtr") || category.toLowerCase().contains("motor");
      return Image.asset(
        isMotorcycle ? "assets/motorcycle.png" : "assets/car.png",
        height: 45, // UKURAN IKON DIPERKECIL
        errorBuilder: (context, error, stackTrace) => Icon(Icons.directions_car, size: 45, color: Colors.grey),
      );
    }
    
    void navigateToDetail() async {
        final result = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ViewDetailCarPage(carData: carData),
            ),
        );
        if (result == true) {
            await fetchVehicles();
        }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // PADDING VERTIKAL DIKURANGI
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            carData['plate']!,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const Divider(height: 18), // Spasi divider lebih kecil
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              getVehicleIcon(carData['category']!),
              const SizedBox(width: 12), // Spasi ikon lebih kecil
              Expanded(
                child: Column(
                  children: [
                    _buildDetailRow("Brand", carData['brand']!),
                    _buildDetailRow("Type", carData['type']!),
                    _buildDetailRow("Category", carData['category']!),
                    _buildDetailRow("Color", carData['color']!),
                    _buildDetailRow("Manufacture Year", carData['year']!),
                    _buildDetailRow("License Plate Color", carData['plateColor']!),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Spasi sebelum tombol lebih kecil
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: navigateToDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF629584),
                padding: const EdgeInsets.symmetric(vertical: 10), // Padding tombol lebih kecil
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                "View Detail",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), // Font tombol lebih kecil
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Row detail dengan font dan spasi paling kecil
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0), // SPASI ANTAR BARIS PALING KECIL
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54), // FONT LABEL PALING KECIL
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87), // FONT NILAI PALING KECIL
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/empty_car.png", width: 150, height: 150,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.car_crash_outlined, size: 150, color: Colors.grey)),
              const SizedBox(height: 16),
              const Text("No cars added yet", style: TextStyle(color: Colors.black54, fontSize: 18, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              const Text("Tap the '+' icon above to add your first vehicle.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}