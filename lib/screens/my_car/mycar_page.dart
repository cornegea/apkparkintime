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
      print('id_akun tidak ditemukan di SharedPreferences');
      setState(() => isLoading = false);
      return;
    }

    await fetchVehicles();
  }

  Future<void> fetchVehicles() async {
    setState(() => isLoading = true);

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
          print("Gagal: Data kosong");
        }
      } else {
        print("Gagal mengambil data dari server");
      }
    } catch (e) {
      print("Error saat fetch kendaraan: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 228, 225, 225),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vehicleList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                controller: scrollController,
                itemCount: vehicleList.length,
                itemBuilder: (context, index) {
                  final vehicle = vehicleList[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _buildVehicleCard(
                      carId: vehicle["carId"]!,
                      plate: vehicle["plate"]!,
                      owner: vehicle["owner"]!,
                      brand: vehicle["brand"]!,
                      type: vehicle["type"]!,
                      category: vehicle["category"]!,
                      color: vehicle["color"]!,
                      year: vehicle["year"]!,
                      capacity: vehicle["capacity"]!,
                      energy: vehicle["energy"]!,
                      plateColor: vehicle["plateColor"]!,
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
      height: 120,
      padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
      decoration: const BoxDecoration(color: Color(0xFF629584)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "My Car",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddCarScreen()),
              );
              if (result == true) {
                await fetchVehicles(); // Refresh data kendaraan secara otomatis
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard({
    required String carId,
    required String plate,
    required String brand,
    required String type,
    required String category,
    required String color,
    required String year,
    required String plateColor,
    required String owner,
    required String capacity,
    required String energy,
  }) {
    final isPlateColorWhite = plateColor.toLowerCase() == 'putih';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            plate,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          Divider(height: 32, color: Colors.grey.shade300),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset("assets/car.png", height: 60),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow("Brand", brand),
                    _buildDetailRow("Type", type),
                    _buildDetailRow("Category", category),
                    _buildDetailRow("Color", color),
                    _buildDetailRow("Manufacture Year", year),
                    _buildDetailRow(
                      "License Plate Color",
                      plateColor,
                      overrideColor: isPlateColorWhite ? Colors.black87 : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewDetailCarPage(
                      carData: {
                        "carId": carId,
                        "plate": plate,
                        "brand": brand,
                        "type": type,
                        "color": color,
                        "year": year,
                        "owner": owner,
                        "category": category,
                        "capacity": capacity,
                        "energy": energy,
                        "plateColor": plateColor,
                      },
                    ),
                  ),
                );

                if (result == true) {
                  await fetchVehicles();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF629584),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                "View Detail",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? overrideColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: overrideColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/empty_car.png", width: 150, height: 150),
          const SizedBox(height: 16),
          const Text(
            "No cars added yet",
            style: TextStyle(color: Colors.black54, fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
