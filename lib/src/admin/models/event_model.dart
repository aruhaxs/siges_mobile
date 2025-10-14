import 'package:firebase_database/firebase_database.dart';

class Event {
  String? id;
  final String title;
  final String date;
  final String time;
  final String location;
  final String description;

  Event({
    this.id,
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.description,
  });

  factory Event.fromFcmPayload(Map<String, dynamic> data) {
    return Event(
      title: data['title'] ?? 'Tanpa Judul',
      date: data['date'] ?? 'Tidak ada tanggal',
      time: data['time'] ?? 'Tidak ada waktu',
      location: data['location'] ?? 'Tidak ada lokasi',
      description: data['description'] ?? 'Tidak ada deskripsi.',
    );
  }

  factory Event.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return Event(
      id: snapshot.key,
      title: data['title'] ?? 'Tanpa Judul',
      date: data['date'] ?? 'Tidak ada tanggal',
      time: data['time'] ?? 'Tidak ada waktu',
      location: data['location'] ?? 'Tidak ada lokasi',
      description: data['description'] ?? 'Tidak ada deskripsi.',
    );
  }
  
  factory Event.fromMapEntry(MapEntry<dynamic, dynamic> entry) {
    final data = entry.value as Map<dynamic, dynamic>;
    return Event(
      id: entry.key,
      title: data['title'] ?? 'Tanpa Judul',
      date: data['date'] ?? 'Tidak ada tanggal',
      time: data['time'] ?? 'Tidak ada waktu',
      location: data['location'] ?? 'Tidak ada lokasi',
      description: data['description'] ?? 'Tidak ada deskripsi.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'time': time,
      'location': location,
      'description': description,
    };
  }
}