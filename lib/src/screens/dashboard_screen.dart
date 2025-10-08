import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:apk_sukorame/src/screens/scan_screen.dart';
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
    _connectivitySubscription = InternetConnection().onStatusChange.listen((InternetStatus status) {
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
  
  // --- FUNGSI BARU UNTUK MENAMPILKAN DIALOG HASIL SCAN ---
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final uri = Uri.parse(result);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Tidak dapat membuka tautan: $result')),
                      );
                    }
                  }
                },
              ),
            ]
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

  void _showUserProfileDialog() {
    if (currentUser == null) return;
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Profil Admin'), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Nama: ${currentUser!.displayName ?? "Tidak diatur"}'), const SizedBox(height: 8), Text('Email: ${currentUser!.email ?? "Tidak ada"}'),],), actions: [TextButton(child: const Text('Tutup'), onPressed: () => Navigator.of(ctx).pop(),),],),);
  }
  void _showLogoutConfirmationDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('Konfirmasi Log Out'), content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal'),), TextButton(onPressed: () {Navigator.of(ctx).pop(); FirebaseAuth.instance.signOut();}, child: const Text('Log Out', style: TextStyle(color: Colors.red)),),],),);
  }
  Widget _buildStatCard({required IconData icon, required Color color, required String title, required Widget valueWidget,}) {
    return Card(elevation: 2.0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, size: 32, color: color), const SizedBox(height: 10), Text(title, style: const TextStyle(color: Colors.grey)), const SizedBox(height: 4), DefaultTextStyle(style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87,), child: valueWidget,),],),),);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SIGES', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, size: 28),
            onSelected: (value) {
              if (value == 'profil') {
                _showUserProfileDialog();
              } else if (value == 'logout') {
                _showLogoutConfirmationDialog();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'profil', child: ListTile(leading: Icon(Icons.person), title: Text('Profil'),),),
              const PopupMenuItem<String>(value: 'logout', child: ListTile(leading: Icon(Icons.logout), title: Text('Log Out'),),),
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
              decoration: BoxDecoration(color: Colors.teal,),
              child: Text('Menu Utama', style: TextStyle(color: Colors.white, fontSize: 24,),),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan Barcode'),
              onTap: () {
                Navigator.pop(context);
                _navigateToScanner();
              },
            ),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Pengaturan'), onTap: () {Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Pengaturan segera hadir!')),);},),
            ListTile(leading: const Icon(Icons.info_outline), title: const Text('Tentang Aplikasi'), onTap: () {Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aplikasi SIG Sukorame v1.0')),);},),
          ],
        ),
      ),
      backgroundColor: Colors.grey[100],
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(color: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), child: Padding(padding: const EdgeInsets.all(20.0), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Selamat Datang!', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),), const SizedBox(height: 8), Text(currentUser?.displayName ?? currentUser?.email ?? 'Administrator SIG Sukorame', style: const TextStyle(fontSize: 16, color: Colors.white70),), const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _isOnline ? Colors.white24 : Colors.red.shade300, borderRadius: BorderRadius.circular(12),), child: Text(_isOnline ? 'Status: Online' : 'Status: Offline', style: const TextStyle(color: Colors.white),),),],),), const Icon(Icons.location_pin, size: 50, color: Colors.white54),],),),),
          const SizedBox(height: 20),
          GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.2, children: [_buildStatCard(icon: Icons.people, color: Colors.blue, title: 'Total Penduduk', valueWidget: StreamBuilder(stream: FirebaseDatabase.instance.ref('populations').onValue, builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {if (snapshot.hasData && snapshot.data?.snapshot.value != null) {return Text('${snapshot.data!.snapshot.children.length}');} return const Text('0');},),), _buildStatCard(icon: Icons.apartment, color: Colors.brown, title: 'Total Bangunan', valueWidget: StreamBuilder(stream: FirebaseDatabase.instance.ref('buildings').onValue, builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {if (snapshot.hasData && snapshot.data?.snapshot.value != null) {return Text('${snapshot.data!.snapshot.children.length}');} return const Text('0');},),), _buildStatCard(icon: Icons.map, color: Colors.orange, title: 'Luas Wilayah', valueWidget: RichText(text: const TextSpan(style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87), children: [TextSpan(text: '8.2'), TextSpan(text: ' km²', style: TextStyle(fontSize: 14)),],),),), _buildStatCard(icon: Icons.show_chart, color: Colors.purple, title: 'Pertumbuhan', valueWidget: const Text('+2.3%'),),],),
        ],
      ),
    );
  }
}