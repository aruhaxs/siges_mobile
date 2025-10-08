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

  bool _isSelectionMode = false;
  final Set<String> _selectedKeys = {};

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

  void _toggleSelection(String key) {
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
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

  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text('Kelola Data Kependudukan'),
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
          if (!_isSelectionMode)
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
                // ... (logika StreamBuilder tetap sama sampai return ListView.builder)
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
                    final key = penduduk['key'] as String;
                    final isSelected = _selectedKeys.contains(key);

                    return Card(
                      color: isSelected ? Colors.blue.shade100 : null,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: InkWell(
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(key);
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
                          title: Text(penduduk['nama_lengkap'] ?? 'Tanpa Nama'),
                          subtitle: Text("NIK: $key"),
                          trailing: !_isSelectionMode
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => AddEditPopulationScreen(populationNik: key),
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
                builder: (context) => const AddEditPopulationScreen(),
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
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          TextButton(
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onPressed: () {
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
