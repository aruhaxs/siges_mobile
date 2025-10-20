import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

List<LatLng> _parseGeoJson(String jsonString) {
  final Map<String, dynamic> data = json.decode(jsonString);
  final List<LatLng> points = [];

  if (data['features'] != null && data['features'] is List) {
    final List features = data['features'];
    if (features.isNotEmpty) {
      final Map<String, dynamic> feature = features[0];
      final Map<String, dynamic> geometry = feature['geometry'];
      final String geometryType = geometry['type'];

      if (geometryType == 'Polygon') {
        final List coordinates = geometry['coordinates'][0];
        for (var coord in coordinates) {
          points.add(LatLng(coord[1], coord[0]));
        }
      } else if (geometryType == 'MultiPolygon') {
        final List coordinates = geometry['coordinates'][0][0];
        for (var coord in coordinates) {
          points.add(LatLng(coord[1], coord[0]));
        }
      }
    }
  }
  return points;
}

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
  LatLng? _userLocation;

  List<LatLng> _sukorameBoundary = [];

  List<Map<String, dynamic>> _allBuildings = [];
  Map<String, int> _categoryCounts = {};

  final List<String> _kategoriOptions = [
    'Semua',
    'Pendidikan',
    'Kesehatan',
    'Tempat Ibadah',
    'Kantor Pemerintahan',
    'UMKM',
    'Penginapan',
    'Lainnya'
  ];

  String _selectedCategory = 'Semua';
  String? _selectedBuildingKey;
  bool _isCategoryListVisible = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });

    _loadSukorameBoundaryFromGeoJson();
  }

  Future<void> _loadSukorameBoundaryFromGeoJson() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/sukorame_boundary.geojson');
      final List<LatLng> points = await compute(_parseGeoJson, jsonString);
      if (mounted) {
        setState(() {
          _sukorameBoundary = points;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat batas wilayah: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
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
              if (_sukorameBoundary.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _sukorameBoundary,
                      color: Colors.teal.withOpacity(0.2),
                      borderColor: Colors.teal,
                      borderStrokeWidth: 3.0,
                      isFilled: true,
                    ),
                  ],
                ),
              StreamBuilder<DatabaseEvent>(
                stream: _dbRef.onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.hasError ||
                      snapshot.data!.snapshot.value == null) {
                    return MarkerLayer(
                      markers: [
                        if (_userLocation != null) _buildUserLocationMarker(),
                      ],
                    );
                  }

                  final data =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                  final newAllBuildings = <Map<String, dynamic>>[];
                  final newCategoryCounts = <String, int>{'Semua': 0};
                  for (var cat in _kategoriOptions) {
                    if (cat != 'Semua') newCategoryCounts[cat] = 0;
                  }

                  data.forEach((key, value) {
                    final building = Map<String, dynamic>.from(value as Map)
                      ..['key'] = key;

                    newAllBuildings.add(building);

                    final kategori = building['kategori'] as String? ?? 'Lainnya';
                    newCategoryCounts['Semua'] = (newCategoryCounts['Semua'] ?? 0) + 1;
                    if (newCategoryCounts.containsKey(kategori)) {
                      newCategoryCounts[kategori] = (newCategoryCounts[kategori] ?? 0) + 1;
                    } else {
                      // Handle case where category from DB doesn't exist in options
                      newCategoryCounts['Lainnya'] = (newCategoryCounts['Lainnya'] ?? 0) + 1;
                    }
                  });

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _allBuildings = newAllBuildings;
                        _categoryCounts = newCategoryCounts;
                      });
                    }
                  });

                  final categoryFilteredBuildings = _selectedCategory == 'Semua'
                      ? newAllBuildings
                      : newAllBuildings
                          .where((b) => b['kategori'] == _selectedCategory)
                          .toList();

                  final filteredBuildings = categoryFilteredBuildings
                      .where((building) {
                    final nama = (building['nama_bangunan'] as String? ?? '').toLowerCase();
                    return nama.contains(_searchQuery.toLowerCase());
                  }).toList();

                  final List<Marker> buildingMarkers = filteredBuildings.map((building) {
                    final lat = building['latitude'] as double? ?? 0.0;
                    final lng = building['longitude'] as double? ?? 0.0;
                    if (lat == 0.0 && lng == 0.0) return null;

                    return Marker(
                      width: 40.0,
                      height: 40.0,
                      point: LatLng(lat, lng),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBuildingKey = building['key'];
                            _isCategoryListVisible = false;
                          });
                        },
                        child: Tooltip(
                          message: building['nama_bangunan'] as String? ?? 'Tanpa Nama',
                          child: Icon(
                            Icons.location_pin,
                            color: _selectedBuildingKey == building['key']
                                ? Colors.blue
                                : Colors.red,
                            size: 40.0,
                          ),
                        ),
                      ),
                    );
                  }).whereType<Marker>().toList();

                  if (_searchQuery.isNotEmpty && filteredBuildings.length == 1) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        final firstBuilding = filteredBuildings.first;
                        final lat = firstBuilding['latitude'] as double?;
                        final lng = firstBuilding['longitude'] as double?;
                        if (lat != null && lng != null) {
                           _mapController.move(LatLng(lat, lng), 17.0);
                        }
                      }
                    });
                  }

                  return MarkerLayer(
                    markers: [
                      ...buildingMarkers,
                      if (_userLocation != null) _buildUserLocationMarker(),
                    ],
                  );
                },
              ),
            ],
          ),
          _buildSearchbar(),
          _buildCategoryFilters(),
          _buildCategoryListPanel(),
          _buildMyLocationButton(),
          _buildMarkerDetailSheet(),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Positioned(
      top: 70,
      left: 0,
      right: 0,
      child: Container(
        height: 50,
        color: Colors.black.withOpacity(0.1),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: _kategoriOptions.length,
          itemBuilder: (context, index) {
            final category = _kategoriOptions[index];
            final count = _categoryCounts[category] ?? 0;
            final isSelected = _selectedCategory == category;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ChoiceChip(
                label: Text('$category ($count)'),
                selected: isSelected,
                selectedColor: Colors.teal,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                    _isCategoryListVisible = (category != 'Semua');
                    _selectedBuildingKey = null;
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryListPanel() {
    final categoryBuildings = _allBuildings
        .where((b) => b['kategori'] == _selectedCategory)
        .toList();

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: 120,
      bottom: 0,
      left: _isCategoryListVisible ? 0 : -MediaQuery.of(context).size.width * 0.8,
      child: Material(
        elevation: 8,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_selectedCategory (${categoryBuildings.length})',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isCategoryListVisible = false;
                        });
                      },
                    )
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: categoryBuildings.length,
                  itemBuilder: (context, index) {
                    final building = categoryBuildings[index];
                    final lat = building['latitude'] as double? ?? 0.0;
                    final lng = building['longitude'] as double? ?? 0.0;

                    return ListTile(
                      title: Text(building['nama_bangunan'] ?? 'Tanpa Nama'),
                      subtitle: Text(building['alamat'] ?? 'Tanpa Alamat'),
                      onTap: () {
                        _searchController.clear();
                        if (lat != 0.0 && lng != 0.0) {
                           _mapController.move(LatLng(lat, lng), 17.0);
                        }
                        setState(() {
                          _selectedBuildingKey = building['key'];
                          _isCategoryListVisible = false;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkerDetailSheet() {
    if (_selectedBuildingKey == null) {
      return const SizedBox.shrink();
    }

    Map<String, dynamic>? selectedBuilding;
    try {
      selectedBuilding = _allBuildings.firstWhere((b) => b['key'] == _selectedBuildingKey);
    } catch (e) {
      selectedBuilding = null;
    }

    if (selectedBuilding == null) {
      return const SizedBox.shrink();
    }

    final building = selectedBuilding; // Promote to non-nullable

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.1,
      maxChildSize: 0.6,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2)),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedBuildingKey = null;
                    });
                  },
                ),
              ),
              _buildDetailRow(context, Icons.business, 'Nama Bangunan', building['nama_bangunan']),
              _buildDetailRow(context, Icons.category, 'Kategori', building['kategori']),
              _buildDetailRow(context, Icons.description, 'Deskripsi', building['deskripsi']),
              _buildDetailRow(context, Icons.location_on, 'Alamat', building['alamat']),
              _buildDetailRow(context, Icons.access_time, 'Jam Buka', building['jam_buka']),
              _buildDetailRow(context, Icons.access_time_filled, 'Jam Tutup', building['jam_tutup']),
              _buildDetailRow(context, Icons.map, 'Koordinat', "${building['latitude']}, ${building['longitude']}"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value != null && value.isNotEmpty ? value : 'Tidak ada data', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
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
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Izin lokasi ditolak. Mohon aktifkan di pengaturan aplikasi.')),
              );
            }
            return;
          }

          try {
            final pos = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high);
            final newLocation = LatLng(pos.latitude, pos.longitude);

            setState(() {
              _userLocation = newLocation;
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _mapController.move(newLocation, 17.0);
              }
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
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
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

  Marker _buildUserLocationMarker() {
    // Pastikan _userLocation tidak null sebelum membuat Marker
    if (_userLocation == null) {
      // Return marker kosong atau handle error
      return Marker(point: const LatLng(0,0), child: Container()); // Placeholder
    }
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
              BoxShadow(
                  color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
        ),
      ),
    );
  }
}