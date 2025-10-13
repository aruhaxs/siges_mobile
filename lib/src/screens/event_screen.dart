import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/event_model.dart';

class EventScreen extends StatelessWidget {
  final Event event;

  const EventScreen({super.key, required this.event});

  void _shareEvent(BuildContext context) {
    final String eventDetails = '''
Jadwal Kegiatan Desa Sukorame:

Judul: ${event.title}
Tanggal: ${event.date}
Waktu: ${event.time}
Lokasi: ${event.location}

Deskripsi:
${event.description}
''';
    Share.share(eventDetails, subject: 'Jadwal Kegiatan: ${event.title}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail Kegiatan"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareEvent(context),
            tooltip: 'Bagikan Kegiatan',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            // Padding di dalam Card
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 24.0),

                _buildInfoRow(Icons.calendar_today, 'Tanggal', event.date),
                _buildInfoRow(Icons.access_time, 'Waktu', event.time),
                _buildInfoRow(Icons.location_on, 'Lokasi', event.location),
                const SizedBox(height: 16.0),
                const Divider(),
                const SizedBox(height: 16.0),

                const Text(
                  'Deskripsi:',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  event.description, // Mengambil data 'description' dari objek event
                  style: const TextStyle(fontSize: 16.0, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal.shade700, size: 20),
          const SizedBox(width: 16.0),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 16.0),
            ),
          ),
        ],
      ),
    );
  }
}