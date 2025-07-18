import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:parkintime/screens/payment_webview_page.dart'; // Pastikan path import ini benar

// Model Ticket (tidak ada perubahan)
class Ticket {
  final String orderId;
  final String status;
  final String nomorPlat;
  final String jenisKendaraan;
  final String parkingArea;
  final String address;
  final String vehicle;
  final String parkingSpot;
  final String waktuMasuk;
  final String qrData;
  final String tarifPerJam;
  final String total;
  final String statusPembayaran;
  final String? redirectUrl;

  Ticket({
    required this.orderId,
    required this.status,
    required this.nomorPlat,
    required this.jenisKendaraan,
    required this.parkingArea,
    required this.address,
    required this.vehicle,
    required this.parkingSpot,
    required this.waktuMasuk,
    required this.qrData,
    required this.tarifPerJam,
    required this.total,
    required this.statusPembayaran,
    this.redirectUrl,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      orderId: json['order_id'] ?? '',
      status: (json['status'] as String? ?? 'Unknown').toLowerCase(),
      nomorPlat: json['nomor_plat'],
      jenisKendaraan: json['jenis_kendaraan'],
      parkingArea: json['parking_area'],
      address: json['address'],
      vehicle: json['vehicle'],
      parkingSpot: json['parking_spot'],
      waktuMasuk: json['waktu_masuk'],
      qrData: json['qr_data'],
      tarifPerJam: json['tarif_per_jam'],
      total: json['total'],
      statusPembayaran: json['status_pembayaran'],
      redirectUrl: json['redirect_url'],
    );
  }
}

class TicketPage extends StatefulWidget {
  final int ticketId;

  const TicketPage({Key? key, required this.ticketId}) : super(key: key);

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  late Future<Ticket> futureTicket;

  @override
  void initState() {
    super.initState();
    futureTicket = fetchTicket();
  }

  // --- FUNGSI LOGIKA (TIDAK ADA PERUBAHAN) ---
  Future<Ticket> fetchTicket() async {
    final apiUrl =
        'https://app.parkintime.web.id/flutter/tiket.php?id=${widget.ticketId}';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          return Ticket.fromJson(jsonResponse['data']);
        } else {
          throw Exception('Failed to load ticket: ${jsonResponse['message']}');
        }
      } else {
        throw Exception(
          'Failed to connect to server. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception(
        'Failed to load data. Check your internet connection. Error: $e',
      );
    }
  }
  
  Future<void> _cancelOrder(String orderId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse('https://app.parkintime.web.id/flutter/cancel_booking.php'),
        body: {'order_id': orderId},
      );

      if (!mounted) return;

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order successfully canceled.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          futureTicket = fetchTicket();
        });
      } else {
        throw Exception(responseData['message'] ?? 'Failed to cancel order.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: ${e.toString().replaceFirst("Exception: ", "")}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteTicket(String orderId) {
    // Implementasikan logika hapus tiket yang sesungguhnya di sini
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleting ticket: $orderId')));
    Navigator.of(context).pop(true); // Kembali dan tandai ada perubahan
  }

  // --- UI WIDGETS (PERBAIKAN DI SINI) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF629584),
      appBar: AppBar(
        toolbarHeight: 50,
        backgroundColor: Color(0xFF629584),
        centerTitle: true,
        title: Text(
          'View Ticket',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: FutureBuilder<Ticket>(
        future: futureTicket,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final ticket = snapshot.data!;
            return buildTicketBody(context, ticket);
          }
          return const Center(
            child: Text(
              'No ticket data available.',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  // --- PERBAIKAN UTAMA PADA STRUKTUR LAYOUT ---
  Widget buildTicketBody(BuildContext context, Ticket ticket) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5), // Warna background untuk konten
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Konten yang bisa di-scroll
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildTicketDetailsCard(ticket),
            ),
          ),
          // Tombol aksi yang menempel di bawah
          _buildBottomActionBar(context, ticket),
        ],
      ),
    );
  }

  // Widget baru untuk kartu detail tiket
  Widget _buildTicketDetailsCard(Ticket ticket) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticket.orderId,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              buildTicketStatusBadge(ticket.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildHeaderInfo('Plate Number:', ticket.nomorPlat),
              buildHeaderInfo(
                'Vehicle Type',
                ticket.jenisKendaraan,
                isRight: true,
              ),
            ],
          ),
          const Divider(height: 30),
          buildInfoRow('Parking Area:', ticket.parkingArea),
          buildInfoRow('Address:', ticket.address),
          buildInfoRow('Vehicle:', ticket.vehicle),
          buildInfoRow('Parking Spot:', ticket.parkingSpot),
          buildInfoRow('Check-in Time:', ticket.waktuMasuk),
          const SizedBox(height: 20),
          Center(
            child: QrImageView(
              data: ticket.qrData,
              version: QrVersions.auto,
              size: 150.0,
              gapless: false,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          buildInfoRow('Price per Hour:', ticket.tarifPerJam),
          buildInfoRow('Total:', ticket.total),
          const SizedBox(height: 20),
          buildPaymentStatus(ticket.statusPembayaran),
        ],
      ),
    );
  }

  // Widget baru untuk action bar bawah yang aman dari potongan
  Widget _buildBottomActionBar(BuildContext context, Ticket ticket) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildActionButtons(context, ticket),
        ),
      ),
    );
  }

  // Widget untuk tombol aksi (logika tidak berubah)
  Widget _buildActionButtons(BuildContext context, Ticket ticket) {
    switch (ticket.status) {
      case 'pending':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (ticket.redirectUrl != null && ticket.redirectUrl!.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentWebViewPage(
                          paymentUrl: ticket.redirectUrl!,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment URL not found. Cannot proceed.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF629584),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue to Payment',
                  style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => _cancelOrder(ticket.orderId),
                child: const Text(
                  'Cancel Order',
                  style: TextStyle(fontSize: 16, color: Colors.red),
                ),
              ),
            ),
          ],
        );
      case 'canceled':
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => _deleteTicket(ticket.orderId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete Ticket',
              style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      default:
        return SizedBox.shrink(); 
    }
  }

  // --- WIDGET HELPER (TIDAK ADA PERUBAHAN) ---
  Widget buildHeaderInfo(String label, String value, {bool isRight = false}) {
    return Column(
      crossAxisAlignment:
          isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTicketStatusBadge(String status) {
    Color badgeColor;
    String displayText = status[0].toUpperCase() + status.substring(1);
    switch (status) {
      case 'valid':
        badgeColor = Colors.blue;
        break;
      case 'completed':
        badgeColor = Colors.green;
        break;
      case 'canceled':
        badgeColor = Colors.red;
        break;
      case 'pending':
        badgeColor = Colors.orange;
        break;
      default:
        badgeColor = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildPaymentStatus(String status) {
    bool isPaid = status.toLowerCase() == 'settlement';
    String displayStatus = isPaid ? 'Paid' : 'Pending';
    Color statusColor = isPaid ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPaid ? Icons.check_circle : Icons.error,
            color: statusColor,
          ),
          const SizedBox(width: 10),
          Text(
            'Payment Status: $displayStatus',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
