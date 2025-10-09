import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

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
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();
  final _pekerjaanController = TextEditingController();

  String? _jenisKelamin;
  String? _pendidikan;
  String? _agama;
  final _pendidikanController = TextEditingController();
  final _agamaController = TextEditingController();
  // suggestion lists loaded from Firebase
  List<String> _namaSuggestions = [];
  List<String> _rtSuggestions = [];
  List<String> _rwSuggestions = [];
  List<String> _pekerjaanSuggestions = [];

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
    // load suggestion lists for autocomplete fields
    _loadSuggestionLists();
  }

  Future<void> _loadSuggestionLists() async {
    try {
      final snapshot = await _dbRef.get();
      final Set<String> names = {};
      final Set<String> rts = {};
      final Set<String> rws = {};
      final Set<String> jobs = {};

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          try {
            final row = value as Map<dynamic, dynamic>;
            final nama = row['nama_lengkap']?.toString();
            final rt = row['rt']?.toString();
            final rw = row['rw']?.toString();
            final pekerjaan = row['pekerjaan']?.toString();
            if (nama != null && nama.isNotEmpty) names.add(nama);
            if (rt != null && rt.isNotEmpty) rts.add(rt);
            if (rw != null && rw.isNotEmpty) rws.add(rw);
            if (pekerjaan != null && pekerjaan.isNotEmpty) jobs.add(pekerjaan);
          } catch (_) {}
        });
      }

      if (mounted) {
        setState(() {
          _namaSuggestions = names.toList()..sort();
          _rtSuggestions = rts.toList()..sort();
          _rwSuggestions = rws.toList()..sort();
          _pekerjaanSuggestions = jobs.toList()..sort();
        });
      }
    } catch (e) {
      // ignore errors; suggestions are optional
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
        _pendidikanController.text = _pendidikan ?? '';
        _agamaController.text = _agama ?? '';
      });
    }
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _tglLahirController.dispose();
    _rtController.dispose();
    _rwController.dispose();
    _pekerjaanController.dispose();
    _pendidikanController.dispose();
    _agamaController.dispose();
    super.dispose();
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

      _dbRef
          .child(_nikController.text)
          .set(data)
          .then((_) {
            if (!mounted) return;
            Navigator.of(context).pop();
          })
          .catchError((error) {
            if (!mounted) return;
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
        title: Text(
          _isEditMode ? 'Edit Data Penduduk' : 'Tambah Data Penduduk',
        ),
        backgroundColor: Colors.teal,
      ),
      body: Form(
        key: _formKey,
        child: DefaultTextStyle(
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                TextFormField(
                  controller: _nikController,
                  decoration: const InputDecoration(labelText: 'NIK'),
                  keyboardType: TextInputType.number,
                  readOnly: _isEditMode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'NIK tidak boleh kosong';
                    }
                    if (value.length != 16) {
                      return 'NIK harus 16 digit';
                    }
                    return null;
                  },
                ),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '')
                      return const Iterable<String>.empty();
                    return _namaSuggestions.where(
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
                            labelText: 'Nama Lengkap',
                          ),
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Nama tidak boleh kosong'
                              : null,
                          onChanged: (v) => _namaController.text = v,
                        );
                      },
                  onSelected: (selection) {
                    setState(() {
                      _namaController.text = selection;
                    });
                  },
                ),
                TextFormField(
                  controller: _tglLahirController,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Lahir',
                    hintText: 'DD-MM-YYYY',
                  ),
                  readOnly: true,
                  onTap: _selectDate,
                ),

                const SizedBox(height: 16),
                Text(
                  'Jenis Kelamin',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            setState(() => _jenisKelamin = 'Laki-laki'),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.55),
                                ),
                              ),
                              child: _jenisKelamin == 'Laki-laki'
                                  ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Laki-laki',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            setState(() => _jenisKelamin = 'Perempuan'),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.55),
                                ),
                              ),
                              child: _jenisKelamin == 'Perempuan'
                                  ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Perempuan',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '')
                            return const Iterable<String>.empty();
                          return _rtSuggestions.where(
                            (opt) => opt.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          );
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              controller.text = _rtController.text;
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length),
                              );
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'RT',
                                ),
                                onChanged: (v) => _rtController.text = v,
                              );
                            },
                        onSelected: (selection) {
                          setState(() => _rtController.text = selection);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '')
                            return const Iterable<String>.empty();
                          return _rwSuggestions.where(
                            (opt) => opt.toLowerCase().contains(
                              textEditingValue.text.toLowerCase(),
                            ),
                          );
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onFieldSubmitted) {
                              controller.text = _rwController.text;
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length),
                              );
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'RW',
                                ),
                                onChanged: (v) => _rwController.text = v,
                              );
                            },
                        onSelected: (selection) {
                          setState(() => _rwController.text = selection);
                        },
                      ),
                    ),
                  ],
                ),
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text == '')
                      return const Iterable<String>.empty();
                    return _pekerjaanSuggestions.where(
                      (opt) => opt.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      ),
                    );
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        controller.text = _pekerjaanController.text;
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: controller.text.length),
                        );
                        return TextFormField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Pekerjaan',
                          ),
                          onChanged: (v) => _pekerjaanController.text = v,
                        );
                      },
                  onSelected: (selection) {
                    setState(() => _pekerjaanController.text = selection);
                  },
                ),

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _pendidikan,
                  decoration: const InputDecoration(
                    labelText: 'Pendidikan Terakhir',
                  ),
                  items:
                      [
                            'Tidak Sekolah',
                            'SD',
                            'SMP',
                            'SMA/SMK',
                            'Diploma',
                            'S1',
                            'S2',
                            'S3',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() {
                    _pendidikan = val;
                    _pendidikanController.text = val ?? '';
                  }),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Pilih pendidikan' : null,
                ),

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _agama,
                  decoration: const InputDecoration(labelText: 'Agama'),
                  items:
                      [
                            'Islam',
                            'Kristen',
                            'Katolik',
                            'Hindu',
                            'Buddha',
                            'Konghucu',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (val) => setState(() {
                    _agama = val;
                    _agamaController.text = val ?? '';
                  }),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Pilih agama' : null,
                ),

                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text('Simpan'),
                ),
              ], // children of ListView
            ), // ListView
          ), // Theme
        ), // DefaultTextStyle
      ), // Form
    ); // Scaffold
  }
}
