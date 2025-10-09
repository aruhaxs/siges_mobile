import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:provider/provider.dart';
import '../services/theme_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  DatabaseReference? _userRef;
  String? _photoUrl;
  final ImagePicker _picker = ImagePicker();
  supa.SupabaseClient? _supabase;
  bool _isUploading = false;

  String _role = 'Administrator';
  String _phoneNumber = '+62 858-5623-9499';
  String _location = 'Kelurahan Sukorame, Kota Kediri';

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _userRef = FirebaseDatabase.instance.ref('users/${_currentUser.uid}');
      _loadUserData();
    }

    _supabase = supa.Supabase.instance.client;
  }

  void _loadUserData() {
    _userRef?.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.exists && mounted) {
        final data = event.snapshot.value as Map;
        setState(() {
          _role = data['role'] ?? _role;
          _phoneNumber = data['phoneNumber'] ?? _phoneNumber;
          _location = data['location'] ?? _location;
          _photoUrl = data['photoUrl'];
        });
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    final File file = File(picked.path);
    await _uploadToSupabase(file);
  }

  Future<void> _uploadToSupabase(File file) async {
    if (_supabase == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supabase belum terkonfigurasi')),
      );
      return;
    }

    setState(() => _isUploading = true);

    final String fileName =
        'profile_${_currentUser?.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      final storage = _supabase!.storage.from('Storage');

      if (_photoUrl != null) {
        final oldFileName = Uri.parse(_photoUrl!).pathSegments.last;
        await storage.remove([oldFileName]);
      }

      await storage.upload(fileName, file);
      final publicUrl = storage.getPublicUrl(fileName);

      if (_userRef != null) {
        await _userRef!.update({'photoUrl': publicUrl});
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto profil berhasil diunggah')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengunggah foto: $e')));
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String initials = (_currentUser?.displayName?.isNotEmpty == true)
        ? _currentUser!.displayName!
              .split(' ')
              .map((e) => e.substring(0, 1))
              .take(2)
              .join()
        : (_currentUser?.email?.substring(0, 2).toUpperCase() ?? '??');
    String joinDate = (_currentUser?.metadata.creationTime != null)
        ? 'Bergabung sejak ${DateFormat('d MMMM yyyy', 'id_ID').format(_currentUser!.metadata.creationTime!)}'
        : 'Tanggal bergabung tidak tersedia';
    String lastSignIn = (_currentUser?.metadata.lastSignInTime != null)
        ? '${DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(_currentUser!.metadata.lastSignInTime!)} WIB'
        : 'Tidak tercatat';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.teal,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          showModalBottomSheet(
                            context: context,
                            builder: (ctx) => SafeArea(
                              child: Wrap(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.camera_alt),
                                    title: const Text('Ambil Foto'),
                                    onTap: () {
                                      Navigator.of(ctx).pop();
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.photo_library),
                                    title: const Text('Pilih dari Galeri'),
                                    onTap: () {
                                      Navigator.of(ctx).pop();
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          backgroundImage: _photoUrl != null
                              ? NetworkImage(_photoUrl!)
                              : null,
                          child: _isUploading
                              ? const CircularProgressIndicator(
                                  color: Colors.teal,
                                )
                              : (_photoUrl == null
                                    ? Text(
                                        initials,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          color: Colors.teal,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Container()), // Spacer
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fitur Edit Profil segera hadir!'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Profil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser?.displayName ?? 'Nama Pengguna',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildDetailRow(Icons.shield_outlined, _role),
                      const Divider(height: 20),
                      _buildDetailRow(
                        Icons.email_outlined,
                        _currentUser?.email ?? 'Tidak ada email',
                      ),
                      _buildDetailRow(Icons.phone_outlined, _phoneNumber),
                      _buildDetailRow(Icons.location_on_outlined, _location),
                      _buildDetailRow(Icons.calendar_today_outlined, joinDate),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Consumer<ThemeManager>(
                  builder: (context, themeManager, child) {
                    return SwitchListTile(
                      title: const Text('Mode Gelap'),
                      value: themeManager.themeMode == ThemeMode.dark,
                      onChanged: (bool value) {
                        themeManager.toggleTheme(value);
                      },
                      secondary: const Icon(
                        Icons.dark_mode_outlined,
                        color: Colors.teal,
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),

                ListTile(
                  leading: const Icon(Icons.history, color: Colors.teal),
                  title: const Text('Login Terakhir'),
                  subtitle: Text(lastSignIn),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: Colors.teal),
                  title: const Text('Ubah Password'),
                  subtitle: const Text('Ganti kata sandi akun'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur Ubah Password segera hadir!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Konfirmasi Log Out'),
                  content: const Text(
                    'Apakah Anda yakin ingin keluar dari aplikasi?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        FirebaseAuth.instance.signOut();
                      },
                      child: const Text(
                        'Log Out',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout),
            label: const Text('Keluar dari Akun'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
