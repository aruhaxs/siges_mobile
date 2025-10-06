import 'package:flutter/material.dart';
import 'package:apk_sukorame/src/screens/dashboard_screen.dart';
import 'package:apk_sukorame/src/screens/map_screen.dart';
import 'package:apk_sukorame/src/screens/buildings/manage_buildings_screen.dart';
import 'package:apk_sukorame/src/screens/populations/manage_populations_screen.dart'; // Import baru

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Halaman Dashboard dan Peta tetap, Kelola Data dipicu oleh tombol tengah
  static const List<Widget> _pages = <Widget>[
    DashboardScreen(),
    MapScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      // Tombol tengah ditekan
      _showManageDataOptions();
    } else {
      // Mengatur indeks untuk Dashboard (0) dan Peta (2 -> 1)
      setState(() {
        _selectedIndex = (index > 1) ? index - 1 : index;
      });
    }
  }
  
  void _showManageDataOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.apartment),
              title: const Text('Kelola Data Bangunan'),
              onTap: () {
                Navigator.pop(context); // Tutup bottom sheet
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageDataScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_alt),
              title: const Text('Kelola Data Kependudukan'),
              onTap: () {
                Navigator.pop(context); // Tutup bottom sheet
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ManagePopulationsScreen()));
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menentukan currentIndex yang benar untuk BottomNavigationBar
    int navIndex;
    if (_selectedIndex == 0) { // Dashboard
      navIndex = 0;
    } else if (_selectedIndex == 1) { // Peta
      navIndex = 2;
    } else {
      navIndex = 0; // Default
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.teal,
              child: const Icon(Icons.edit_document, color: Colors.white, size: 28),
            ),
            label: 'Kelola Data',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Peta',
          ),
        ],
        currentIndex: navIndex, // Menggunakan navIndex yang sudah dihitung
        onTap: _onItemTapped,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
    );
  }
}