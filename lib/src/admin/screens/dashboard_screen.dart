import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Hapus import Realtime Database jika tidak dipakai lagi
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:apk_sukorame/src/admin/screens/scan_screen.dart';
import 'package:apk_sukorame/src/admin/screens/profile_screen.dart';
import 'package:apk_sukorame/src/admin/screens/news_screen.dart';
import 'package:apk_sukorame/src/admin/screens/gallery_screen.dart';
import 'package:apk_sukorame/src/admin/screens/event_list_screen.dart';
import 'package:apk_sukorame/src/admin/screens/add_admin_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/auth_gate.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool _isOnline = true;
  late StreamSubscription<InternetStatus> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkInternetStatus();
    _connectivitySubscription = InternetConnection().onStatusChange.listen(
      (InternetStatus status) {
        if (mounted) {
          setState(() {
            _isOnline = (status == InternetStatus.connected);
          });
        }
      },
    );
  }

  Future<void> _checkInternetStatus() async {
     bool result = await InternetConnection().hasInternetAccess;
     if (mounted) {
       setState(() {
         _isOnline = result;
       });
     }
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
            const Text('Kode yang dideteksi:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SelectableText(result),
            if (isUrl) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Buka Tautan'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: () async {
                  final uri = Uri.parse(result);
                  final currentContext = context;
                  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                     if (mounted) {
                       ScaffoldMessenger.of(currentContext).showSnackBar(
                         SnackBar(content: Text('Tidak dapat membuka tautan: $result')),
                       );
                     }
                  }
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  void _navigateToScanner() async {
    final result = await Navigator.push<String>(
      context, MaterialPageRoute(builder: (context) => const ScanScreen()),
    );
    if (result != null && mounted) {
      _showScanResultDialog(result);
    }
  }

  Widget _buildStatCard({
    required IconData icon, required Color color, required String title, required Widget valueWidget,
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
            Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
            const SizedBox(height: 4),
            DefaultTextStyle(
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
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
        title: const Text('SIGES', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 28),
            onSelected: (value) async {
              if (value == 'profil') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              } else if (value == 'add_admin') {
                final result = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const AddAdminScreen()));
                if (result != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.green));
                }
              } else if (value == 'logout') {
                final bool? confirmLogout = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Konfirmasi Log Out'),
                    content: const Text('Apakah Anda yakin ingin keluar?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
                      TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Log Out', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirmLogout == true) {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const AuthGate()), (Route<dynamic> route) => false);
                  }
                }
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'profil', child: ListTile(leading: Icon(Icons.person), title: Text('Profil'))),
              const PopupMenuItem<String>(value: 'add_admin', child: ListTile(leading: Icon(Icons.person_add_alt_1), title: Text('Tambah Akun'))),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(value: 'logout', child: ListTile(leading: Icon(Icons.logout, color: Colors.red), title: Text('Log Out', style: TextStyle(color: Colors.red)))),
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
              child: Text('Menu Utama', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(leading: const Icon(Icons.collections), title: const Text('Galeri Sukorame'), onTap: () {
                Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryScreen())); }),
            ListTile(leading: const Icon(Icons.newspaper), title: const Text('Berita Terkini'), onTap: () {
                Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const WebViewScreen(url: 'https://radarkediri.jawapos.com/tag/sukorame#google_vignette', title: 'Berita Terkini'))); }),
            ListTile(leading: const Icon(Icons.event), title: const Text('Jadwal Kegiatan'), onTap: () {
                Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const EventListScreen())); }),
            ListTile(leading: const Icon(Icons.qr_code_scanner), title: const Text('Scan Barcode'), onTap: () {
                Navigator.pop(context); _navigateToScanner(); }),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Pengaturan'), onTap: () {
                Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Pengaturan segera hadir!'))); }),
            ListTile(leading: const Icon(Icons.info_outline), title: const Text('Tentang Aplikasi'), onTap: () {
                Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SIGES Versi 2.1'))); }),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              color: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Selamat Datang!', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(currentUser?.displayName ?? currentUser?.email ?? 'Administrator SIGES', style: const TextStyle(fontSize: 16, color: Colors.white70)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: _isOnline ? Colors.white24 : Colors.red.shade300, borderRadius: BorderRadius.circular(12)),
                            child: Text(_isOnline ? 'Status: Online' : 'Status: Offline', style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.location_pin, size: 50, color: Colors.white54),
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
                  // --- PERUBAHAN DI SINI ---
                  valueWidget: StreamBuilder<QuerySnapshot>( // Ganti ke QuerySnapshot
                    stream: FirebaseFirestore.instance.collection('populations').snapshots(), // Ganti stream ke Firestore
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
                      }
                      if (snapshot.hasError) {
                         debugPrint("Error reading populations count from Firestore: ${snapshot.error}");
                         return const Text('!', style: TextStyle(color: Colors.red));
                      }
                      // Hitung jumlah dokumen dari QuerySnapshot
                      int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return Text('$count');
                    },
                  ),
                  // --- AKHIR PERUBAHAN ---
                ),
                _buildStatCard(
                  icon: Icons.apartment,
                  color: Colors.brown,
                  title: 'Total Bangunan',
                  // Biarkan ini menggunakan Realtime DB jika data 'buildings' masih di sana
                  valueWidget: StreamBuilder<DatabaseEvent>(
                    stream: FirebaseDatabase.instance.ref('buildings').onValue,
                    builder: (context, snapshot) {
                       if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
                      }
                       if (snapshot.hasError) {
                          debugPrint("Error reading buildings count: ${snapshot.error}");
                          return const Text('!', style: TextStyle(color: Colors.red));
                       }
                       int count = 0;
                       if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                         final dynamic rawValue = snapshot.data!.snapshot.value;
                         if (rawValue is Map) {
                            count = rawValue.length;
                         } else if (rawValue is List) {
                            count = rawValue.where((item) => item != null).length;
                         } else {
                            debugPrint("Buildings data format unknown: ${rawValue.runtimeType}");
                         }
                      }
                      return Text('$count');
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
      ),
    );
  }
}