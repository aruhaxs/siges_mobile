import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('buildings');
  final _searchController = TextEditingController();
  final _mapController = MapController();
  String _searchQuery = '';
  static const _initialPosition = LatLng(-7.803, 111.996); // Posisi awal di sekitar Kediri
  LatLng? _userLocation;

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
    _mapController.dispose(); // Penting: Hapus controller saat widget tidak digunakan
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Sebaran Bangunan'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [

          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 15.0,
            ),
            children: [
 
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.apk_sukorame',
              ),

              StreamBuilder<DatabaseEvent>(
                stream: _dbRef.onValue,
                builder: (context, snapshot) {
                  final List<Marker> buildingMarkers = [];

                  if (snapshot.hasData && !snapshot.hasError && snapshot.data!.snapshot.value != null) {
                    final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    data.forEach((key, value) {
                      final lat = value['latitude'] as double? ?? 0.0;
                      final lng = value['longitude'] as double? ?? 0.0;
                      if (lat != 0.0 && lng != 0.0) {
                        buildingMarkers.add(
                          Marker(
                            width: 40.0,
                            height: 40.0,
                            point: LatLng(lat, lng),
                            child: Tooltip(
                              message: value['nama_bangunan'] as String? ?? 'Tanpa Nama',
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40.0,
                              ),
                            ),
                          ),
                        );
                      }
                    });
                  }

                  final filteredMarkers = buildingMarkers.where((marker) {
                    final tooltip = (marker.child as Tooltip).message ?? '';
                    return tooltip.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  if (_searchQuery.isNotEmpty && filteredMarkers.length == 1) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _mapController.move(filteredMarkers.first.point, 17.0);
                    });
                  }

                  return MarkerLayer(
                    markers: [
                      ...filteredMarkers,
                      if (_userLocation != null) _buildUserLocationMarker(),
                    ],
                  );
                },
              ),
            ],
          ),

          _buildSearchbar(),
          _buildMyLocationButton(),
        ],
      ),
    );
  }

  Widget _buildMyLocationButton() {
    return Positioned(
      bottom: 20,
      left: 20,
      child: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () async {
          // 1. Minta izin lokasi
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Izin lokasi ditolak. Mohon aktifkan di pengaturan aplikasi.')),
              );
            }
            return;
          }

          // 2. Dapatkan lokasi saat ini
          try {
            final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
            final newLocation = LatLng(pos.latitude, pos.longitude);

            // 3. Update state dan gerakkan peta
            setState(() {
              _userLocation = newLocation;
            });
            
            // Pindahkan kamera setelah UI selesai di-render untuk memastikan stabilitas
            WidgetsBinding.instance.addPostFrameCallback((_) {
                _mapController.move(newLocation, 17.0);
            });

          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
              );
            }
          }
        },
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }

  // Widget untuk Search Bar
  Widget _buildSearchbar() {
    return Positioned(
      top: 10,
      left: 15,
      right: 15,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Cari lokasi di peta...',
            border: InputBorder.none,
            icon: Icon(Icons.search),
          ),
        ),
      ),
    );
  }

  // Widget untuk penanda lokasi pengguna (titik biru)
  Marker _buildUserLocationMarker() {
    return Marker(
      width: 40,
      height: 40,
      point: _userLocation!,
      child: Container(
        alignment: Alignment.center,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
        ),
      ),
    );
  }
}
