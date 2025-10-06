import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:apk_sukorame/src/screens/populations/add_edit_population_screen.dart';

class ManagePopulationsScreen extends StatefulWidget {
  const ManagePopulationsScreen({super.key});

  @override
  State<ManagePopulationsScreen> createState() => _ManagePopulationsScreenState();
}

class _ManagePopulationsScreenState extends State<ManagePopulationsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('populations');
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Data Kependudukan'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari Nama atau NIK',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: _dbRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                  return const Center(child: Text('Belum ada data penduduk.'));
                }

                final Map data = snapshot.data!.snapshot.value as Map;
                final List<Map> items = [];
                data.forEach((key, value) => items.add({"key": key, ...value}));

                final filteredItems = items.where((item) {
                  final nama = (item['nama_lengkap'] as String?)?.toLowerCase() ?? '';
                  final nik = (item['key'] as String?)?.toLowerCase() ?? '';
                  return nama.contains(_searchQuery.toLowerCase()) || nik.contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(child: Text('Data tidak ditemukan.'));
                }

                return ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final penduduk = filteredItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(penduduk['nama_lengkap'] ?? 'Tanpa Nama'),
                        subtitle: Text("NIK: ${penduduk['key']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(
                                builder: (context) => AddEditPopulationScreen(populationNik: penduduk['key']),
                              )),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(penduduk['key']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (context) => const AddEditPopulationScreen(),
        )),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(String nik) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Apakah Anda yakin ingin menghapus data penduduk ini?'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          TextButton(
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onPressed: () {
              _dbRef.child(nik).remove();
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }
}