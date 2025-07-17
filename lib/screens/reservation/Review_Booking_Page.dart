import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:parkintime/screens/payment_webview_page.dart'; // Make sure this import path is correct
import 'package:shared_preferences/shared_preferences.dart';

class ReviewBookingPage extends StatefulWidget {
  final String kodeslot;
  final String id_lahan;
  final String carid; // Vehicle ID
  final String date;
  final String duration;
  final String hours;
  final int total_price;
  final String vehiclePlate;
  final int pricePerHour;

  const ReviewBookingPage({
    super.key,
    required this.kodeslot,
    required this.id_lahan,
    required this.carid,
    required this.date,
    required this.duration,
    required this.hours,
    required this.total_price,
    required this.vehiclePlate,
    required this.pricePerHour,
  });

  @override
  State<ReviewBookingPage> createState() => _ReviewBookingPageState();
}

class _ReviewBookingPageState extends State<ReviewBookingPage> {
  String? parkingArea;
  String? address;
  String? vehicleName;
  bool _isLoading = true;
  bool _isCreatingOrder = false;
  String? _idAkun;

  final currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchPageDetails();
  }

  // --- LOGIC FUNCTIONS (NO MAJOR CHANGES) ---
  Future<void> _fetchPageDetails() async {
    setState(() {
      _isLoading = true;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _idAkun = prefs.getInt('id_akun')?.toString();

      if (_idAkun == null) {
        throw Exception("User not logged in.");
      }

      // Fetching data in parallel
      await Future.wait([
        _fetchLahanDetails(),
        _fetchVehicleDetails(),
      ]);
    } catch (e) {
      print("Error fetching page details: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchLahanDetails() async {
    try {
      final response = await http.get(Uri.parse('https://app.parkintime.web.id/flutter/get_lahan.php'));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body)['data'];
        final lahanData = data.firstWhere((l) => l['id'].toString() == widget.id_lahan, orElse: () => null);
        if (lahanData != null) {
          setState(() {
            parkingArea = lahanData['nama_lokasi'];
            address = lahanData['alamat'];
          });
        }
      }
    } catch (e) {
      print("Error fetching lahan: $e");
    }
  }

  Future<void> _fetchVehicleDetails() async {
    if (_idAkun == null) return;
    try {
      final response = await http.get(Uri.parse('https://app.parkintime.web.id/flutter/get_car.php?id_akun=$_idAkun'));
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body)['data'];
        final carData = data.firstWhere((c) => c['id'].toString() == widget.carid, orElse: () => null);
        if (carData != null) {
          setState(() {
            vehicleName = "${carData['merek'] ?? ''} ${carData['tipe'] ?? ''}".trim();
          });
        }
      }
    } catch (e) {
      print("Error fetching vehicle: $e");
    }
  }

   Future<void> _createBookingAndPay() async {
    if (_idAkun == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isCreatingOrder = true;
    });

    http.Response? response;

    try {
      final String timePart = widget.hours.split(' - ')[0];
      final String waktuMasukInput = "${widget.date} $timePart";
      final bool is12HourFormat = timePart.contains("AM") || timePart.contains("PM");
      final DateFormat inputFormatter = is12HourFormat ? DateFormat('yyyy-MM-dd hh:mm a', 'id_ID') : DateFormat('yyyy-MM-dd HH:mm');
      final DateFormat outputFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      final DateTime waktuMasuk = inputFormatter.parse(waktuMasukInput);
      final String waktuMasukForApi = outputFormatter.format(waktuMasuk);
      final int durasiJam = int.tryParse(widget.duration.split(' ')[0]) ?? 0;
      final DateTime waktuKeluar = waktuMasuk.add(Duration(hours: durasiJam));
      final String waktuKeluarForApi = outputFormatter.format(waktuKeluar);

      final requestBody = {
        'id_akun': _idAkun,
        'id_slot': widget.kodeslot,
        'id_kendaraan': widget.carid,
        'biaya_total': widget.total_price.toString(),
        'waktu_masuk': waktuMasukForApi,
        'waktu_keluar': waktuKeluarForApi,
      };

      final url = Uri.parse('https://app.parkintime.web.id/flutter/create_booking.php');

      response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          final String redirectUrl = responseData['redirect_url'];

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentWebViewPage(
                paymentUrl: redirectUrl,
              ),
            ),
          );
        } else {
          throw Exception(responseData['message'] ?? 'Failed to create booking.');
        }
      } else {
        final responseData = jsonDecode(response.body);
        final errorMessage = responseData['message'] ?? 'Server Error. Status Code: ${response.statusCode}';
        throw Exception(errorMessage);
      }

    } catch (e) {
      String errorMessage = e.toString();
       if (e is FormatException && response != null) {
        errorMessage = "Failed to parse JSON. Server Response:\n${response.body}";
      } else if (e is FormatException) {
        errorMessage = "Failed to parse date/time. Input was: '${widget.date} ${widget.hours.split(' - ')[0]}'. Error: ${e.message}";
      }

      print("--- ERROR LOG ---\n$errorMessage\n--- END ERROR LOG ---");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage.replaceFirst("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingOrder = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Background color for contrast
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Color(0xFF629584),
        centerTitle: true,
        title: Text(
          'Review Booking',
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF629584)))
          : Column(
              children: [
                // --- SCROLLABLE CONTENT ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Booking Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          buildDetailRow('Parking Area', parkingArea ?? 'Loading...'),
                          buildDetailRow('Address', address ?? 'Loading...'),
                          buildDetailRow('Plate Number', widget.vehiclePlate),
                          buildDetailRow('Vehicle', vehicleName ?? 'Loading...'),
                          buildDetailRow('Parking Slot', widget.kodeslot),
                          buildDetailRow('Date', widget.date),
                          buildDetailRow('Duration', widget.duration),
                          buildDetailRow('Hours', widget.hours),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: Divider(),
                          ),
                          Text(
                            "Payment Details",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          buildDetailRow('Price per Hour', currencyFormatter.format(widget.pricePerHour)),
                          buildDetailRow('Duration', widget.duration),
                          const SizedBox(height: 8),
                          buildDetailRow(
                            'Total Payment',
                            currencyFormatter.format(widget.total_price),
                            isTotal: true, // Flag for total style
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // --- BOTTOM ACTION BUTTON ---
                _buildPaymentButton(),
              ],
            ),
    );
  }

  // New widget for the payment button to keep the build method clean
  Widget _buildPaymentButton() {
    return Container(
      // Padding adjusted to raise the button
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), 
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SizedBox(
        height: 55,
        child: ElevatedButton(
          onPressed: _isCreatingOrder ? null : _createBookingAndPay,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF00695C), // A more solid green color
            disabledBackgroundColor: Colors.green.shade200,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isCreatingOrder
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  'Create Order & Continue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // Helper widget for detail rows with updated style
  Widget buildDetailRow(String title, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
                fontSize: isTotal ? 18 : 15,
                color: isTotal ? Color(0xFF00695C) : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
