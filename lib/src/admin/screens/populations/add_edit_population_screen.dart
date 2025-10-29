import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEditPopulationScreen extends StatefulWidget {
  final String? populationNik;
  const AddEditPopulationScreen({super.key, this.populationNik});

  @override
  State<AddEditPopulationScreen> createState() =>
      _AddEditPopulationScreenState();
}

class _AddEditPopulationScreenState extends State<AddEditPopulationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nikController = TextEditingController();
  final _namaController = TextEditingController();
  final _tglLahirController = TextEditingController();
  final _pekerjaanController = TextEditingController();
  final _jalanController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _kelurahanController = TextEditingController();
  final _kecamatanController = TextEditingController();
  final _kabupatenController = TextEditingController();
  final _provinsiController = TextEditingController();
  final _kodeposController = TextEditingController();
  final _kkController = TextEditingController();
  final _emailController = TextEditingController();
  final _kewarganegaraanController = TextEditingController();
  final _noHpController = TextEditingController();
  final _tempatLahirController = TextEditingController();

  String? _jenisKelamin;
  String? _pendidikan;
  String? _agama;
  String? _statusPerkawinan;

  List<String> _namaSuggestions = [];
  List<String> _pekerjaanSuggestions = [];
  List<String> _jalanSuggestions = [];
  List<String> _rtSuggestions = [];
  List<String> _rwSuggestions = [];
  List<String> _kelurahanSuggestions = [];
  List<String> _kecamatanSuggestions = [];
  List<String> _kabupatenSuggestions = [];
  List<String> _provinsiSuggestions = [];
  List<String> _kodeposSuggestions = [];
  List<String> _kewarganegaraanSuggestions = [];
  List<String> _tempatLahirSuggestions = [];

  final ImagePicker _picker = ImagePicker();
  File? _fotoKtpFile;
  File? _fotoKkFile;
  String? _fotoKtpUrl;
  String? _fotoKkUrl;
  bool _isUploadingKtp = false;
  bool _isUploadingKk = false;
  bool _isSavingData = false;

  final CollectionReference _collRef = FirebaseFirestore.instance.collection('populations');
  bool _isEditMode = false;

  final String _supabaseBucket = 'Storage';

  @override
  void initState() {
    super.initState();
    if (widget.populationNik != null) {
      // Ini adalah mode EDIT, jadi kita memuat data yang ada
      _isEditMode = true;
      _nikController.text = widget.populationNik!;
      _loadPopulationData();
    } else {
      // Ini adalah mode TAMBAH, atur nilai default di sini
      _kelurahanController.text = "Sukorame";
      _kecamatanController.text = "Mojoroto";
      _kabupatenController.text = "Kota Kediri";
      _provinsiController.text = "Jawa Timur";
      _kodeposController.text = "64119";
    }
    _loadSuggestionLists();
  }

  Future<void> _loadSuggestionLists() async {
    try {
      final snapshot = await _collRef.limit(500).get();

      final Set<String> names = {};
      final Set<String> jobs = {};
      final Set<String> jalans = {};
      final Set<String> rts = {};
      final Set<String> rws = {};
      final Set<String> kelurahans = {};
      final Set<String> kecamatans = {};
      final Set<String> kabupatens = {};
      final Set<String> provinsis = {};
      final Set<String> kodeposlist = {};
      final Set<String> kewarganegaraans = {};
      final Set<String> tempatLahirs = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          try {
            final nama = data['nama_lengkap']?.toString();
            final pekerjaan = data['pekerjaan']?.toString();
            final kewarganegaraan = data['kewarganegaraan']?.toString();
            final tempatLahir = data['tempat_lahir']?.toString();

            if (nama != null && nama.isNotEmpty) names.add(nama);
            if (pekerjaan != null && pekerjaan.isNotEmpty) jobs.add(pekerjaan);
            if (kewarganegaraan != null && kewarganegaraan.isNotEmpty) kewarganegaraans.add(kewarganegaraan);
            if (tempatLahir != null && tempatLahir.isNotEmpty) tempatLahirs.add(tempatLahir);

            final alamat = data['alamat_terstruktur'];
            if (alamat != null && alamat is Map) {
              final Map<String, dynamic> alamatMap = Map<String, dynamic>.from(alamat);
              if (alamatMap['jalan'] is String && alamatMap['jalan']!.isNotEmpty) jalans.add(alamatMap['jalan']!);
              if (alamatMap['rt'] is String && alamatMap['rt']!.isNotEmpty) rts.add(alamatMap['rt']!);
              if (alamatMap['rw'] is String && alamatMap['rw']!.isNotEmpty) rws.add(alamatMap['rw']!);
              if (alamatMap['kelurahan'] is String && alamatMap['kelurahan']!.isNotEmpty) kelurahans.add(alamatMap['kelurahan']!);
              if (alamatMap['kecamatan'] is String && alamatMap['kecamatan']!.isNotEmpty) kecamatans.add(alamatMap['kecamatan']!);
              if (alamatMap['kabupaten'] is String && alamatMap['kabupaten']!.isNotEmpty) kabupatens.add(alamatMap['kabupaten']!);
              if (alamatMap['provinsi'] is String && alamatMap['provinsi']!.isNotEmpty) provinsis.add(alamatMap['provinsi']!);
              if (alamatMap['kodepos'] is String && alamatMap['kodepos']!.isNotEmpty) kodeposlist.add(alamatMap['kodepos']!);
            }
          } catch (e) {
            debugPrint("Error processing suggestion doc ${doc.id}: $e");
          }
        }
      }

      if (mounted) {
        setState(() {
          _namaSuggestions = names.toList()..sort();
          _pekerjaanSuggestions = jobs.toList()..sort();
          _jalanSuggestions = jalans.toList()..sort();
          _rtSuggestions = rts.toList()..sort();
          _rwSuggestions = rws.toList()..sort();
          _kelurahanSuggestions = kelurahans.toList()..sort();
          _kecamatanSuggestions = kecamatans.toList()..sort();
          _kabupatenSuggestions = kabupatens.toList()..sort();
          _provinsiSuggestions = provinsis.toList()..sort();
          _kodeposSuggestions = kodeposlist.toList()..sort();
          _kewarganegaraanSuggestions = kewarganegaraans.toList()..sort();
          _tempatLahirSuggestions = tempatLahirs.toList()..sort();
        });
      }
    } catch (e) {
      debugPrint("Error loading suggestions from Firestore: $e");
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat sugesti: $e'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  void _loadPopulationData() async {
    if (widget.populationNik == null) return;
    try {
      final snapshot = await _collRef.doc(widget.populationNik!).get();

      if (snapshot.exists && mounted) {
        final data = snapshot.data() as Map<String, dynamic>?;

        if (data != null) {
          _namaController.text = data['nama_lengkap']?.toString() ?? '';
          _tglLahirController.text = data['tanggal_lahir']?.toString() ?? '';
          _pekerjaanController.text = data['pekerjaan']?.toString() ?? '';
          _kkController.text = data['kk']?.toString() ?? '';
          _emailController.text = data['email']?.toString() ?? '';
          _kewarganegaraanController.text = data['kewarganegaraan']?.toString() ?? '';
          _noHpController.text = data['no_hp']?.toString() ?? '';
          _tempatLahirController.text = data['tempat_lahir']?.toString() ?? '';

          final alamat = data['alamat_terstruktur'];
          if (alamat != null && alamat is Map) {
            final Map<String, dynamic> alamatMap = Map<String, dynamic>.from(alamat);
            _jalanController.text = alamatMap['jalan']?.toString() ?? '';
            _rtController.text = alamatMap['rt']?.toString() ?? '';
            _rwController.text = alamatMap['rw']?.toString() ?? '';
            _kelurahanController.text = alamatMap['kelurahan']?.toString() ?? '';
            _kecamatanController.text = alamatMap['kecamatan']?.toString() ?? '';
            _kabupatenController.text = alamatMap['kabupaten']?.toString() ?? '';
            _provinsiController.text = alamatMap['provinsi']?.toString() ?? '';
            _kodeposController.text = alamatMap['kodepos']?.toString() ?? '';
          }

          setState(() {
            _jenisKelamin = data['jenis_kelamin']?.toString();
            _pendidikan = data['pendidikan_terakhir']?.toString();
            _agama = data['agama']?.toString();
            _statusPerkawinan = data['status_perkawinan']?.toString();
            _fotoKtpUrl = data['foto_ktp_url']?.toString();
            _fotoKkUrl = data['foto_kk_url']?.toString();
          });
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Data NIK ${widget.populationNik} tidak ditemukan.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memuat data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _tglLahirController.dispose();
    _pekerjaanController.dispose();
    _jalanController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _kelurahanController.dispose();
    _kecamatanController.dispose();
    _kabupatenController.dispose();
    _provinsiController.dispose();
    _kodeposController.dispose();
    _kkController.dispose();
    _emailController.dispose();
    _kewarganegaraanController.dispose();
    _noHpController.dispose();
    _tempatLahirController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    DateTime initial = DateTime.now();
    try {
      if (_tglLahirController.text.isNotEmpty) {
        initial = DateFormat('dd-MM-yyyy').parse(_tglLahirController.text);
      }
    } catch (_) {
      initial = DateTime.now();
    }

    DateTime? picked = await showDatePicker(
      context: context, initialDate: initial, firstDate: DateTime(1900), lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _tglLahirController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  Future<void> _pickFotoKtp() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null && mounted) {
      setState(() {
        _fotoKtpFile = File(pickedFile.path);
        _fotoKtpUrl = null;
      });
    }
  }

  Future<void> _pickFotoKk() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null && mounted) {
      setState(() {
        _fotoKkFile = File(pickedFile.path);
        _fotoKkUrl = null;
      });
    }
  }

  Future<String?> _uploadFoto(File file, String folderPath, String nik) async {
    try {
      final fileExtension = file.path.split('.').last.toLowerCase();
      final cleanNik = nik.replaceAll(RegExp(r'[^0-9]'), '');
      final fileName = '${cleanNik}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final supabasePath = '$folderPath/$fileName'.replaceAll(r'\', '/');

      await Supabase.instance.client.storage
          .from(_supabaseBucket)
          .upload(supabasePath, file, fileOptions: const FileOptions(cacheControl: '3600', upsert: false));

      final imageUrlResponse = Supabase.instance.client.storage
          .from(_supabaseBucket)
          .getPublicUrl(supabasePath);

      return imageUrlResponse;

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal unggah ($folderPath): ${e is StorageException ? e.message : e.toString()}'), backgroundColor: Colors.red),
        );
      }
      debugPrint('Supabase Upload Error ($folderPath): $e');
      return null;
    }
  }

  Future<void> _deleteOldFoto(String? fileUrl) async {
    if (fileUrl == null || fileUrl.isEmpty) return;
    try {
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;
      final bucketNameIndex = pathSegments.indexOf(_supabaseBucket);
      final filePathStartIndex = bucketNameIndex + 1;

      if (filePathStartIndex < pathSegments.length) {
        final filePath = pathSegments.sublist(filePathStartIndex).join('/');
        if (filePath.isNotEmpty) {
          await Supabase.instance.client.storage
              .from(_supabaseBucket)
              .remove([filePath]);
          debugPrint("Successfully deleted old photo: $filePath");
        } else {
          debugPrint("Could not extract valid file path from URL segments: $pathSegments");
        }
      } else {
        debugPrint("Could not find bucket name '$_supabaseBucket' or path in URL: $fileUrl");
      }
    } catch (e) {
      debugPrint("Gagal menghapus foto lama ($fileUrl): $e");
    }
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_jenisKelamin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jenis Kelamin harus dipilih'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSavingData = true);

    String? uploadedKtpUrl = _fotoKtpUrl;
    String? uploadedKkUrl = _fotoKkUrl;
    bool uploadSuccess = true;

    if (_fotoKtpFile != null) {
      setState(() => _isUploadingKtp = true);
      String? oldKtpUrl = _fotoKtpUrl;
      uploadedKtpUrl = await _uploadFoto(_fotoKtpFile!, 'ktp_images', _nikController.text);
      if (!mounted) return;
      setState(() => _isUploadingKtp = false);
      if (uploadedKtpUrl == null) uploadSuccess = false;
      else if (_isEditMode && oldKtpUrl != null && oldKtpUrl.isNotEmpty && oldKtpUrl != uploadedKtpUrl) await _deleteOldFoto(oldKtpUrl);
    }

    if (uploadSuccess && _fotoKkFile != null) {
      setState(() => _isUploadingKk = true);
      String? oldKkUrl = _fotoKkUrl;
      uploadedKkUrl = await _uploadFoto(_fotoKkFile!, 'kk_images', _nikController.text);
      if (!mounted) return;
      setState(() => _isUploadingKk = false);
      if (uploadedKkUrl == null) uploadSuccess = false;
      else if (_isEditMode && oldKkUrl != null && oldKkUrl.isNotEmpty && oldKkUrl != uploadedKkUrl) await _deleteOldFoto(oldKkUrl);
    }

    if (!uploadSuccess) {
      if (mounted) setState(() => _isSavingData = false);
      return;
    }

    final List<String> addressParts = [
      _jalanController.text,
      if (_rtController.text.isNotEmpty) 'RT ${_rtController.text}',
      if (_rwController.text.isNotEmpty) 'RW ${_rwController.text}',
      _kelurahanController.text, _kecamatanController.text, _kabupatenController.text,
      _provinsiController.text, if (_kodeposController.text.isNotEmpty) _kodeposController.text,
    ];
    final String combinedAlamat = addressParts.where((s) => s.isNotEmpty).join(', ');

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

    final Map<String, dynamic> data = {
      'nama_lengkap': _namaController.text,
      'tanggal_lahir': _tglLahirController.text,
      'jenis_kelamin': _jenisKelamin,
      'alamat': combinedAlamat,
      'alamat_terstruktur': alamatTerstruktur,
      'pekerjaan': _pekerjaanController.text,
      'pendidikan_terakhir': _pendidikan,
      'agama': _agama,
      'kk': _kkController.text,
      'email': _emailController.text,
      'kewarganegaraan': _kewarganegaraanController.text,
      'no_hp': _noHpController.text,
      'status_perkawinan': _statusPerkawinan,
      'tempat_lahir': _tempatLahirController.text,
      'foto_ktp_url': uploadedKtpUrl,
      'foto_kk_url': uploadedKkUrl,
    };

    try {
      await _collRef.doc(_nikController.text).set(data, SetOptions(merge: _isEditMode));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data berhasil disimpan'), backgroundColor: Colors.green),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan ke Firestore: $error'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingData = false;
        });
      }
    }
  }

  Widget _buildAutocomplete({
    required TextEditingController controller,
    required String labelText,
    required List<String> suggestions,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') return const Iterable<String>.empty();
        return suggestions.where(
          (opt) =>
              opt.toLowerCase().contains(textEditingValue.text.toLowerCase()),
        );
      },
      fieldViewBuilder:
          (context, fieldController, focusNode, onFieldSubmitted) {
        fieldController.text = controller.text;
        fieldController.selection = TextSelection.fromPosition(
          TextPosition(offset: controller.text.length),
        );
        return TextFormField(
          controller: fieldController,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: labelText),
          keyboardType: keyboardType,
          validator: (value) =>
              (isRequired && (value == null || value.isEmpty))
                  ? '$labelText tidak boleh kosong'
                  : null,
          onChanged: (v) => controller.text = v,
        );
      },
      onSelected: (selection) {
        setState(() {
          controller.text = selection;
        });
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: 200,
                  maxWidth: MediaQuery.of(context).size.width - 40),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                        padding: const EdgeInsets.all(16.0), child: Text(option)),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoUpload(
      {required String label,
      required File? file,
      required String? existingUrl,
      required bool isUploading,
      required VoidCallback onPick,
      required VoidCallback onRemove}) {
    Widget displayWidget;
    if (file != null) {
      displayWidget = Image.file(file,
          height: 100, width: double.infinity, fit: BoxFit.cover);
    } else if (existingUrl != null && existingUrl.isNotEmpty) {
      displayWidget = Image.network(existingUrl,
          height: 100,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) =>
              loadingProgress == null
                  ? child
                  : const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator())),
          errorBuilder: (context, error, stackTrace) => Container(
              height: 100,
              width: double.infinity,
              color: Colors.grey[200],
              child: Center(
                  child: Icon(Icons.broken_image, color: Colors.grey[700]))));
    } else {
      displayWidget = Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade400)),
          child:
              Center(child: Icon(Icons.camera_alt, color: Colors.grey[700], size: 40)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            InkWell(
                onTap: isUploading ? null : onPick,
                child:
                    ClipRRect(borderRadius: BorderRadius.circular(8.0), child: displayWidget)),
            if (isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8.0)),
                  child: const Center(
                      child: CircularProgressIndicator(color: Colors.white)),
                ),
              ),
            if (!isUploading &&
                (file != null || (existingUrl != null && existingUrl.isNotEmpty)))
              Positioned(
                  top: 4, right: 4,
                  child: Material(color: Colors.black54, shape: const CircleBorder(),
                    child: InkWell(customBorder: const CircleBorder(), onTap: onRemove,
                        child: const Padding(padding: EdgeInsets.all(4.0), child: Icon(Icons.close, color: Colors.white, size: 16)))))
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Data Penduduk' : 'Tambah Data Penduduk'),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(controller: _nikController, decoration: const InputDecoration(labelText: 'NIK *'), keyboardType: TextInputType.number, readOnly: _isEditMode,
                  validator: (v) => (v == null || v.isEmpty) ? 'NIK kosong' : (v.length != 16 ? 'NIK 16 digit' : null)),
              const SizedBox(height: 12),
              TextFormField(controller: _kkController, decoration: const InputDecoration(labelText: 'No. KK'), keyboardType: TextInputType.number,
                  validator: (v) => (v != null && v.isNotEmpty && v.length != 16) ? 'No. KK 16 digit' : null),
              const SizedBox(height: 12),
              _buildAutocomplete(controller: _namaController, labelText: 'Nama Lengkap *', suggestions: _namaSuggestions, isRequired: true),
              const SizedBox(height: 12),
              _buildAutocomplete(controller: _tempatLahirController, labelText: 'Tempat Lahir', suggestions: _tempatLahirSuggestions),
              const SizedBox(height: 12),
              TextFormField(controller: _tglLahirController, decoration: const InputDecoration(labelText: 'Tanggal Lahir *', hintText: 'DD-MM-YYYY', suffixIcon: Icon(Icons.calendar_today)), readOnly: true, onTap: _selectDate,
                  validator: (v) => (v == null || v.isEmpty) ? 'Tgl Lahir kosong' : null),
              const SizedBox(height: 16),
              Text('Jenis Kelamin *', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              Row(children: [
                Expanded(child: RadioListTile<String>(title: const Text('Laki-laki'), value: 'Laki-laki', groupValue: _jenisKelamin, onChanged: (v) => setState(() => _jenisKelamin = v), contentPadding: EdgeInsets.zero, activeColor: Colors.teal)),
                Expanded(child: RadioListTile<String>(title: const Text('Perempuan'), value: 'Perempuan', groupValue: _jenisKelamin, onChanged: (v) => setState(() => _jenisKelamin = v), contentPadding: EdgeInsets.zero, activeColor: Colors.teal))]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(value: _statusPerkawinan, decoration: const InputDecoration(labelText: 'Status Perkawinan'), items: ['Belum Kawin', 'Kawin', 'Cerai Hidup', 'Cerai Mati'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _statusPerkawinan = v)),
              const SizedBox(height: 12),
              _buildAutocomplete(controller: _kewarganegaraanController, labelText: 'Kewarganegaraan', suggestions: _kewarganegaraanSuggestions),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(value: _agama, decoration: const InputDecoration(labelText: 'Agama'), items: ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha', 'Konghucu'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _agama = v)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(value: _pendidikan, decoration: const InputDecoration(labelText: 'Pendidikan Terakhir'), items: ['Tidak Sekolah', 'SD', 'SMP', 'SMA/SMK', 'Diploma', 'S1', 'S2', 'S3'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _pendidikan = v)),
              const SizedBox(height: 12),
              _buildAutocomplete(controller: _pekerjaanController, labelText: 'Pekerjaan', suggestions: _pekerjaanSuggestions),
              const SizedBox(height: 12),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v != null && v.isNotEmpty && !RegExp(r'^.+@[a-zA-Z]+\.{1}[a-zA-Z]+(\.{0,1}[a-zA-Z]+)$').hasMatch(v)) ? 'Email tidak valid' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _noHpController, decoration: const InputDecoration(labelText: 'No. HP'), keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              Text('Alamat', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 8),
              _buildAutocomplete(controller: _jalanController, labelText: 'Jalan *', suggestions: _jalanSuggestions, isRequired: true),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildAutocomplete(controller: _rtController, labelText: 'RT', suggestions: _rtSuggestions, keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildAutocomplete(controller: _rwController, labelText: 'RW', suggestions: _rwSuggestions, keyboardType: TextInputType.number))]),
              const SizedBox(height: 12),
              _buildAutocomplete(controller: _kelurahanController, labelText: 'Kelurahan/Desa *', suggestions: _kelurahanSuggestions, isRequired: true),
              const SizedBox(height: 12),
              _buildAutocomplete(controller: _kecamatanController, labelText: 'Kecamatan *', suggestions: _kecamatanSuggestions, isRequired: true),
              const SizedBox(height: 12),
              _buildAutocomplete(controller: _kabupatenController, labelText: 'Kabupaten/Kota *', suggestions: _kabupatenSuggestions, isRequired: true),
              const SizedBox(height: 12),
              _buildAutocomplete(controller: _provinsiController, labelText: 'Provinsi *', suggestions: _provinsiSuggestions, isRequired: true),
              const SizedBox(height: 12),
              _buildAutocomplete(controller: _kodeposController, labelText: 'Kode Pos', suggestions: _kodeposSuggestions, keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              _buildPhotoUpload(label: 'Foto KTP', file: _fotoKtpFile, existingUrl: _fotoKtpUrl, isUploading: _isUploadingKtp, onPick: _pickFotoKtp, onRemove: () => setState(() { _fotoKtpFile = null; _fotoKtpUrl = null; })),
              const SizedBox(height: 16),
              _buildPhotoUpload(label: 'Foto Kartu Keluarga (KK)', file: _fotoKkFile, existingUrl: _fotoKkUrl, isUploading: _isUploadingKk, onPick: _pickFotoKk, onRemove: () => setState(() { _fotoKkFile = null; _fotoKkUrl = null; })),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: (_isSavingData || _isUploadingKtp || _isUploadingKk) ? null : _submitData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16.0), minimumSize: const Size(double.infinity, 50), textStyle: const TextStyle(fontSize: 16)),
                child: (_isSavingData || _isUploadingKtp || _isUploadingKk)
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Simpan Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}