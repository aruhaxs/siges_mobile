import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import '../../../google_drive_service.dart';

class AddEditScreen extends StatefulWidget {
  final String? buildingKey;

  const AddEditScreen({super.key, this.buildingKey});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _koordinatController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _jamBukaController = TextEditingController();
  final _jamTutupController = TextEditingController();
  final _jalanController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _kelurahanController = TextEditingController();
  final _kecamatanController = TextEditingController();
  final _kabupatenController = TextEditingController();
  final _provinsiController = TextEditingController();
  final _kodeposController = TextEditingController();

  String? _selectedKategori;

  List<String> _nameSuggestions = [];
  List<String> _jalanSuggestions = [];
  List<String> _rtSuggestions = [];
  List<String> _rwSuggestions = [];
  List<String> _kelurahanSuggestions = [];
  List<String> _kecamatanSuggestions = [];
  List<String> _kabupatenSuggestions = [];
  List<String> _provinsiSuggestions = [];
  List<String> _kodeposSuggestions = [];

  final GoogleDriveService _driveService = GoogleDriveService();
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _driveImageId;
  bool _isUploading = false;

  bool _isLoadingImage = false;
  Uint8List? _driveImageBytes;

  final List<String> _kategoriOptions = [
    'Pendidikan',
    'Kesehatan',
    'Tempat Ibadah',
    'Kantor Pemerintahan',
    'UMKM',
    'Penginapan',
    'Lainnya'
  ];
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('buildings');

  @override
  void initState() {
    super.initState();
    if (widget.buildingKey != null) {
      _loadBuildingData();
    }
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final snapshot = await _dbRef.get();
      if (snapshot.exists && mounted) {
        final data = snapshot.value as Map;

        final names = <String>{};
        final jalans = <String>{};
        final rts = <String>{};
        final rws = <String>{};
        final kelurahans = <String>{};
        final kecamatans = <String>{};
        final kabupatens = <String>{};
        final provinsis = <String>{};
        final kodeposlist = <String>{};

        data.forEach((key, value) {
          try {
            final row = value as Map;
            final n = row['nama_bangunan'];
            if (n is String && n.isNotEmpty) names.add(n);

            final alamat = row['alamat_terstruktur'];
            if (alamat != null && alamat is Map) {
              if (alamat['jalan'] is String && alamat['jalan'].isNotEmpty) {
                jalans.add(alamat['jalan']);
              }
              if (alamat['rt'] is String && alamat['rt'].isNotEmpty) {
                rts.add(alamat['rt']);
              }
              if (alamat['rw'] is String && alamat['rw'].isNotEmpty) {
                rws.add(alamat['rw']);
              }
              if (alamat['kelurahan'] is String &&
                  alamat['kelurahan'].isNotEmpty) {
                kelurahans.add(alamat['kelurahan']);
              }
              if (alamat['kecamatan'] is String &&
                  alamat['kecamatan'].isNotEmpty) {
                kecamatans.add(alamat['kecamatan']);
              }
              if (alamat['kabupaten'] is String &&
                  alamat['kabupaten'].isNotEmpty) {
                kabupatens.add(alamat['kabupaten']);
              }
              if (alamat['provinsi'] is String &&
                  alamat['provinsi'].isNotEmpty) {
                provinsis.add(alamat['provinsi']);
              }
              if (alamat['kodepos'] is String &&
                  alamat['kodepos'].isNotEmpty) {
                kodeposlist.add(alamat['kodepos']);
              }
            }
          } catch (_) {}
        });

        setState(() {
          _nameSuggestions = names.toList();
          _jalanSuggestions = jalans.toList();
          _rtSuggestions = rts.toList();
          _rwSuggestions = rws.toList();
          _kelurahanSuggestions = kelurahans.toList();
          _kecamatanSuggestions = kecamatans.toList();
          _kabupatenSuggestions = kabupatens.toList();
          _provinsiSuggestions = provinsis.toList();
          _kodeposSuggestions = kodeposlist.toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _namaController.dispose();
    _koordinatController.dispose();
    _deskripsiController.dispose();
    _jamBukaController.dispose();
    _jamTutupController.dispose();
    _jalanController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _kelurahanController.dispose();
    _kecamatanController.dispose();
    _kabupatenController.dispose();
    _provinsiController.dispose();
    _kodeposController.dispose();

    super.dispose();
  }

  void _loadBuildingData() async {
    DataSnapshot snapshot = await _dbRef.child(widget.buildingKey!).get();
    if (snapshot.exists && mounted) {
      Map data = snapshot.value as Map;
      _namaController.text = data['nama_bangunan'] ?? '';
      _deskripsiController.text = data['deskripsi'] ?? '';
      _koordinatController.text = "${data['latitude']}, ${data['longitude']}";
      _jamBukaController.text = data['jam_buka'] ?? '';
      _jamTutupController.text = data['jam_tutup'] ?? '';

      final alamat = data['alamat_terstruktur'];
      if (alamat != null && alamat is Map) {
        _jalanController.text = alamat['jalan'] ?? '';
        _rtController.text = alamat['rt'] ?? '';
        _rwController.text = alamat['rw'] ?? '';
        _kelurahanController.text = alamat['kelurahan'] ?? '';
        _kecamatanController.text = alamat['kecamatan'] ?? '';
        _kabupatenController.text = alamat['kabupaten'] ?? '';
        _provinsiController.text = alamat['provinsi'] ?? '';
        _kodeposController.text = alamat['kodepos'] ?? '';
      }

      setState(() {
        _selectedKategori = data['kategori'];
        _driveImageId = data['driveImageId'];
      });

      if (_driveImageId != null) {
        setState(() => _isLoadingImage = true);
        final bytes = await _driveService.downloadFile(_driveImageId!);
        if (mounted) {
          setState(() {
            _driveImageBytes = bytes;
            _isLoadingImage = false;
          });
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _driveImageBytes = null;
      });
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (pickedTime != null) {
      setState(() {
        final localizations = MaterialLocalizations.of(context);
        final formattedTime =
            localizations.formatTimeOfDay(pickedTime, alwaysUse24HourFormat: true);
        controller.text = formattedTime;
      });
    }
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isUploading = true;
    });
    String? oldImageId = _driveImageId;
    String? newImageId = _driveImageId;

    final List<String> addressParts = [
      _jalanController.text,
      if (_rtController.text.isNotEmpty) 'RT ' + _rtController.text,
      if (_rwController.text.isNotEmpty) 'RW ' + _rwController.text,
      _kelurahanController.text,
      _kecamatanController.text,
      _kabupatenController.text,
      _provinsiController.text,
      if (_kodeposController.text.isNotEmpty) _kodeposController.text,
    ];
    final String combinedAlamat =
        addressParts.where((s) => s.isNotEmpty).join(', ');

    final Map<String, String> alamatTerstruktur = {
      'jalan': _jalanController.text,
      'rt': _rtController.text,
      'rw': _rwController.text,
      'kelurahan': _kelurahanController.text,
      'kecamatan': _kecamatanController.text,
      'kabupaten': _kabupatenController.text,
      'provinsi': _provinsiController.text,
      'kodepos': _kodeposController.text,
    };

    try {
      if (_imageFile != null) {
        newImageId = await _driveService.uploadFile(_imageFile!);
        if (newImageId == null) {
          throw Exception('Gagal mengunggah gambar ke Drive.');
        }
        if (oldImageId != null && oldImageId != newImageId) {
          await _driveService.deleteFile(oldImageId);
        }
      }
      final parts = _koordinatController.text.split(',');
      final lat = double.tryParse(parts[0].trim()) ?? 0.0;
      final lng = double.tryParse(parts[1].trim()) ?? 0.0;

      final data = {
        'nama_bangunan': _namaController.text,
        'alamat': combinedAlamat,
        'alamat_terstruktur': alamatTerstruktur,
        'kategori': _selectedKategori,
        'deskripsi': _deskripsiController.text,
        'latitude': lat,
        'longitude': lng,
        'driveImageId': newImageId,
        'jam_buka': _jamBukaController.text,
        'jam_tutup': _jamTutupController.text,
      };

      if (widget.buildingKey == null) {
        await _dbRef.push().set(data);
      } else {
        await _dbRef.child(widget.buildingKey!).update(data);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _removeImage() async {
    final bool? shouldDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: const Text('Hapus Gambar?'),
              content:
                  const Text('Apakah Anda yakin ingin menghapus gambar ini?'),
              actions: <Widget>[
                TextButton(
                    child: const Text('Batal'),
                    onPressed: () => Navigator.of(context).pop(false)),
                TextButton(
                    child: const Text('Hapus',
                        style: TextStyle(color: Colors.red)),
                    onPressed: () => Navigator.of(context).pop(true))
              ]);
        });
    if (shouldDelete != true) return;
    if (_imageFile != null) {
      setState(() => _imageFile = null);
      return;
    }
    if (widget.buildingKey != null && _driveImageId != null) {
      setState(() => _isUploading = true);
      try {
        await _driveService.deleteFile(_driveImageId!);
        await _dbRef.child(widget.buildingKey!).child('driveImageId').remove();
        if (mounted) {
          setState(() {
            _driveImageId = null;
            _driveImageBytes = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Gagal menghapus gambar: $e')));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildAddressAutocomplete({
    required TextEditingController controller,
    required String labelText,
    required List<String> suggestions,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return suggestions.where((String option) {
          return option
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        textEditingController.text = controller.text;
        textEditingController.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length));

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: labelText),
          keyboardType: keyboardType,
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$labelText tidak boleh kosong';
            }
            return null;
          },
          onChanged: (value) {
            controller.text = value;
          },
        );
      },
      onSelected: (String selection) {
        setState(() {
          controller.text = selection;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.buildingKey == null
            ? 'Tambah Data Bangunan'
            : 'Edit Data Bangunan'),
        backgroundColor: Colors.teal,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: (_imageFile != null || _driveImageId != null)
                      ? null
                      : _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _imageFile != null
                          ? Image.file(_imageFile!, fit: BoxFit.cover)
                          : (_driveImageId != null
                              ? (_isLoadingImage
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : (_driveImageBytes != null
                                      ? Image.memory(_driveImageBytes!,
                                          fit: BoxFit.cover)
                                      : const Center(
                                          child: Icon(Icons.error_outline,
                                              color: Colors.red, size: 50))))
                              : Center(
                                  child: Icon(Icons.camera_alt,
                                      size: 60, color: Colors.grey[700]))),
                    ),
                  ),
                ),
                if ((_imageFile != null || _driveImageId != null) &&
                    !_isLoadingImage)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _removeImage,
                        child: const Padding(
                          padding: EdgeInsets.all(6.0),
                          child:
                              Icon(Icons.delete, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return _nameSuggestions.where((opt) =>
                    opt.toLowerCase().contains(textEditingValue.text.toLowerCase()));
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                controller.text = _namaController.text;
                controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length));
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(labelText: 'Nama Bangunan'),
                  validator: (value) =>
                      value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                  onChanged: (v) => _namaController.text = v,
                );
              },
              onSelected: (selection) {
                setState(() => _namaController.text = selection);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedKategori,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: _kategoriOptions
                  .map((String value) =>
                      DropdownMenuItem<String>(value: value, child: Text(value)))
                  .toList(),
              onChanged: (newValue) => setState(() => _selectedKategori = newValue),
              validator: (value) => value == null ? 'Kategori harus dipilih' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
                maxLines: 3),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _jamBukaController,
                    decoration: const InputDecoration(
                        labelText: 'Jam Buka',
                        suffixIcon: Icon(Icons.access_time)),
                    readOnly: true,
                    onTap: () => _selectTime(_jamBukaController),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _jamTutupController,
                    decoration: const InputDecoration(
                        labelText: 'Jam Tutup',
                        suffixIcon: Icon(Icons.access_time)),
                    readOnly: true,
                    onTap: () => _selectTime(_jamTutupController),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAddressAutocomplete(
              controller: _jalanController,
              labelText: 'Jalan',
              suggestions: _jalanSuggestions,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAddressAutocomplete(
                    controller: _rtController,
                    labelText: 'RT',
                    suggestions: _rtSuggestions,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAddressAutocomplete(
                    controller: _rwController,
                    labelText: 'RW',
                    suggestions: _rwSuggestions,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAddressAutocomplete(
              controller: _kelurahanController,
              labelText: 'Kelurahan/Desa',
              suggestions: _kelurahanSuggestions,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildAddressAutocomplete(
              controller: _kecamatanController,
              labelText: 'Kecamatan',
              suggestions: _kecamatanSuggestions,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildAddressAutocomplete(
              controller: _kabupatenController,
              labelText: 'Kabupaten/Kota',
              suggestions: _kabupatenSuggestions,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildAddressAutocomplete(
              controller: _provinsiController,
              labelText: 'Provinsi',
              suggestions: _provinsiSuggestions,
              isRequired: true,
            ),
            const SizedBox(height: 16),
            _buildAddressAutocomplete(
              controller: _kodeposController,
              labelText: 'Kode Pos',
              suggestions: _kodeposSuggestions,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _koordinatController,
              decoration: const InputDecoration(
                  labelText: 'Koordinat', hintText: 'Contoh: -7.803, 111.996'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true, signed: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Koordinat tidak boleh kosong';
                }
                final parts = value.split(',');
                if (parts.length != 2) return 'Format salah (harus: lat, lng)';
                if (double.tryParse(parts[0].trim()) == null) {
                  return 'Latitude tidak valid';
                }
                if (double.tryParse(parts[1].trim()) == null) {
                  return 'Longitude tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isUploading ? null : _submitData,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16.0)),
              child: const Text('Simpan'),
            ),
            if (_isUploading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }
}