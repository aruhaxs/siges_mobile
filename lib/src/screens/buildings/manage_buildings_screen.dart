import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:apk_sukorame/src/screens/buildings/add_edit_screen.dart';
import 'package:apk_sukorame/src/screens/buildings/detail_screen.dart';

enum SortOrder { asc, desc }

class ManageBuildingsScreen extends StatefulWidget {
  const ManageBuildingsScreen({super.key});

  @override
  State<ManageBuildingsScreen> createState() => _ManageBuildingsScreenState();
}

class _ManageBuildingsScreenState extends State<ManageBuildingsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('buildings');
  final _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  SortOrder _sortOrder = SortOrder.asc;

  // --- State baru untuk multi-delete ---
  bool _isSelectionMode = false;
  final Set<String> _selectedKeys = {};

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

  // --- Fungsi baru untuk mengelola state seleksi ---
  void _toggleSelection(String key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
      // Keluar dari mode seleksi jika tidak ada item yang dipilih
      if (_selectedKeys.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedKeys.clear();
    });
  }

  // --- AppBar normal dan AppBar untuk mode seleksi ---
  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text('Kelola Data Bangunan'),
      backgroundColor: Colors.teal,
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      title: Text('${_selectedKeys.length} dipilih'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      backgroundColor: Colors.blueGrey,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _showMultiDeleteDialog,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: Column(
        children: [
          // Filter dan Search UI (tidak berubah)
          if (!_isSelectionMode)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Cari Nama Bangunan',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                            return DropdownMenuItem<String>(value: category, child: Text(category));
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() => _selectedCategory = newValue!);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(_sortOrder == SortOrder.asc ? Icons.arrow_downward : Icons.arrow_upward),
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
              ],
            ),
          Expanded(
            child: StreamBuilder(
              stream: _dbRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                // ... (logika StreamBuilder tetap sama sampai return ListView.builder)
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
                    final key = building['key'] as String;
                    final isSelected = _selectedKeys.contains(key);

                    return Card(
                      color: isSelected ? Colors.blue.shade100 : null,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: InkWell(
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(key);
                          } else {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => DetailScreen(building: building),
                            ));
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                            setState(() {
                              _isSelectionMode = true;
                              _toggleSelection(key);
                            });
                          }
                        },
                        child: ListTile(
                          leading: _isSelectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (bool? value) => _toggleSelection(key),
                                )
                              : null,
                          title: Text(building['nama_bangunan'] ?? 'Tanpa Nama'),
                          subtitle: Text(building['kategori'] ?? 'Tanpa Kategori'),
                          trailing: !_isSelectionMode
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => AddEditScreen(buildingKey: key),
                                      )),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _showSingleDeleteDialog(key),
                                    ),
                                  ],
                                )
                              : null,
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
      floatingActionButton: !_isSelectionMode
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (context) => const AddEditScreen(),
              )),
              backgroundColor: Colors.teal,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showSingleDeleteDialog(String key) {
    _showDeleteDialog([key]);
  }

  void _showMultiDeleteDialog() {
    _showDeleteDialog(_selectedKeys.toList());
  }

  void _showDeleteDialog(List<String> keysToDelete) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text('Apakah Anda yakin ingin menghapus ${keysToDelete.length} data ini?'),
        actions: <Widget>[
          TextButton(
            child: const Text('Batal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onPressed: () {
              // Hapus semua data yang dipilih
              final Map<String, dynamic> updates = {};
              for (var key in keysToDelete) {
                updates[key] = null;
              }
              _dbRef.update(updates);

              Navigator.of(ctx).pop();
              if (_isSelectionMode) {
                _exitSelectionMode();
              }
            },
          )
        ],
      ),
    );
  }
}
