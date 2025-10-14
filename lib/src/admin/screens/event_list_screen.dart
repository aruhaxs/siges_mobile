import 'package:apk_sukorame/src/admin/models/event_model.dart';
import 'package:apk_sukorame/src/admin/screens/event_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  final DatabaseReference _eventsRef = FirebaseDatabase.instance.ref('events');
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  void _checkUserRole() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous && user.emailVerified) {
      setState(() {
        _isAdmin = true;
      });
    }
  }

  void _deleteEvent(String eventId) {
    _eventsRef.child(eventId).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kegiatan berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menghapus kegiatan.'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _showDeleteConfirmation(Event event) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus kegiatan "${event.title}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteEvent(event.id!);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kegiatan'),
        backgroundColor: Colors.teal,
      ),
      body: StreamBuilder(
        stream: _eventsRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan.'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'Belum ada jadwal kegiatan.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final Map<dynamic, dynamic> eventsMap =
              snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
          final List<Event> events = eventsMap.entries.map((entry) {
            return Event.fromMapEntry(entry);
          }).toList();
          
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                child: GestureDetector(
                  onLongPress: _isAdmin ? () => _showDeleteConfirmation(event) : null,
                  child: ListTile(
                    leading: const Icon(Icons.event, color: Colors.teal),
                    title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${event.date} - ${event.location}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EventScreen(event: event),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: _isAdmin
        ? Container(
            padding: const EdgeInsets.all(12),
            color: Colors.teal.withOpacity(0.1),
            child: const Text(
              'Tips: Tekan lama pada kegiatan untuk menghapusnya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.teal, fontStyle: FontStyle.italic),
            ),
          )
        : null,
    );
  }
}