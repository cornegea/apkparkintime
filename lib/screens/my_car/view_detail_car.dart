import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ViewDetailCarPage extends StatelessWidget {
  final Map<String, String> carData;

  const ViewDetailCarPage({super.key, required this.carData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Color(0xFF629584),
        centerTitle: true, // ✅ Tengahin judul
        title: Text(
          'Management Car',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '* Vehicle data must match the actual data',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  carData['plate'] ?? '',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Last 4 digits of chassis number"),
            ),
            const SizedBox(height: 6),
            const TextField(
              decoration: InputDecoration(
                hintText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const Divider(height: 32, thickness: 1),
            _buildDetailItem("Registration Number", carData["plate"]),
            _buildDetailItem("Name of Owner", carData["owner"]),
            _buildDetailItem("Brand", carData["brand"]),
            _buildDetailItem("Type", carData["type"]),
            _buildDetailItem("Category", carData["category"]),
            _buildDetailItem("Color", carData["color"]),
            _buildDetailItem("Manufacture Year", carData["year"]),
            _buildDetailItem("Cylinder Capacity", carData["capacity"]),
            _buildDetailItem("Energy Source", carData["energy"]),
            _buildDetailItem("Licence Plate Color", carData["plateColor"]),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _showDeleteConfirmation(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Remove Car",style: const TextStyle(
            
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Expanded(
            child: Text(
              value?.toUpperCase() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 40),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.shade100,
                    ),
                    child: const Icon(Icons.close, color: Colors.red, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Are you sure you want to remove this vehicle?",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            backgroundColor: Colors.grey.shade300,
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _deleteCar(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("Remove"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _deleteCar(BuildContext context) async {
    final String carId = carData['carId'] ?? '';

    if (carId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid car ID")));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://app.parkintime.web.id/flutter/delete_car.php'),
        body: {'id': carId},
      );

      final result = jsonDecode(response.body);

      if (result['status']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Car removed successfully")),
        );
        Navigator.of(context).pop(true); // kembali dan trigger refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to remove car')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
