import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import '../../google_drive_service.dart';

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
  List<String> _nameSuggestions = [];
  List<String> _alamatSuggestions = [];

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
    'UMKM',
    'Kantor Pemerintahan',
    'Lainnya',
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
        final addrs = <String>{};
        data.forEach((key, value) {
          try {
            final row = value as Map;
            final n = row['nama_bangunan'];
            final a = row['alamat'];
            if (n is String && n.isNotEmpty) names.add(n);
            if (a is String && a.isNotEmpty) addrs.add(a);
          } catch (_) {}
        });
        setState(() {
          _nameSuggestions = names.toList();
          _alamatSuggestions = addrs.toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _koordinatController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  void _loadBuildingData() async {
    DataSnapshot snapshot = await _dbRef.child(widget.buildingKey!).get();
    if (snapshot.exists && mounted) {
      Map data = snapshot.value as Map;
      _namaController.text = data['nama_bangunan'] ?? '';
      _alamatController.text = data['alamat'] ?? '';
      _deskripsiController.text = data['deskripsi'] ?? '';
      _koordinatController.text = "${data['latitude']}, ${data['longitude']}";
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
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _driveImageBytes = null;
      });
    }
  }

  void _removeImage() async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Gambar?'),
          content: const Text('Apakah Anda yakin ingin menghapus gambar ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus gambar: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    String? oldImageId = _driveImageId;
    String? newImageId = _driveImageId;

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
        'alamat': _alamatController.text,
        'kategori': _selectedKategori,
        'deskripsi': _deskripsiController.text,
        'latitude': lat,
        'longitude': lng,
        'driveImageId': newImageId,
      };

      if (widget.buildingKey == null) {
        await _dbRef.push().set(data);
      } else {
        await _dbRef.child(widget.buildingKey!).update(data);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.buildingKey == null
              ? 'Tambah Data Bangunan'
              : 'Edit Data Bangunan',
        ),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _imageFile != null
                                ? Image.file(_imageFile!, fit: BoxFit.cover)
                                : (_driveImageId != null
                                      ? (_isLoadingImage
                                            ? const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                            : (_driveImageBytes != null
                                                  ? Image.memory(
                                                      _driveImageBytes!,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : const Center(
                                                      child: Icon(
                                                        Icons.error_outline,
                                                        color: Colors.red,
                                                        size: 50,
                                                      ),
                                                    )))
                                      : Center(
                                          child: Icon(
                                            Icons.camera_alt,
                                            size: 60,
                                            color: Colors.grey[700],
                                          ),
                                        )),
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
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty)
                        return const Iterable<String>.empty();
                      return _nameSuggestions.where(
                        (opt) => opt.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        ),
                      );
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          controller.text = _namaController.text;
                          controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Nama Bangunan',
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'Nama tidak boleh kosong'
                                : null,
                            onChanged: (v) => _namaController.text = v,
                          );
                        },
                    onSelected: (selection) {
                      setState(() => _namaController.text = selection);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedKategori,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: _kategoriOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) =>
                        setState(() => _selectedKategori = newValue),
                    validator: (value) =>
                        value == null ? 'Kategori harus dipilih' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deskripsiController,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty)
                        return const Iterable<String>.empty();
                      return _alamatSuggestions.where(
                        (opt) => opt.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        ),
                      );
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          controller.text = _alamatController.text;
                          controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: controller.text.length),
                          );
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Alamat',
                            ),
                            validator: (value) => value!.isEmpty
                                ? 'Alamat tidak boleh kosong'
                                : null,
                            onChanged: (v) => _alamatController.text = v,
                          );
                        },
                    onSelected: (selection) {
                      setState(() => _alamatController.text = selection);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _koordinatController,
                    decoration: const InputDecoration(
                      labelText: 'Koordinat',
                      hintText: 'Contoh: -7.803, 111.996',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Koordinat tidak boleh kosong';
                      }
                      final parts = value.split(',');
                      if (parts.length != 2) {
                        return 'Format salah (harus: lat, lng)';
                      }
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
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: const Color.fromRGBO(0, 0, 0, 0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Memproses...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
