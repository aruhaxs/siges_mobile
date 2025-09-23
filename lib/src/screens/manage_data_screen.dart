import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:apk_sukorame/src/screens/add_edit_screen.dart';
import 'package:apk_sukorame/src/screens/detail_screen.dart';

enum SortOrder { asc, desc }

class ManageDataScreen extends StatefulWidget {
  const ManageDataScreen({super.key});

  @override
  State<ManageDataScreen> createState() => _ManageDataScreenState();
}

class _ManageDataScreenState extends State<ManageDataScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('buildings');
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  SortOrder _sortOrder = SortOrder.asc;

  final List<String> _kategoriOptions = [
    'Semua', 'Pendidikan', 'Kesehatan', 'Tempat Ibadah', 'UMKM', 'Kantor Pemerintahan', 'Lainnya'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
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
        title: const Text('Kelola Data Bangunan'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari Nama Bangunan',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10.0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                    ),
                    items: _kategoriOptions.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCategory = newValue!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _sortOrder == SortOrder.asc ? Icons.arrow_downward : Icons.arrow_upward,
                  ),
                  tooltip: _sortOrder == SortOrder.asc ? 'Sortir Z-A' : 'Sortir A-Z',
                  onPressed: () {
                    setState(() {
                      _sortOrder = _sortOrder == SortOrder.asc ? SortOrder.desc : SortOrder.asc;
                    });
                  },
                ),
              ],
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
                  return const Center(child: Text('Belum ada data.'));
                }

                final Map data = snapshot.data!.snapshot.value as Map;
                final List<Map> items = [];
                data.forEach((key, value) {
                  items.add({"key": key, ...value});
                });

                final processedItems = items.where((item) {
                  final namaBangunan = (item['nama_bangunan'] as String?)?.toLowerCase() ?? '';
                  final kategori = item['kategori'] as String? ?? '';
                  final matchesCategory = _selectedCategory == 'Semua' || kategori == _selectedCategory;
                  final matchesSearch = namaBangunan.contains(_searchQuery.toLowerCase());
                  return matchesCategory && matchesSearch;
                }).toList();

                processedItems.sort((a, b) {
                  final namaA = (a['nama_bangunan'] as String?)?.toLowerCase() ?? '';
                  final namaB = (b['nama_bangunan'] as String?)?.toLowerCase() ?? '';
                  return _sortOrder == SortOrder.asc ? namaA.compareTo(namaB) : namaB.compareTo(namaA);
                });

                if (processedItems.isEmpty) {
                  return const Center(child: Text('Data tidak ditemukan.'));
                }

                return ListView.builder(
                  itemCount: processedItems.length,
                  itemBuilder: (context, index) {
                    final building = processedItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(building['nama_bangunan'] ?? 'Tanpa Nama'),
                        subtitle: Text(building['kategori'] ?? 'Tanpa Kategori'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailScreen(building: building),
                            ),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditScreen(buildingKey: building['key']),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteDialog(building['key']);
                              },
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _showDeleteDialog(String key) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: const Text('Apakah Anda yakin ingin menghapus data ini?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onPressed: () {
              _dbRef.child(key).remove();
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }
}
