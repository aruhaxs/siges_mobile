import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('buildings');
  final List<Color> _pieColors = [
    Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.brown,
  ];

  void _showUserProfile() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Profil Pengguna'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Username: ${user.displayName ?? 'Tidak ada'}"),
                const SizedBox(height: 8),
                Text("Email: ${user.email ?? 'Tidak ada'}"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Sukorame'),
        backgroundColor: Colors.teal,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profil') {
                _showUserProfile();
              } else if (value == 'logout') {
                FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profil',
                child: Text('Profil'),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Text('Log Out'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder(
        // ... sisa kode body tidak berubah ...
        stream: _dbRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Belum ada data bangunan.\nTekan tombol "Kelola Data" di bawah untuk menambahkan data pertama Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final Map<String, int> categoryCount = {};
          data.forEach((key, value) {
            final kategori = value['kategori'] as String? ?? 'Lainnya';
            categoryCount[kategori] = (categoryCount[kategori] ?? 0) + 1;
          });
          int totalBangunan = data.length;
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Total Bangunan Terdata: $totalBangunan',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Text(
                'Distribusi Kategori Bangunan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: _generatePieChartSections(categoryCount, totalBangunan),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Legenda', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildLegend(categoryCount),
            ],
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections(
      Map<String, int> counts, int total) {
    int i = 0;
    if (total == 0) return [];
    return counts.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      final section = PieChartSectionData(
        color: _pieColors[i % _pieColors.length],
        value: entry.value.toDouble(),
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
      i++;
      return section;
    }).toList();
  }

  Widget _buildLegend(Map<String, int> counts) {
    int i = 0;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: counts.entries.map((entry) {
        final widget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              color: _pieColors[i % _pieColors.length],
            ),
            const SizedBox(width: 8),
            Text("${entry.key} (${entry.value})"),
          ],
        );
        i++;
        return widget;
      }).toList(),
    );
  }
}
