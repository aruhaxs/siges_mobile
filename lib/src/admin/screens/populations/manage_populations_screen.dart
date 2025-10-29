import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:apk_sukorame/src/admin/screens/populations/add_edit_population_screen.dart';

class ManagePopulationsScreen extends StatefulWidget {
  const ManagePopulationsScreen({super.key});

  @override
  State<ManagePopulationsScreen> createState() => _ManagePopulationsScreenState();
}

class _ManagePopulationsScreenState extends State<ManagePopulationsScreen> {
  final CollectionReference _collRef = FirebaseFirestore.instance.collection('populations');
  final _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isSelectionMode = false;
  final Set<String> _selectedKeys = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String key) {
    if (!mounted) return;
    setState(() {
      if (_selectedKeys.contains(key)) {
        _selectedKeys.remove(key);
      } else {
        _selectedKeys.add(key);
      }
      _isSelectionMode = _selectedKeys.isNotEmpty;
    });
  }

  void _exitSelectionMode() {
    if (!mounted) return;
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
                   suffixIcon: _searchQuery.isNotEmpty
                       ? IconButton(
                           icon: const Icon(Icons.clear),
                           onPressed: () => _searchController.clear(),
                         )
                       : null,
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _collRef.orderBy('nama_lengkap').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                   return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Belum ada data penduduk.'));
                }

                final List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
                final List<Map<String, dynamic>> items = docs.map((doc) {
                   final data = doc.data() as Map<String, dynamic>? ?? {};
                   data['nik_key'] = doc.id;
                   return data;
                }).toList();


                final filteredItems = items.where((item) {
                  final nama = (item['nama_lengkap'] as String?)?.toLowerCase() ?? '';
                  final nik = (item['nik_key'] as String?)?.toLowerCase() ?? '';
                  final query = _searchQuery.toLowerCase();
                  return nama.contains(query) || nik.contains(query);
                }).toList();

                if (filteredItems.isEmpty) {
                  return Center(child: Text(_searchQuery.isEmpty ? 'Belum ada data penduduk.' : 'Data tidak ditemukan.'));
                }

                return ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final penduduk = filteredItems[index];
                    final nikKey = penduduk['nik_key'] as String;
                    final isSelected = _selectedKeys.contains(nikKey);

                    String rtDisplay = '-';
                    String rwDisplay = '-';
                    final alamat = penduduk['alamat_terstruktur'];
                    if (alamat is Map) {
                       rtDisplay = alamat['rt']?.toString() ?? '-';
                       rwDisplay = alamat['rw']?.toString() ?? '-';
                    }

                    return Card(
                      color: isSelected ? Colors.blue.shade100 : null,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: InkWell(
                        onTap: () {
                          if (_isSelectionMode) {
                            _toggleSelection(nikKey);
                          } else {
                             Navigator.push(context, MaterialPageRoute(
                               builder: (context) => AddEditPopulationScreen(populationNik: nikKey),
                             ));
                          }
                        },
                        onLongPress: () {
                          if (!_isSelectionMode) {
                             if (mounted) {
                                setState(() {
                                   _isSelectionMode = true;
                                   _toggleSelection(nikKey);
                                });
                             }
                          } else {
                              _toggleSelection(nikKey);
                          }
                        },
                        child: ListTile(
                          leading: _isSelectionMode
                              ? Checkbox(value: isSelected, onChanged: (bool? value) => _toggleSelection(nikKey), activeColor: Colors.teal)
                              : const Icon(Icons.person_outline, color: Colors.teal),
                          title: Text(penduduk['nama_lengkap'] ?? 'Tanpa Nama'),
                          subtitle: Text("NIK: $nikKey\nRT: $rtDisplay RW: $rwDisplay"),
                           isThreeLine: true,
                           trailing: !_isSelectionMode
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      tooltip: 'Edit Data',
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => AddEditPopulationScreen(populationNik: nikKey),
                                      )),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Hapus Data',
                                      onPressed: () => _showSingleDeleteDialog(nikKey),
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
              tooltip: 'Tambah Data Penduduk',
              child: const Icon(Icons.add, color: Colors.white),
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
     if (keysToDelete.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text('Apakah Anda yakin ingin menghapus ${keysToDelete.length} data penduduk ini? Tindakan ini tidak dapat diurungkan.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          TextButton(
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.of(ctx).pop();

              WriteBatch batch = FirebaseFirestore.instance.batch();
              for (var key in keysToDelete) {
                 batch.delete(_collRef.doc(key));
              }

              try {
                  await batch.commit();
                   if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('${keysToDelete.length} data berhasil dihapus'), backgroundColor: Colors.green),
                     );
                     if (_isSelectionMode) {
                       _exitSelectionMode();
                     }
                   }
              } catch (error) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal menghapus data: $error'), backgroundColor: Colors.red),
                    );
                  }
              }
            },
          )
        ],
      ),
    );
  }
}