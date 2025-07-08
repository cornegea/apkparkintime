import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:parkintime/screens/ticket_page.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedIndex = 0;
  int? _idAkun;
  final List<String> filters = ["Valid", "Completed", "Canceled"];
  List<HistoryItem> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIdAkun();
  }

  Future<void> _loadIdAkun() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _idAkun = prefs.getInt('id_akun');
    });
    if (_idAkun != null) {
      await fetchHistory();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchHistory() async {
    if (_idAkun == null) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("https://app.parkintime.web.id/flutter/riwayat.php"),
        body: {"id_akun": _idAkun.toString()},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _historyItems = (data['data'] as List)
                .map((item) => HistoryItem.fromJson(item))
                .toList();
          });
        }
      }
    } catch (e) {
      // Handle error, maybe show a snackbar
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            height: 70,
            width: double.infinity,
            color: Color(0xFF629584),
            alignment: Alignment.bottomCenter,
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(filters.length, (index) {
                final isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFF629584): Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Text(
                      filters[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Color(0xFF629584),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(child: _buildContentForTab()),
        ],
      ),
    );
  }

  Widget _buildContentForTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    String selectedFilter = filters[_selectedIndex].toLowerCase();
    final filteredItems = _historyItems.where((item) {
      String itemStatus = item.status.toLowerCase();
      if (selectedFilter == "valid") {
        return itemStatus == "valid" || itemStatus == "pending";
      }
      return itemStatus == selectedFilter;
    }).toList();

    return RefreshIndicator(
      onRefresh: fetchHistory,
      child: filteredItems.isEmpty
          ? ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: Text("No history found.")),
        ],
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TicketPage(ticketId: item.ticketId),
                ),
              );
            },
            child: _buildHistoryCardFromModel(item),
          );
        },
      ),
    );
  }

  Widget _buildHistoryCardFromModel(HistoryItem item) {
    final masuk = item.waktuMasuk;
    final keluar = item.waktuKeluar ?? masuk;
    final duration = keluar.difference(masuk);
    final dateText =
        "${DateFormat('d MMMM y').format(masuk)} - ${DateFormat('HH.mm').format(masuk)}";

    return _buildHistoryCard(
      // <<< DIUBAH: Mengirim orderId ke widget kartu
      orderId: item.orderId ?? 'NO ID',
      date: dateText,
      location: item.namaLokasi,
      slot: item.kodeSlot,
      duration: "${duration.inHours} Hours",
      statusWidget: _buildStatusBoxFromStatus(item),
    );
  }

  Widget _buildStatusBoxFromStatus(HistoryItem item) {
    final status = item.status.toLowerCase();

    switch (status) {
      case "pending":
        return _buildTextStatusBox("Waiting for payment", Colors.orange, Colors.white);
      case "valid":
        return _buildStatusBox(
          title: "Valid until",
          date: DateFormat('d MMMM y').format(item.waktuKeluar ?? item.waktuMasuk),
          time: DateFormat('HH.mm').format(item.waktuKeluar ?? item.waktuMasuk),
          color: Colors.blue,
        );
      case "completed":
        return _buildTextStatusBox("Completed", Color(0xFF629584), Colors.white);
      case "canceled":
        return _buildTextStatusBox("Canceled", Colors.red, Colors.white);
      default:
        return _buildTextStatusBox(item.status, Colors.grey, Colors.white);
    }
  }

  Widget _buildStatusBox({
    required String title,
    required String date,
    required String time,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 2),
          Text(date, style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextStatusBox(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  // <<< DIUBAH: Mengganti parameter 'ticket' menjadi 'orderId'
  Widget _buildHistoryCard({
    required String orderId,
    required String date,
    required String location,
    required String slot,
    required String duration,
    required Widget statusWidget,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // <<< DIUBAH: Menampilkan orderId
              Text(orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(date, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(slot),
                    Text(duration),
                  ],
                ),
              ),
              statusWidget,
            ],
          ),
        ],
      ),
    );
  }
}

class HistoryItem {
  final int ticketId;
  // <<< DIUBAH: Menambahkan properti orderId
  final String? orderId;
  final String status;
  final DateTime waktuMasuk;
  final DateTime? waktuKeluar;
  final int biayaTotal;
  final String kodeSlot;
  final String namaLokasi;
  final String jenis;

  HistoryItem({
    required this.ticketId,
    // <<< DIUBAH: Menambahkan orderId ke constructor
    this.orderId,
    required this.status,
    required this.waktuMasuk,
    this.waktuKeluar,
    required this.biayaTotal,
    required this.kodeSlot,
    required this.namaLokasi,
    required this.jenis,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      ticketId: int.tryParse(json['tiket_id'].toString()) ?? 0,
      // <<< DIUBAH: Mengambil data 'order_id' dari JSON
      orderId: json['order_id'],
      status: json['status'],
      waktuMasuk: DateTime.parse(json['waktu_masuk']),
      waktuKeluar: json['waktu_keluar'] != null && json['waktu_keluar'] != ''
          ? DateTime.tryParse(json['waktu_keluar'])
          : null,
      biayaTotal: int.tryParse(json['biaya_total'].toString()) ?? 0,
      kodeSlot: json['kode_slot'],
      namaLokasi: json['nama_lokasi'],
      jenis: json['jenis'],
    );
  }
}