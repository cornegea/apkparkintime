import 'package:flutter/material.dart';
import 'package:parkintime/screens/history/historyscreen.dart';
import 'package:parkintime/screens/profil/profilescreen.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart'; // Import package
import 'home_page_content.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePageContent(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  // List ikon untuk navigation bar baru
  final iconList = <IconData>[
    Icons.home_filled,
    Icons.history,
    Icons.person,
  ];
  
  // List label
  final labelList = <String>[
    "Home",
    "History",
    "Profile",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 254, 239, 238),
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      // GANTI WIDGET BottomNavigationBar DENGAN INI
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: iconList.length,
        tabBuilder: (int index, bool isActive) {
          final color = isActive ? Color(0xFF629584) : Colors.black54;
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                iconList[index],
                size: 24,
                color: color,
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  labelList[index],
                  maxLines: 1,
                  style: TextStyle(color: color, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
                ),
              )
            ],
          );
        },
        backgroundColor: Colors.white,
        activeIndex: _selectedIndex,
        splashColor: Color(0xFF629584),
        splashSpeedInMilliseconds: 300,
        notchSmoothness: NotchSmoothness.softEdge,
        gapLocation: GapLocation.none, // Kita tidak pakai floating button, jadi 'none'
        onTap: (index) => setState(() => _selectedIndex = index),
        shadow: BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 10,
        ),
      ),
    );
  }
}