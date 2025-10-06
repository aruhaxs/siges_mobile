import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AddEditPopulationScreen extends StatefulWidget {
  final String? populationNik;
  const AddEditPopulationScreen({super.key, this.populationNik});

  @override
  State<AddEditPopulationScreen> createState() => _AddEditPopulationScreenState();
}

class _AddEditPopulationScreenState extends State<AddEditPopulationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _namaController = TextEditingController();
  final _tglLahirController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _pekerjaanController = TextEditingController();
  
  String? _jenisKelamin;
  String? _pendidikan;
  String? _agama;
  
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('populations');
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.populationNik != null) {
      _isEditMode = true;
      _nikController.text = widget.populationNik!;
      _loadPopulationData();
    }
  }

  void _loadPopulationData() async {
    final snapshot = await _dbRef.child(widget.populationNik!).get();
    if (snapshot.exists) {
      final data = snapshot.value as Map;
      _namaController.text = data['nama_lengkap'] ?? '';
      _tglLahirController.text = data['tanggal_lahir'] ?? '';
      _rtController.text = data['rt'] ?? '';
      _rwController.text = data['rw'] ?? '';
      _pekerjaanController.text = data['pekerjaan'] ?? '';
      setState(() {
        _jenisKelamin = data['jenis_kelamin'];
        _pendidikan = data['pendidikan_terakhir'];
        _agama = data['agama'];
      });
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _tglLahirController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  void _submitData() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'nama_lengkap': _namaController.text,
        'tanggal_lahir': _tglLahirController.text,
        'jenis_kelamin': _jenisKelamin,
        'rt': _rtController.text,
        'rw': _rwController.text,
        'pekerjaan': _pekerjaanController.text,
        'pendidikan_terakhir': _pendidikan,
        'agama': _agama,
      };

      _dbRef.child(_nikController.text).set(data).then((_) {
        Navigator.of(context).pop();
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data: $error')),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Data Penduduk' : 'Tambah Data Penduduk'),
        backgroundColor: Colors.teal,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nikController,
              decoration: const InputDecoration(labelText: 'NIK'),
              keyboardType: TextInputType.number,
              readOnly: _isEditMode,
              validator: (value) {
                if (value == null || value.isEmpty) return 'NIK tidak boleh kosong';
                if (value.length != 16) return 'NIK harus 16 digit';
                return null;
              },
            ),
            TextFormField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              validator: (value) => value!.isEmpty ? 'Nama tidak boleh kosong' : null,
            ),
            TextFormField(
              controller: _tglLahirController,
              decoration: const InputDecoration(labelText: 'Tanggal Lahir', hintText: 'DD-MM-YYYY'),
              readOnly: true,
              onTap: _selectDate,
            ),
             DropdownButtonFormField<String>(
              value: _jenisKelamin,
              decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
              items: ['Laki-laki', 'Perempuan'].map((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
              }).toList(),
              onChanged: (newValue) => setState(() => _jenisKelamin = newValue),
            ),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _rtController, decoration: const InputDecoration(labelText: 'RT'))),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _rwController, decoration: const InputDecoration(labelText: 'RW'))),
              ],
            ),
            TextFormField(controller: _pekerjaanController, decoration: const InputDecoration(labelText: 'Pekerjaan')),
            DropdownButtonFormField<String>(
              value: _pendidikan,
              decoration: const InputDecoration(labelText: 'Pendidikan Terakhir'),
              items: ['Tidak Sekolah', 'SD', 'SMP', 'SMA/SMK', 'Diploma', 'S1', 'S2', 'S3'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _pendidikan = val),
            ),
            DropdownButtonFormField<String>(
              value: _agama,
              decoration: const InputDecoration(labelText: 'Agama'),
              items: ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _agama = val),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}