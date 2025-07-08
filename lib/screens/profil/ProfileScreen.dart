import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkintime/screens/profil/edit_profile_screen.dart';
import 'package:parkintime/screens/profil/change_password_screen.dart';
import 'package:parkintime/screens/my_car/mycar_page.dart';
import 'package:parkintime/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = 'Loading...';
  String email = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        name = _capitalize(prefs.getString('user_name') ?? 'Guest User');
        email = prefs.getString('user_email') ?? 'guest@email.com';
      });
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text
        .split(' ')
        .map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    })
        .join(' ');
  }

  // --- PERBAIKAN: Dialog konfirmasi sebelum logout ---
  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User harus memilih salah satu tombol
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Log Out'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to log out?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Log Out', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Lebih baik clear semua data saat logout

                // Navigasi ke LoginScreen dan hapus semua halaman sebelumnya
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Warna background lebih cerah
      body: Stack(
        children: [
          // --- PERBAIKAN: Header dibuat terpisah untuk efek tumpuk ---
          _buildHeader(),

          // --- PERBAIKAN: Body utama dibuat bisa di-scroll ---
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100), // Beri ruang seukuran header
                _buildProfileCard(),
                const SizedBox(height: 20),
                _buildLogoutButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 150, // Tinggi header
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF629584),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- Info Pengguna ---
          Row(
            children: [
              const CircleAvatar(
                radius: 35,
                backgroundColor: Color(0xFFE0E0E0),
                child: Icon(Icons.person, size: 40, color: Color(0xFF629584)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),

          // --- Menu Item ---
          _buildMenuItem(
            icon: Icons.person_outline,
            text: "Edit Profile",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditProfileScreen()),
              ).then((_) => _loadUserInfo());
            },
          ),
          _buildMenuItem(
            icon: Icons.lock_outline,
            text: "Change Password",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.directions_car_outlined,
            text: "My Car",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageVehiclePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- PERBAIKAN: Tombol logout dibuat lebih baik dan responsif ---
  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity, // Lebar penuh
        child: TextButton.icon(
          icon: const Icon(Icons.logout),
          label: const Text("Log Out"),
          onPressed: _showLogoutConfirmationDialog, // Panggil dialog konfirmasi
          style: TextButton.styleFrom(
            foregroundColor: const Color.fromARGB(255, 242, 242, 242),
            backgroundColor: const Color.fromARGB(255, 255, 29, 63),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  // --- PERBAIKAN: Desain ulang item menu agar lebih menarik ---
  Widget _buildMenuItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.green.shade700),
      ),
      title: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
