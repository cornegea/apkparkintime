import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:parkintime/screens/ticket_page.dart';

// [NEW] Widget for the empty state view
class EmptyHistoryWidget extends StatelessWidget {
  final VoidCallback onRefresh;

  const EmptyHistoryWidget({Key? key, required this.onRefresh}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "History is Empty",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "All parking tickets you have used or canceled will appear here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text("Try Again"),
                      onPressed: onRefresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF629584), // Correct parameter
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// [NEW] Widget to display each history item as a card
class HistoryItemCard extends StatelessWidget {
  final HistoryItem item;

  const HistoryItemCard({Key? key, required this.item}) : super(key: key);

  // Helper to get an icon based on parking type
  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'car': // Changed from 'mobil'
        return Icons.directions_car;
      case 'motorcycle': // Changed from 'motor'
        return Icons.two_wheeler;
      default:
        return Icons.receipt_long;
    }
  }

  // Helper to get the status color
  Color _getColorForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      case 'valid':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Helper to format the status text (e.g., "completed" -> "Completed")
  String _formatStatusText(String status) {
    if (status.isEmpty) return "Unknown";
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () {
          // Navigation when the card is tapped
          if (item.status.toLowerCase() != 'canceled') {
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TicketPage(ticketId: item.ticketId),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Vehicle Type Icon
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF629584).withOpacity(0.1),
                child: Icon(
                  _getIconForType(item.jenis),
                  size: 28,
                  color: const Color(0xFF629584),
                ),
              ),
              const SizedBox(width: 16),
              // 2. Detailed Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaLokasi,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "ID: ${item.orderId ?? 'N/A'} • Slot: ${item.kodeSlot}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d MMMM y, HH:mm').format(item.waktuMasuk),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 3. Status Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getColorForStatus(item.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatStatusText(item.status),
                  style: TextStyle(
                    color: _getColorForStatus(item.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// MAIN SCREEN CLASS
// =========================================================================
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
    if(!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("https://app.parkintime.web.id/flutter/riwayat.php"),
        body: {"id_akun": _idAkun.toString()},
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          setState(() {
            _historyItems =
                (data['data'] as List)
                    .map((item) => HistoryItem.fromJson(item))
                    .toList();
          });
        }
      }
    } catch (e) {
      print(e);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load history. Check your connection.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 225, 223, 223),
      // [CHANGED] Using a more standard AppBar
      appBar: AppBar(
        backgroundColor: const Color(0xFF629584),
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(child: _buildContentForTab()),
        ],
      ),
    );
  }
  
  // [CHANGED] Filter widget extracted for cleaner code
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedIndex == index;
          return ChoiceChip(
            label: Text(filters[index]),
            selected: isSelected,
            onSelected: (bool selected) {
              if (selected) {
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFF629584),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF629584),
              fontWeight: FontWeight.w600,
            ),
            shape: StadiumBorder(
              side: BorderSide(
                color: isSelected ? const Color(0xFF629584) : Colors.grey.shade400,
              )
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          );
        }),
      ),
    );
  }

  Widget _buildContentForTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF629584)));
    }

    String selectedFilter = filters[_selectedIndex].toLowerCase();
    final filteredItems =
        _historyItems.where((item) {
          String itemStatus = item.status.toLowerCase();
          // Filter logic: "Valid" includes both "valid" and "pending"
          if (selectedFilter == "valid") {
            return itemStatus == "valid" || itemStatus == "pending";
          }
          return itemStatus == selectedFilter;
        }).toList();
        
    // [CHANGED] Using the new EmptyHistoryWidget when data is empty
    if (filteredItems.isEmpty) {
      return EmptyHistoryWidget(onRefresh: fetchHistory);
    }
    
    // [CHANGED] Using the new HistoryItemCard to display data
    return RefreshIndicator(
      onRefresh: fetchHistory,
      color: const Color(0xFF629584),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          // Using the new card widget
          return HistoryItemCard(item: item);
        },
      ),
    );
  }
}

// HistoryItem Model Class (with improved null-safety checks)
class HistoryItem {
  final int ticketId;
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
      ticketId: int.tryParse(json['tiket_id']?.toString() ?? '0') ?? 0,
      orderId: json['order_id'],
      status: json['status'] ?? 'Unknown',
      waktuMasuk: DateTime.parse(json['waktu_masuk'] ?? DateTime.now().toIso8601String()),
      waktuKeluar:
          json['waktu_keluar'] != null && json['waktu_keluar'].toString().isNotEmpty
              ? DateTime.tryParse(json['waktu_keluar'])
              : null,
      biayaTotal: int.tryParse(json['biaya_total']?.toString() ?? '0') ?? 0,
      kodeSlot: json['kode_slot'] ?? 'N/A',
      namaLokasi: json['nama_lokasi'] ?? 'Location Not Found',
      jenis: json['jenis'] ?? 'General',
    );
  }
}