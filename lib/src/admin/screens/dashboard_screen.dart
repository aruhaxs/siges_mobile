import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:apk_sukorame/src/admin/screens/scan_screen.dart';
import 'package:apk_sukorame/src/admin/screens/profile_screen.dart';
import 'package:apk_sukorame/src/admin/screens/news_screen.dart';
import 'package:apk_sukorame/src/admin/screens/gallery_screen.dart';
import 'package:apk_sukorame/src/admin/screens/event_list_screen.dart';
import 'package:apk_sukorame/src/admin/screens/add_admin_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

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

  void _showScanResultDialog(String result) {
    final bool isUrl = Uri.tryParse(result)?.isAbsolute ?? false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.qr_code_2, color: Colors.teal),
            SizedBox(width: 10),
            Text('Hasil Pindai'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kode yang dideteksi:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SelectableText(result),
            if (isUrl) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Buka Tautan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final uri = Uri.parse(result);
                  final messenger = ScaffoldMessenger.of(context);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Tidak dapat membuka tautan: $result'),
                      ),
                    );
                  }
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _navigateToScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const ScanScreen()),
    );

    if (result != null && mounted) {
      _showScanResultDialog(result);
    }
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
          'SIGES',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, size: 28),
            onSelected: (value) async { // ## JADIKAN ASYNC ##
              if (value == 'profil') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              } else if (value == 'add_admin') {
                // ## PERUBAHAN LOGIKA NAVIGASI ##
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (context) => const AddAdminScreen()),
                );

                if (result != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profil',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profil'),
                ),
              ),
              // ## PERUBAHAN ITEM MENU ##
              const PopupMenuItem<String>(
                value: 'add_admin',
                child: ListTile(
                  leading: Icon(Icons.person_add_alt_1),
                  title: Text('Tambah Akun'),
                ),
              ),
            ],
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
                'Menu Utama',
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
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan Barcode'),
              onTap: () {
                Navigator.pop(context);
                _navigateToScanner();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Pengaturan'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur Pengaturan segera hadir!'),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Tentang Aplikasi'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SIGES Versi 2.1')),
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
                          'Selamat Datang!',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentUser?.displayName ??
                              currentUser?.email ??
                              'Administrator SIGES',
                          style: const TextStyle(
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
                            color: _isOnline
                                ? Colors.white24
                                : Colors.red.shade300,
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
                    Icons.location_pin,
                    size: 50,
                    color: Colors.white54,
                  ),
                ],
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