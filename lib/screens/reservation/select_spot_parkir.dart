import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:parkintime/screens/reservation/select_vehicle.dart';

class ParkingLotDetailPage extends StatefulWidget {
  final String id_lahan;

  const ParkingLotDetailPage({Key? key,
    required this.id_lahan
  }) : super(key: key);

  @override
  _ParkingLotDetailPageState createState() => _ParkingLotDetailPageState();
}

class SlotParkir {
  final String kodeSlot;
  final String area;
  final String status;

  SlotParkir({
    required this.kodeSlot,
    required this.area,
    required this.status,
  });

  factory SlotParkir.fromJson(Map<String, dynamic> json) {
    return SlotParkir(
      kodeSlot: json['kode_slot'],
      area: json['area'],
      status: json['status'],
    );
  }
}

class _ParkingLotDetailPageState extends State<ParkingLotDetailPage> {
  List<SlotParkir> allSlots = [];
  List<String> uniqueAreas = [];
  String? selectedArea;
  String? selectedSlot;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSlotsByLahan(widget.id_lahan);
  }

  Future<void> fetchSlotsByLahan(String idLahan) async {
    try {
      final response = await http.get(
        Uri.parse('https://app.parkintime.web.id/flutter/get_slot.php?id_lahan=$idLahan'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> slotJson = json.decode(response.body);
        final List<SlotParkir> fetchedSlots =
        slotJson.map((json) => SlotParkir.fromJson(json)).toList();

        final Set<String> areaSet = fetchedSlots.map((e) => e.area).toSet();

        if (mounted) {
          setState(() {
            allSlots = fetchedSlots;
            uniqueAreas = areaSet.toList()..sort();
            selectedArea = uniqueAreas.isNotEmpty ? uniqueAreas[0] : null;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat data slot');
      }
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<SlotParkir> get filteredSlots => selectedArea == null
      ? []
      : allSlots.where((slot) => slot.area == selectedArea).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 245, 245),
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Color(0xFF629584),
        centerTitle: true,
        title: Text(
          'Information Spot',
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
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        color: Color.fromARGB(255, 245, 245, 245),
        child: ElevatedButton(
          onPressed: selectedSlot != null
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectVehiclePage(
                        kodeslot: selectedSlot!,
                        id_lahan: widget.id_lahan,
                      ),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedSlot != null ? Color(0xFF2ECC40) : Colors.grey,
            
            // --- PERBAIKAN UTAMA: Mengatur ukuran tombol ---
            fixedSize: const Size(double.infinity, 35), // Lebar penuh, Tinggi 55

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: selectedSlot != null ? 2 : 0,
          ),
          child: Text(
            selectedSlot != null
                ? 'Reservation Slot $selectedSlot'
                : 'Select an Available Slot',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Area
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: uniqueAreas.map((area) {
                  final isSelected = area == selectedArea;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedArea = area;
                          selectedSlot = null;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        isSelected ? Color(0xFF629584) : Colors.white,
                        foregroundColor:
                        isSelected ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: Color(0xFF2ECC40)),
                        ),
                      ),
                      child: Text('$area'),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Daftar Slot
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.green))
                : filteredSlots.isEmpty && !_isLoading
                    ? Center(child: Text("No slots available in this area."))
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: buildSlotWidgets(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildSlotWidgets() {
    List<Widget> widgets = [];
    for (int i = 0; i < filteredSlots.length; i += 2) {
      final first = filteredSlots[i];
      final second = (i + 1 < filteredSlots.length) ? filteredSlots[i + 1] : null;

      widgets.add(
        _buildParkingRow(
          [first.kodeSlot, second?.kodeSlot ?? ''],
          [first.status, second?.status ?? ''],
        ),
      );
    }
    return widgets;
  }

  Widget _buildParkingRow(List<String> labels, List<String> statuses) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(2, (index) {
          final status = statuses[index];
          final slotLabel = labels[index];

          if (slotLabel.isEmpty) return Expanded(child: SizedBox());

          bool isAvailable = status.toLowerCase() == 'available';
          bool isSelected = slotLabel == selectedSlot;

          Color bgColor;
          Widget childContent;

          if (status.toLowerCase() == 'occupied') {
            bgColor = Colors.red.shade100;
            childContent = Image.asset('assets/car-terisi.png');
          } else if (status.toLowerCase() == 'booked') {
            bgColor = Colors.orange.shade100;
            childContent = Center(
              child: Text(
                'Booked',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
            );
          } else { // Tersedia
            bgColor = isSelected ? Color(0xFF2ECC40) : Colors.green.shade100;
            childContent = Center(
              child: Text(
                slotLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            );
          }

          return Expanded(
            child: GestureDetector(
              onTap: isAvailable
                  ? () {
                      setState(() {
                        selectedSlot = slotLabel == selectedSlot ? null : slotLabel;
                      });
                    }
                  : null,
              child: Container(
                height: 80,
                margin: EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border.all(
                    color: isSelected ? Colors.green.shade800 : Colors.black26,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: childContent,
              ),
            ),
          );
        }),
      ),
    );
  }
}
