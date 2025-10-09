import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';

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
  static const _initialPosition = LatLng(-7.803, 111.996);

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
          StreamBuilder(
            stream: _dbRef.onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<Marker> allMarkers = [];
              if (snapshot.hasData &&
                  !snapshot.hasError &&
                  snapshot.data?.snapshot.value != null) {
                final data =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                data.forEach((key, value) {
                  final lat = value['latitude'] as double? ?? 0.0;
                  final lng = value['longitude'] as double? ?? 0.0;
                  if (lat != 0.0 && lng != 0.0) {
                    allMarkers.add(
                      Marker(
                        width: 40.0,
                        height: 40.0,
                        point: LatLng(lat, lng),
                        child: Tooltip(
                          message: value['nama_bangunan'] ?? 'Tanpa Nama',
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

              final filteredMarkers = allMarkers.where((marker) {
                final tooltip = (marker.child as Tooltip).message ?? '';
                return tooltip.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );
              }).toList();

              if (_searchQuery.isNotEmpty && filteredMarkers.length == 1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _mapController.move(filteredMarkers.first.point, 17.0);
                });
              }

              return FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _initialPosition,
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.apk_sukorame',
                  ),
                  MarkerLayer(markers: filteredMarkers),
                ],
              );
            },
          ),
          Positioned(
            top: 10,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
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
          ),
        ],
      ),
    );
  }
}
