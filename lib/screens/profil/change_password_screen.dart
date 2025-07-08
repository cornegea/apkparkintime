import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Perbaikan: Tambahkan FocusNode untuk mendeteksi status fokus pada TextField
  final _currentPasswordFocus = FocusNode();
  final _newPasswordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Perbaikan: Tambahkan listener ke FocusNode di initState
  @override
  void initState() {
    super.initState();
    _currentPasswordFocus.addListener(() => setState(() {}));
    _newPasswordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));
  }

  // Perbaikan: Jangan lupa dispose FocusNode untuk menghindari memory leak
  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    _currentPasswordFocus.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }


  Future<void> _changePassword() async {
    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackbar("Please fill in all fields");
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackbar("New passwords do not match");
      return;
    }

    // Tampilkan loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(child: CircularProgressIndicator(color: Color(0xFF629584)));
      },
    );

    try {
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString('user_email') ?? '';

        final response = await http.post(
        Uri.parse('https://app.parkintime.web.id/flutter/change_password.php'),
        body: {
            'email': email,
            'current_password': currentPassword,
            'new_password': newPassword,
        },
        );

        Navigator.pop(context); // Tutup loading indicator

        if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['success']) {
                _showSnackbar("Password changed successfully");
                Navigator.pop(context); // Kembali ke halaman sebelumnya
            } else {
                _showSnackbar(data['message'] ?? "Failed to change password");
            }
        } else {
            _showSnackbar("Server error: ${response.statusCode}");
        }
    } catch (e) {
        Navigator.pop(context); // Tutup loading indicator jika ada error
        _showSnackbar("An error occurred. Please try again.");
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Perbaikan: Definisikan warna utama agar mudah digunakan kembali
    const primaryColor = Color(0xFF629584);

    return Scaffold(
      // Perbaikan: Ganti warna background agar lebih soft
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 80, // Sedikit kurangi tinggi toolbar
        backgroundColor: primaryColor,
        // Perbaikan: Hilangkan shadow bawaan AppBar
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Change Password',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, // Menggunakan ikon standar yang lebih universal
            color: Colors.white,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        // Perbaikan: Beri padding di luar container agar ada jarak dari tepi layar
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            // Perbaikan: Shadow dibuat lebih soft dan menyebar
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 4,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPasswordField(
                label: "Current Password",
                hint: "Enter current password",
                controller: currentPasswordController,
                obscureText: _obscureCurrent,
                focusNode: _currentPasswordFocus, // kirim focus node
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),
              // Perbaikan: Atur ulang jarak antar field
              const SizedBox(height: 20),
              _buildPasswordField(
                label: "New Password",
                hint: "Enter new password",
                controller: newPasswordController,
                obscureText: _obscureNew,
                focusNode: _newPasswordFocus, // kirim focus node
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                label: "Confirm New Password",
                hint: "Re-enter new password",
                controller: confirmPasswordController,
                obscureText: _obscureConfirm,
                focusNode: _confirmPasswordFocus, // kirim focus node
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              // Perbaikan: Atur ulang jarak ke tombol
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white, // Warna ripple effect
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    // Perbaikan: Tambahkan shadow kecil pada tombol agar terkesan "timbul"
                    elevation: 2,
                  ),
                  child: const Text(
                    "Change Password",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Perbaikan: Tambahkan parameter FocusNode
  Widget _buildPasswordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    required FocusNode focusNode,
  }) {
    // Perbaikan: Definisikan warna utama
    const primaryColor = Color(0xFF629584);
    final bool isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Perbaikan: Style label dibuat lebih tegas
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF424242))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          focusNode: focusNode, // Gunakan FocusNode
          decoration: InputDecoration(
            hintText: hint,
            // Perbaikan: Ubah warna ikon berdasarkan status fokus
            prefixIcon: Icon(Icons.lock_outline, color: isFocused ? primaryColor : Colors.grey),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                // Perbaikan: Ubah warna ikon berdasarkan status fokus
                color: isFocused ? primaryColor : Colors.grey,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            // Perbaikan: Border dibuat lebih sederhana dan konsisten
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryColor, width: 2.0),
            ),
          ),
        ),
      ],
    );
  }
}