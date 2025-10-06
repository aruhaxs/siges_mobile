import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:apk_sukorame/src/screens/dashboard_screen.dart';
import 'package:apk_sukorame/src/screens/map_screen.dart';
import 'package:apk_sukorame/src/screens/buildings/manage_buildings_screen.dart';
import 'package:apk_sukorame/src/screens/populations/manage_populations_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    DashboardScreen(),
    MapScreen(),
  ];

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        animationCurve: Curves.bounceInOut,
        animationDuration: const Duration(milliseconds: 300),
        children: [
          _buildSpeedDialChild(
            icon: Icons.people_alt,
            backgroundColor: Colors.orange,
            label: 'Penduduk',
            onTap: () => _navigateTo(const ManagePopulationsScreen()),
          ),
          _buildSpeedDialChild(
            icon: Icons.apartment,
            backgroundColor: Colors.blue,
            label: 'Bangunan',
            onTap: () => _navigateTo(const ManageBuildingsScreen()),
          ),
          _buildSpeedDialChild(
            icon: Icons.map,
            backgroundColor: Colors.red,
            label: 'Peta',
            onTap: () => setState(() => _selectedIndex = 1),
          ),
          _buildSpeedDialChild(
            icon: Icons.dashboard,
            backgroundColor: Colors.green,
            label: 'Dashboard',
            onTap: () => setState(() => _selectedIndex = 0),
          ),
        ],
      ),
    );
  }

  SpeedDialChild _buildSpeedDialChild({
    required IconData icon,
    required Color backgroundColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return SpeedDialChild(
      child: Icon(icon),
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      label: label,
      labelStyle: const TextStyle(fontSize: 14.0, color: Colors.black),
      labelBackgroundColor: Colors.white,
      onTap: onTap,
    );
  }
}