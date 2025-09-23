import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DetailScreen extends StatelessWidget {
  final Map building;

  const DetailScreen({super.key, required this.building});

  @override
  Widget build(BuildContext context) {
    final lat = building['latitude'] as double? ?? 0.0;
    final lng = building['longitude'] as double? ?? 0.0;
    final location = LatLng(lat, lng);

    return Scaffold(
      appBar: AppBar(
        title: Text(building['nama_bangunan'] ?? 'Detail Bangunan'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 250,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: location,
                initialZoom: 17.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.apk_sukorame',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: location,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDetailRow(context, Icons.business, 'Nama Bangunan', building['nama_bangunan']),
                _buildDetailRow(context, Icons.category, 'Kategori', building['kategori']),
                _buildDetailRow(context, Icons.description, 'Deskripsi', building['deskripsi']),
                _buildDetailRow(context, Icons.location_on, 'Alamat', building['alamat']),
                _buildDetailRow(context, Icons.map, 'Koordinat', '$lat, $lng'),
              ],
            ),
          ),
        ],
      ),
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
}
