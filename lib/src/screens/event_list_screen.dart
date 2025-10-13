import 'package:flutter/material.dart';

// Halaman ini tidak butuh parameter, jadi aman dipanggil dari mana saja.
class EventListScreen extends StatelessWidget {
  const EventListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kegiatan'),
        backgroundColor: Colors.teal,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'Belum ada jadwal kegiatan.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}