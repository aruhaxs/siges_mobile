import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddEditScreen extends StatefulWidget {
  final String? buildingKey;

  const AddEditScreen({super.key, this.buildingKey});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _koordinatController = TextEditingController();
  final _deskripsiController = TextEditingController();
  String? _selectedKategori;

  final List<String> _kategoriOptions = [
    'Pendidikan', 'Kesehatan', 'Tempat Ibadah', 'UMKM', 'Kantor Pemerintahan', 'Lainnya'
  ];
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('buildings');

  @override
  void initState() {
    super.initState();
    if (widget.buildingKey != null) {
      _loadBuildingData();
    }
  }

  void _loadBuildingData() async {
    DataSnapshot snapshot = await _dbRef.child(widget.buildingKey!).get();
    if (snapshot.exists) {
      Map data = snapshot.value as Map;
      _namaController.text = data['nama_bangunan'] ?? '';
      _alamatController.text = data['alamat'] ?? '';
      _deskripsiController.text = data['deskripsi'] ?? '';
      _koordinatController.text = "${data['latitude']}, ${data['longitude']}";
      setState(() {
        _selectedKategori = data['kategori'];
      });
    }
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      final parts = _koordinatController.text.split(',');
      final lat = double.tryParse(parts[0].trim()) ?? 0.0;
      final lng = double.tryParse(parts[1].trim()) ?? 0.0;

      final data = {
        'nama_bangunan': _namaController.text,
        'alamat': _alamatController.text,
        'kategori': _selectedKategori,
        'deskripsi': _deskripsiController.text,
        'latitude': lat,
        'longitude': lng,
      };

      if (widget.buildingKey == null) {
        _dbRef.push().set(data);
      } else {
        _dbRef.child(widget.buildingKey!).update(data);
      }
      Navigator.of(context).pop();
    }
  }
  
  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _koordinatController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.buildingKey == null ? 'Tambah Data Bangunan' : 'Edit Data Bangunan'),
        backgroundColor: Colors.teal,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama Bangunan'),
                validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedKategori,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: _kategoriOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedKategori = newValue),
                validator: (value) => value == null ? 'Kategori harus dipilih' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(labelText: 'Alamat'),
                validator: (value) => value!.isEmpty ? 'Alamat tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _koordinatController,
                decoration: const InputDecoration(
                  labelText: 'Koordinat',
                  hintText: 'Contoh: -7.803, 111.996',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Koordinat tidak boleh kosong';
                  final parts = value.split(',');
                  if (parts.length != 2) return 'Format salah (harus: lat, lng)';
                  if (double.tryParse(parts[0].trim()) == null) return 'Latitude tidak valid';
                  if (double.tryParse(parts[1].trim()) == null) return 'Longitude tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitData,
                child: const Text('Simpan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
