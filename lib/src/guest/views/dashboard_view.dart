import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:apk_sukorame/src/admin/screens/news_screen.dart';
import 'package:apk_sukorame/src/admin/screens/gallery_screen.dart';
import 'package:apk_sukorame/src/admin/screens/event_list_screen.dart';
import 'package:apk_sukorame/src/admin/screens/map_screen.dart';

class GuestDashboardScreen extends StatefulWidget {
  const GuestDashboardScreen({super.key});

  @override
  State<GuestDashboardScreen> createState() => _GuestDashboardScreenState();
}

class _GuestDashboardScreenState extends State<GuestDashboardScreen> {
  bool _isOnline = false;
  late StreamSubscription<InternetStatus> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = InternetConnection().onStatusChange.listen((
      InternetStatus status,
    ) {
      if (mounted) {
        setState(() {
          _isOnline = (status == InternetStatus.connected);
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color color,
    required String title,
    required Widget valueWidget,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              child: valueWidget,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SIGES (Guest)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.login),
            label: const Text('Login Admin'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            // ## PERUBAHAN UTAMA: Logika Tombol Login Admin ##
            onPressed: () async {
              // Cukup logout dari sesi anonim. AuthGate akan menangani sisanya.
              await FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text(
                'Menu Informasi',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.collections),
              title: const Text('Galeri Sukorame'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GalleryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.newspaper),
              title: const Text('Berita Terkini'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WebViewScreen(
                      url: 'https://radarkediri.jawapos.com/tag/sukorame#google_vignette',
                      title: 'Berita Terkini',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Jadwal Kegiatan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventListScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Tentang Aplikasi'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Aplikasi SIG Sukorame v1.0')),
                );
              },
            ),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            color: Colors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat Datang, Tamu!',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Jelajahi informasi Desa Sukorame',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _isOnline ? Colors.white24 : Colors.red.shade300,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isOnline ? 'Status: Online' : 'Status: Offline',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.explore,
                    size: 50,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2.0,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );
              },
              child: const ListTile(
                leading: Icon(Icons.map_outlined, color: Colors.teal, size: 32),
                title: Text('Peta Desa', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Lihat persebaran bangunan di Sukorame'),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                icon: Icons.people,
                color: Colors.blue,
                title: 'Total Penduduk',
                valueWidget: StreamBuilder(
                  stream: FirebaseDatabase.instance.ref('populations').onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data?.snapshot.value != null) {
                      return Text('${(snapshot.data!.snapshot.value as Map).length}');
                    }
                    return const Text('0');
                  },
                ),
              ),
              _buildStatCard(
                icon: Icons.apartment,
                color: Colors.brown,
                title: 'Total Bangunan',
                valueWidget: StreamBuilder(
                  stream: FirebaseDatabase.instance.ref('buildings').onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data?.snapshot.value != null) {
                      return Text('${(snapshot.data!.snapshot.value as Map).length}');
                    }
                    return const Text('0');
                  },
                ),
              ),
              _buildStatCard(
                icon: Icons.map,
                color: Colors.orange,
                title: 'Luas Wilayah',
                valueWidget: const Text('3.85 km²'),
              ),
              _buildStatCard(
                icon: Icons.show_chart,
                color: Colors.purple,
                title: 'Pertumbuhan',
                valueWidget: const Text('+2.3%'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}