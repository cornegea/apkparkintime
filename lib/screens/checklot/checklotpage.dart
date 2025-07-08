import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:parkintime/screens/checklot/information_spot_page.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckLotPage extends StatefulWidget {
  const CheckLotPage({Key? key}) : super(key: key);

  @override
  State<CheckLotPage> createState() => _CheckLotPageState();
}

class _CheckLotPageState extends State<CheckLotPage> {
  List<Map<String, dynamic>> parkingData = [];
  List<Map<String, dynamic>> allParkingData = []; // Untuk pencarian
  bool isLoading = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchParkingData();
  }

  Future<void> fetchParkingData() async {
    final response = await http.get(
      Uri.parse('https://app.parkintime.web.id/flutter/get_lahan.php'),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success']) {
        final List<dynamic> data = body['data'];
        final processed = data.map((e) {
          int kapasitas = int.tryParse(e['kapasitas'].toString()) ?? 0;
          int terisi = int.tryParse(e['terisi'].toString()) ?? 0;
          String status = "Tersedia";
          double persen = terisi / kapasitas;

          if (persen >= 1.0) {
            status = "Penuh";
          } else if (persen >= 0.9) {
            status = "Hampir Penuh";
          }

          return {
            "id": e['id'],
            "name": e['nama_lokasi'],
            "address": e['alamat'],
            "price": "Rp ${e['tarif_per_jam']}",
            "capacity": "$terisi/$kapasitas",
            "status": status,
            "foto": e['foto'],
          };
        }).toList();

        setState(() {
          allParkingData = processed;
          parkingData = processed;
          isLoading = false;
        });
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  void _filterSearchResults(String query) {
    final filtered = allParkingData.where((item) {
      final name = item["name"].toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();

    setState(() {
      parkingData = filtered;
    });
  }

  String _limitWords(String text, int maxWords) {
    final words = text.split(' ');
    if (words.length <= maxWords) return text;
    return words.sublist(0, maxWords).join(' ') + '...';
  }

  Color _statusColor(String status) {
    switch (status) {
      case "Tersedia":
        return Colors.green.shade100;
      case "Hampir Penuh":
        return Colors.orange.shade100;
      case "Penuh":
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case "Tersedia":
        return Colors.green;
      case "Hampir Penuh":
        return Colors.orange;
      case "Penuh":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Color(0xFF629584),
        centerTitle: true, // ✅ Tengahin judul
        title: Text(
          'Check Lot',
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.all(15),
            color: Color(0xFF629584),
            child: TextField(
              controller: _searchController,
              onChanged: _filterSearchResults,
              decoration: InputDecoration(
                hintText: 'Search parking location..',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: parkingData.length,
              itemBuilder: (context, index) {
                final item = parkingData[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item["name"],
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16)),
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _statusColor(item["status"]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item["status"],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _statusTextColor(item["status"]),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        _limitWords(item["address"], 6),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Hourly rate\n${item["price"]}",
                              style: TextStyle(fontSize: 13)),
                          Text("Capacity\n${item["capacity"]}",
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => InformationSpotPage(
                                        id_lahan: item["id"]), // kirim ID
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2ECC40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text("Select"),
                            ),
                          ),
                          SizedBox(width: 12),
                          IconButton(
                            icon: Icon(Icons.navigation,
                                color: Colors.green),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon:
                            Icon(Icons.share, color: Colors.green),
                            onPressed: () {
                              final message =
                                  "Parkir tersedia di ${item["name"]}, alamat: ${item["address"]}, tarif: ${item["price"]}, kapasitas: ${item["capacity"]}.";
                              Share.share(message);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}