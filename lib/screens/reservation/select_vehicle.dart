import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:parkintime/screens/my_car/add_car.dart'; // <-- LANGKAH 1
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkintime/screens/reservation/book_parking.dart';

class SelectVehiclePage extends StatefulWidget {
  final String kodeslot;
  final String id_lahan;

  const SelectVehiclePage({
    Key? key,
    required this.kodeslot,
    required this.id_lahan,
  }) : super(key: key);

  @override
  _SelectVehiclePageState createState() => _SelectVehiclePageState();
}

class _SelectVehiclePageState extends State<SelectVehiclePage> {
  int? selectedVehicleIndex;
  List<Map<String, String>> vehicles = [];
  bool isLoading = true;
  String? idAkun;
  int? tarifPerJam;

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await loadIdAkun();
    if (idAkun != null) {
      await Future.wait([
        fetchVehicles(),
        fetchTarifLahan(),
      ]);
    }
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadIdAkun() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    idAkun = prefs.getInt('id_akun')?.toString();
  }

  Future<void> fetchTarifLahan() async {
    try {
      final response = await http.get(Uri.parse(
        'https://app.parkintime.web.id/flutter/get_lahan.php',
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];
          final lahanData = data.firstWhere(
              (lahan) => lahan['id'].toString() == widget.id_lahan,
              orElse: () => null);

          if (lahanData != null) {
            String tarifString = lahanData['tarif_per_jam'].toString();
            double? tarifDouble = double.tryParse(tarifString);
            if (tarifDouble != null) {
              if (mounted) {
                setState(() {
                  tarifPerJam = tarifDouble.toInt();
                });
              }
            }
          }
        }
      }
    } catch (e) {
      print('Exception terjadi di fetchTarifLahan: $e');
    }
  }

  Future<void> fetchVehicles() async {
    try {
      final response = await http.get(Uri.parse(
        'https://app.parkintime.web.id/flutter/get_car.php?id_akun=$idAkun',
      ));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['status'] == true) {
          final List<dynamic> data = json['data'];
          if (mounted) {
            setState(() {
              vehicles = data
                  .map<Map<String, String>>((item) => {
                        'carid': item['id']?.toString() ?? '',
                        'brand': item['merek'] ?? 'No brand',
                        'type': item['tipe'] ?? 'No type',
                        'plate': item['no_kendaraan'] ?? 'No plate',
                        'image': 'assets/car.png',
                      })
                  .toList();
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching vehicles: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canContinue = selectedVehicleIndex != null && tarifPerJam != null;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Color(0xFF629584),
        centerTitle: true, // ✅ Tengahin judul
        title: Text(
          'Select Vehicle',
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : vehicles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("There are no vehicles registered"),
                              SizedBox(height: 12),
                              // --- LANGKAH 2: IMPLEMENTASI NAVIGASI ---
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => AddCarScreen()),
                                  );
                                  if (result == true) {
                                    setState(() {
                                      isLoading = true;
                                    });
                                    await loadInitialData();
                                  }
                                },
                                child: Text(
                                  "Add Vehicle",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) {
                            final vehicle = vehicles[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedVehicleIndex = index;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: selectedVehicleIndex == index
                                      ? Border.all(color: Colors.green, width: 2)
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Image.asset(vehicle['image']!, height: 60),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            vehicle['plate']!,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            vehicle['brand']!,
                                            style: TextStyle(color: Colors.grey[700]),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            vehicle['type']!,
                                            style: TextStyle(color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Radio<int>(
                                      value: index,
                                      groupValue: selectedVehicleIndex,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedVehicleIndex = value;
                                        });
                                      },
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: ElevatedButton(
                onPressed: canContinue
                    ? () {
                        final selectedVehicle = vehicles[selectedVehicleIndex!];
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookParkingDetailsPage(
                              kodeslot: widget.kodeslot,
                              id_lahan: widget.id_lahan,
                              vehicleId: selectedVehicle['carid']!,
                              vehiclePlate: selectedVehicle['plate']!,
                              pricePerHour: tarifPerJam!,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canContinue ? Colors.green : Colors.grey,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text("Continue",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}