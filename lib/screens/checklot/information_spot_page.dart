import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InformationSpotPage extends StatefulWidget {
  final String id_lahan;

  const InformationSpotPage({Key? key, required this.id_lahan})
    : super(key: key);

  @override
  _InformationSpotPageState createState() => _InformationSpotPageState();
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

class _InformationSpotPageState extends State<InformationSpotPage> {
  List<SlotParkir> allSlots = [];
  List<String> uniqueAreas = [];
  String? selectedArea;

  @override
  void initState() {
    super.initState();
    fetchSlotsByLahan(widget.id_lahan);
  }

  Future<void> fetchSlotsByLahan(String idLahan) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://app.parkintime.web.id/flutter/get_slot.php?id_lahan=$idLahan',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> slotJson = json.decode(response.body);
        final List<SlotParkir> fetchedSlots =
            slotJson.map((json) => SlotParkir.fromJson(json)).toList();

        final Set<String> areaSet = fetchedSlots.map((e) => e.area).toSet();

        setState(() {
          allSlots = fetchedSlots;
          uniqueAreas = areaSet.toList()..sort();
          selectedArea = uniqueAreas.isNotEmpty ? uniqueAreas[0] : null;
        });
      } else {
        throw Exception('Gagal memuat data slot');
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  List<SlotParkir> get filteredSlots =>
      selectedArea == null
          ? []
          : allSlots.where((slot) => slot.area == selectedArea).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 231, 229, 229), // ✅ Ubah background halaman
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Color(0xFF629584),
        centerTitle: true, // ✅ Tengahin judul
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
          ), // ✅ Icon back lebih tebal
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            color: const Color.fromARGB(255, 234, 230, 230),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children:
                    uniqueAreas.map((area) {
                      final isSelected = area == selectedArea;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedArea = area;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isSelected ? Color(0xFF2ECC40) : Colors.white,
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
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(children: buildSlotWidgets()),
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
      final second =
          (i + 1 < filteredSlots.length) ? filteredSlots[i + 1] : null;

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

          Color bgColor;
          Widget childContent;

          if (status == 'terisi') {
            bgColor = Colors.green.shade50;
            childContent = Image.asset('assets/car-terisi.png');
          } else if (status == 'occupied') {
            bgColor = Colors.orange.shade100;
            childContent = Center(
              child: Text(
                'Occupied',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            );
          } else {
            bgColor = Colors.green.shade100;
            childContent = Center(
              child: Text(
                slotLabel,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }

          return Expanded(
            child: Container(
              height: 80,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.all(
                  color: Colors.black26,
                  style: BorderStyle.solid,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: childContent,
            ),
          );
        }),
      ),
    );
  }
}
