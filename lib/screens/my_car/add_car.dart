import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddCarScreen extends StatefulWidget {
  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  // --- Kontroler & State yang Sudah Ada ---
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _chassisController = TextEditingController();
  Map<String, String>? _vehicleData;
  bool _isLoading = false;
  String? _message;

  // --- State Baru untuk Mode Manual ---
  bool _isManualMode = false;
  final _formKey = GlobalKey<FormState>(); // Kunci untuk validasi form manual
  final TextEditingController _ownerController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _energyController = TextEditingController();
  final TextEditingController _plateColorController = TextEditingController();

  final String _fetchUrl = "https://app.parkintime.web.id/flutter/car.php";
  final String _submitUrl = "https://app.parkintime.web.id/flutter/add_car.php";

  // --- [MODIFIKASI] State untuk validasi tombol manual ---
  bool _isPlateFilled = false;
  bool _isChassisFilled = false;
  bool _isConnectionFailed = false;

  @override
  void initState() {
    super.initState();
    // Tambahkan listener untuk memantau perubahan input
    _plateController.addListener(_updateInputStatus);
    _chassisController.addListener(_updateInputStatus);
  }

  void _updateInputStatus() {
    setState(() {
      _isPlateFilled = _plateController.text.trim().isNotEmpty;
      _isChassisFilled = _chassisController.text.trim().length == 4;
    });
  }


  Future<void> _fetchVehicleData() async {
    // Jangan fetch jika sedang dalam mode manual
    if (_isManualMode) return;

    final plat = _plateController.text.trim().toUpperCase();
    final rangka = _chassisController.text.trim();

    // Panggil _updateInputStatus untuk memastikan state ter-update
    _updateInputStatus();

    if (plat.isEmpty || rangka.length != 4) {
      setState(() {
        _vehicleData = null;
        // Reset pesan jika input tidak valid
        _message = null;
        _isConnectionFailed = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
      _vehicleData = null;
      _isConnectionFailed = false; // Reset status koneksi gagal
    });

    try {
      final response = await http.post(
        Uri.parse(_fetchUrl),
        body: {"noreg": plat, "bbn": '0', "norangka": rangka},
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        final info = Map<String, dynamic>.from(data['data']);
        setState(() {
          _vehicleData = {
            "Registration Number": info['no_kendaraan'] ?? '',
            "Name of Owner": info['pemilik'] ?? '',
            "Brand": info['merek'] ?? '',
            "Type": info['tipe'] ?? '',
            "Category": info['kategori'] ?? '',
            "Color": info['warna'] ?? '',
            "Manufacture Year": info['tahun'] ?? '',
            "Cylinder Capacity": info['kapasitas'] ?? '',
            "Energy Source": info['energi'] ?? '',
            "License Plate Color": info['warna_plat'] ?? '',
          };
          _isConnectionFailed = false;
        });
      } else {
        setState(() {
          _vehicleData = null;
          _message = data['message'] ?? 'Failed to fetch data. Try again or add manually.';
          // Cek jika pesan dari server BUKAN kegagalan koneksi
          _isConnectionFailed = false;
        });
      }
    } catch (e) {
      setState(() {
        _vehicleData = null;
        _message = "Failed to connect to server. Check your connection or add car manually.";
        // --- [MODIFIKASI] Set flag koneksi gagal menjadi true ---
        _isConnectionFailed = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addCar() async {
    final prefs = await SharedPreferences.getInstance();
    final idAkun = prefs.getInt('id_akun');

    if (idAkun == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User is not logged in")),
      );
      return;
    }

    Map<String, String> carDataPayload;

    if (_isManualMode) {
      if (!_formKey.currentState!.validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill in all required fields.")),
        );
        return;
      }
      carDataPayload = {
        'id_akun': idAkun.toString(),
        'no_kendaraan': _plateController.text.toUpperCase(),
        'pemilik': _ownerController.text,
        'merek': _brandController.text,
        'tipe': _typeController.text,
        'kategori': _categoryController.text,
        'warna': _colorController.text,
        'tahun': _yearController.text,
        'kapasitas': _capacityController.text,
        'energi': _energyController.text,
        'warna_plat': _plateColorController.text,
      };
    } else {
      if (_vehicleData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Vehicle data not available")),
        );
        return;
      }
      carDataPayload = {
        'id_akun': idAkun.toString(),
        'no_kendaraan': _vehicleData!["Registration Number"] ?? '',
        'pemilik': _vehicleData!["Name of Owner"] ?? '',
        'merek': _vehicleData!["Brand"] ?? '',
        'tipe': _vehicleData!["Type"] ?? '',
        'kategori': _vehicleData!["Category"] ?? '',
        'warna': _vehicleData!["Color"] ?? '',
        'tahun': _vehicleData!["Manufacture Year"] ?? '',
        'kapasitas': _vehicleData!["Cylinder Capacity"] ?? '',
        'energi': _vehicleData!["Energy Source"] ?? '',
        'warna_plat': _vehicleData!["License Plate Color"] ?? '',
      };
    }

    setState(() { _isLoading = true; });

    try {
      final response = await http.post(
        Uri.parse(_submitUrl),
        body: carDataPayload,
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Car added successfully!")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Failed to add car")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Connection failed")),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  void dispose() {
    // Jangan lupa remove listener untuk menghindari memory leak
    _plateController.removeListener(_updateInputStatus);
    _chassisController.removeListener(_updateInputStatus);
    _plateController.dispose();
    _chassisController.dispose();
    _ownerController.dispose();
    _brandController.dispose();
    _typeController.dispose();
    _categoryController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    _capacityController.dispose();
    _energyController.dispose();
    _plateColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- [MODIFIKASI] Definisikan kondisi untuk menampilkan tombol manual di sini agar lebih rapi ---
    final bool shouldShowManualButton = _isPlateFilled &&
        _isChassisFilled &&
        _isConnectionFailed &&
        !_isLoading &&
        !_isManualMode;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 231, 227, 227),
      appBar: AppBar(
        toolbarHeight: 90,
        backgroundColor: Color(0xFF629584),
        centerTitle: true,
        title: Text(
          'Add Car',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("* Vehicle data must match the original vehicle data. Currently only available for the Riau Islands province",
                style: TextStyle(color: Colors.red, fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Center(
                child: TextField(
                  controller: _plateController,
                  readOnly: _isManualMode,
                  // Gunakan onChanged untuk memanggil fetch data
                  onChanged: (value) => _fetchVehicleData(),
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    UpperCaseTextFormatter(),
                  ],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "BP1234YY",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (!_isManualMode) _buildApiSearchSection(),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Center(child: CircularProgressIndicator()),
              ),

            // --- [MODIFIKASI] Tampilkan pesan error jika ada ---
            if (_message != null && !_isLoading && !_isManualMode)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _message!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            // --- [MODIFIKASI] Gunakan kondisi yang sudah didefinisikan untuk menampilkan tombol manual ---
            if (shouldShowManualButton)
              _buildManualButton(),

            if (_vehicleData != null && !_isLoading && !_isManualMode)
              _buildVehicleDataDisplay(),

            if (_isManualMode) _buildManualForm(),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_vehicleData != null || _isManualMode) && !_isLoading ? _addCar : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF629584),
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text("Add Car", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Last 4 digits of chassis number"),
        const SizedBox(height: 8),
        TextField(
          controller: _chassisController,
          // Gunakan onChanged untuk memanggil fetch data
          onChanged: (value) => _fetchVehicleData(),
          keyboardType: TextInputType.text,
          inputFormatters: [UpperCaseTextFormatter()],
          maxLength: 4,
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            hintText: "Example: 4H56",
          ),
        ),
      ],
    );
  }

  // --- [MODIFIKASI] Widget ini sekarang hanya untuk tombol, pesannya ditampilkan terpisah ---
  Widget _buildManualButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _isManualMode = true;
              _message = null; // Hapus pesan error agar tidak tumpang tindih
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF629584),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            "Add Manually",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleDataDisplay() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _vehicleData!.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Text("${entry.key}:", style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  flex: 5,
                  child: Text(entry.value, style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildManualForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          Text("Please fill in the vehicle details manually:", style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 16),
          _buildManualTextField(_ownerController, "Name of Owner", "Example: Budi Santoso"),
          _buildManualTextField(_brandController, "Brand", "Example: TOYOTA"),
          _buildManualTextField(_typeController, "Type", "Example: AVANZA"),
          _buildManualTextField(_categoryController, "Category", "Example: MINIBUS"),
          _buildManualTextField(_colorController, "Color", "Example: HITAM"),
          _buildManualTextField(_yearController, "Manufacture Year", "Example: 2022", keyboardType: TextInputType.number),
          _buildManualTextField(_capacityController, "Cylinder Capacity", "Example: 1500", keyboardType: TextInputType.number),
          _buildManualTextField(_energyController, "Energy Source", "Example: BENSIN"),
          _buildManualTextField(_plateColorController, "License Plate Color", "Example: HITAM"),
        ],
      ),
    );
  }

  Widget _buildManualTextField(TextEditingController controller, String label, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'This field cannot be empty';
          }
          return null;
        },
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}